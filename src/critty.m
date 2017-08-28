#include "utf8/utf8.h"
#include "tinybuf/tinybuf.h"

#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TerminalStorageLine: NSObject
@property(readonly,nonatomic,strong) NSString* string;
@property(readonly,nonatomic) size_t index;

- (instancetype)initWithString:(NSString*)string index:(size_t)i NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@implementation TerminalStorageLine
- (instancetype)initWithString:(NSString*)string index:(size_t)i {
	if ((self = [super init])) {
		if (!string) {
			abort();
		}
		_string = string;
	}
	return self;
}
@end

@class TerminalStorage;
@protocol TerminalStorageObserver
- (void)terminalStorage:(TerminalStorage*)storage changedLines:(NSArray<TerminalStorageLine*>*)lines;
@end

@interface TerminalStorage: NSObject
@property (nonatomic,assign) id<TerminalStorageObserver> observer;
@property (readonly,nonatomic) NSMutableArray<TerminalStorageLine*>* lines;
@end

@implementation TerminalStorage {
	// Consider saving the original data.
	// NSMutableArray<dispatch_data_t>* _originalData;
	size_t _currentLine;
	tinybuf_t _buf;
	utf8_decode_context_t _utf8_decode_context;
}

- (instancetype)init {
	if ((self = [super init])) {
		_lines = [NSMutableArray array];
		_currentLine = -1;
		tinybuf_init(&_buf);
	}
	return self;
}

- (void)dealloc {
	tinybuf_free(&_buf);
}

- (void)append:(dispatch_data_t)data {
	__block size_t good_length = 0;
	dispatch_data_apply(data, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
		for (size_t i = 0; i < size; i++) {
			utf8_decode(&_utf8_decode_context, ((unsigned char*)buffer)[i]);
			switch (_utf8_decode_context.state) {
				case UTF8_OK:
					tinybuf_append(&_buf, _utf8_decode_context.codepoint);
					good_length = _buf.len;
					break;
				case UTF8_ERROR:
					/* Append a replacement character (�) */
					tinybuf_append(&_buf, 0xfffd);
					_utf8_decode_context.state = UTF8_OK;
					break;
				default:
					break;
			}
		}
		return true;
	});
	NSLog(@"len: %zu good_length: %zu", _buf.len, good_length);
	size_t oldcount = _lines.count;
	for (size_t i = 0, start = 0; i < good_length; i++) {
		// TODO: Save in-progress line to an ivar.
		if (i == good_length - 1 || _buf.buf[i] == '\n') {
			[_lines addObject:[[TerminalStorageLine alloc] initWithString:
				[[NSString alloc] initWithBytes:_buf.buf + start
										 length:(i - start) * sizeof(_buf.buf[0])
									   encoding:NSUTF32StringEncoding]
			index:_lines.count]];
			start = i;
		}
	}
	tinybuf_delete_front(&_buf, good_length);
	NSLog(@"last line: %@ (len: %zu), buf left: %zu", _lines.lastObject, _lines.count, _buf.len);
	[_observer terminalStorage:self changedLines:[_lines subarrayWithRange:NSMakeRange(oldcount, _lines.count-oldcount)]];
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
@property(nonatomic,strong) NSFont* font;
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
	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)([[NSAttributedString alloc] initWithString:self.string ? self.string : @"<nil>" attributes:@{
		NSFontAttributeName: _font,
	}]));
	[NSColor.whiteColor setFill];
	CGContextFillRect(context, dirtyRect);
	CGContextSetTextPosition(context, 0, ceil(-_font.descender));
	CTLineDraw(line, context);
	CFRelease(line);
}

@end

@interface TerminalContentView: NSView<TerminalStorageObserver>
@end

@implementation TerminalContentView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
	TerminalStorage* _storage;
	NSFont* _font;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
		_lineViews = [NSMutableArray array];
		_lineViewReusePool = [[ViewReusePool alloc] init];
	}
	return self;
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[self prepareContentInRect:NSZeroRect];
}

- (NSRect)lineRect {
	return [self backingAlignedRect:NSMakeRect(
		0, 0, NSWidth(self.bounds), NSHeight(_font.boundingRectForFont)
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
			lineView.font = _font;
		}
		lineView.string = _storage.lines[firstLine + i].string;
#if 0
		// Ew ew ew ew
		[_storage readSync:^(unsigned char* buf, size_t len) {
			(void)firstLine;
			NSString* str = [NSString stringWithFormat:@"#%zu %@", firstLine + i, [[NSString alloc] initWithBytes:buf + (100 * (firstLine + i)) length:100 encoding:NSUTF8StringEncoding]];
			lineView.string = str ? str : @"<err>";
		}];
#endif
		[_lineViews insertObject:lineView atIndex:i];
		[self addSubview:lineView];
		lineRect.origin.y += NSHeight(lineRect);
		i += 1;
	}
	[super prepareContentInRect:outRect];
}

- (void)terminalStorage:(TerminalStorage*)storage changedLines:(NSArray<TerminalStorageLine*>*)lines {
	// :(
	_storage = storage;

	// Ew, plz no change own frame.
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self setFrameSize:NSMakeSize(NSWidth(self.frame), ceil(storage.lines.count) * NSHeight([self lineRect]))];
	});
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
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 0)];
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
	NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
	win.contentView.wantsLayer = YES;

	TerminalView* terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
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
			DISPATCH_IO_STREAM, argv[1], O_RDONLY, 0, queue, ^(int err){}
		);
		dispatch_io_read(
			channel, 0, SIZE_MAX, queue,
			^(bool done, dispatch_data_t data, int error){
				if (!data)
					return;
				[storage append:data];
			}
		);
	}

	NSApplication* app = [NSApplication sharedApplication];
	AppDelegate* appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
