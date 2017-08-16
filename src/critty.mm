#include "utf8/utf8.hpp"

#include <math.h>
#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NSFont* const systemFont = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

#define BUFGROW (1024 * 1024)

@class TerminalStorage;
@protocol TerminalStorageObserver
- (void)terminalStorageChanged:(TerminalStorage*)storage;
@end

@interface TerminalStorage: NSObject
@property (nonatomic,assign) id<TerminalStorageObserver> observer;
@end

@implementation TerminalStorage {
	dispatch_queue_t queue_;
	unsigned char* buf_;
	size_t cap_;
	size_t len_;
}

- (instancetype)init {
	if ((self = [super init])) {
		queue_ = dispatch_queue_create(
			[self class].description.UTF8String,
			DISPATCH_QUEUE_SERIAL
		);
	}
	return self;
}
- (void)dealloc {
	dispatch_sync(queue_, ^{
		free(buf_);
	});
}

- (void)read:(void(^)(unsigned char*, size_t))block {
	dispatch_async(queue_, ^{
		block(buf_, len_);
	});
}

- (void)appendData:(const void*)buf length:(size_t)len {
	dispatch_barrier_sync(queue_, ^{
		const size_t nlen = len_ + len;
		if (nlen > cap_) {
			cap_ = nlen + BUFGROW - (nlen % BUFGROW);
			buf_ = (unsigned char*)realloc(buf_, cap_);
		}
		memcpy(buf_ + len_, buf, len);
		len_ += len;
	});
	[_observer terminalStorageChanged:self];
}
@end

@interface ViewReusePool<__covariant ViewType:NSView*>: NSObject
@property(nonatomic,strong) NSMutableArray<ViewType>* freeObjects;

- (ViewType)getObject;
- (void)returnObject:(ViewType)object;
@end

@implementation ViewReusePool
- (instancetype)init {
	if ((self = [super init])) {
		self.freeObjects = [NSMutableArray array];
	}
	return self;
}

- (id)getObject {
	id ret = [_freeObjects lastObject];
	if (ret) { [_freeObjects removeLastObject]; }
	return ret;
}

- (void)returnObject:(id)object {
	[object prepareForReuse];
	[_freeObjects addObject:object];
}
@end

@interface TerminalLineView: NSView
@property(nonatomic,strong) NSString* string;
- (instancetype)initWithFrame:(NSRect)frameRect NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;
@end

@implementation TerminalLineView

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
		self.layerContentsPlacement = NSViewLayerContentsPlacementBottomLeft;
	}
	return self;
}

- (BOOL)isOpaque {
	return YES;
}

- (void)setString:(NSString*)string {
	_string = string;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>([[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", self.string, NSStringFromRect(self.frame)] attributes:@{
		NSFontAttributeName: systemFont,
	}]));
	[NSColor.whiteColor setFill];
	CGContextFillRect(context, dirtyRect);
	CGContextSetTextPosition(context, 0, ceil(-systemFont.descender));
	CTLineDraw(line, context);
	CFRelease(line);
}

@end

@interface TerminalContentView: NSView<TerminalStorageObserver>
@end

@implementation TerminalContentView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
		_lineViewReusePool = [[ViewReusePool alloc] init];
	}
	return self;
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[self prepareContentInRect:self.visibleRect];
}

- (NSRect)lineRect {
	return [self backingAlignedRect:NSMakeRect(
		0, 0, NSWidth(self.bounds), systemFontHeight
	) options:NSAlignAllEdgesOutward];
}

- (void)prepareContentInRect:(const NSRect)rect {
	NSRect lineRect = [self lineRect];
	CGFloat yOffset = fmod(NSMinY(rect), NSHeight(lineRect));
	lineRect.origin.y = NSMinY(rect) - yOffset;
	const size_t visibleLines = ceil((NSHeight(rect) + yOffset) / NSHeight(lineRect));
	const size_t firstLine = NSMinY(lineRect) / NSHeight(lineRect);
	const NSRect outRect = NSMakeRect(NSMinX(lineRect), NSMinY(lineRect), NSWidth(lineRect), visibleLines * NSHeight(lineRect));

	for (size_t i = 0;;) {
		if (i < _lineViews.count) {
			TerminalLineView* lineView = [_lineViews objectAtIndex:i];
			if (NSMinY(lineView.frame) < NSMinY(outRect) || NSMaxY(lineView.frame) > NSMaxY(outRect) ) {
				[lineView removeFromSuperview];
				[_lineViews removeObjectAtIndex:i];
				[_lineViewReusePool returnObject:lineView];
				continue;
			} else if (NSMinY(lineView.frame) == NSMinY(lineRect)) {
				lineRect.origin.y += NSHeight(lineRect);
				i += 1;
				continue;
			}
		}
		if (NSMinY(lineRect) > NSMaxY(outRect)) {
			break;
		}
		TerminalLineView* lineView = [_lineViewReusePool getObject];
		if (lineView) {
			lineView.frame = lineRect;
		} else {
			lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
			lineView.autoresizingMask = NSViewWidthSizable;
		}
		lineView.string = [NSString stringWithFormat:@"%zu", firstLine + i];
		[_lineViews insertObject:lineView atIndex:i];
		[self addSubview:lineView];
		lineRect.origin.y += NSHeight(lineRect);
		i += 1;
	}
	[super prepareContentInRect:outRect];
}

- (void)terminalStorageChanged:(TerminalStorage*)storage {
	[storage read:^(unsigned char* buf, size_t len) {
		NSLog(@"GOGO %c %zu", buf[0], len);
		// Ew, plz no change own frame.
		[self setFrameSize:NSMakeSize(NSWidth(self.frame), len / 10 * NSHeight([self lineRect]))];
	}];
}

@end

@interface TerminalView: NSView<NSStreamDelegate>
@property(readonly,nonatomic) TerminalContentView* contentView;
@end

@implementation TerminalView {
	id scrollObserver_;
	NSScrollView* _scrollView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), systemFontHeight * 1000000)];
		_contentView.autoresizingMask = NSViewWidthSizable;
		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.documentView = _contentView;
		[_scrollView.contentView scrollToPoint:NSMakePoint(0, NSHeight(_contentView.bounds) - NSHeight(_scrollView.bounds))];
		[self addSubview:_scrollView];
	}
	return self;
}

@end

@interface AppDelegate: NSObject<NSApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
@end

int main(int argc, char* argv[]) {
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
	win.contentView.wantsLayer = YES;

	auto terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

	TerminalStorage* storage = [[TerminalStorage alloc] init];
	storage.observer = terminalView.contentView;

	if (argc > 1) {
		dispatch_queue_t queue =
			dispatch_queue_create("reader", DISPATCH_QUEUE_SERIAL);
		dispatch_io_t channel = dispatch_io_create_with_path(
			DISPATCH_IO_STREAM, argv[1], O_RDONLY, 0, queue, ^(int){}
		);
		dispatch_io_read(
			channel, 0, SIZE_MAX, queue,
			^(bool done, dispatch_data_t data, int error){
				if (!data)
					return;
				dispatch_data_apply(data, ^(
					dispatch_data_t region,
					size_t offset,
					const void *buffer,
					size_t size
				){
					[storage appendData:buffer length:size];
					return true;
				});
			}
		);
	}

	auto app = [NSApplication sharedApplication];
	auto appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
