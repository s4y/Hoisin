#include "utf8/utf8.h"
#include "tinybuf/tinybuf.h"

#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

static const CGFloat kLineXMargin = 4;

@interface TerminalDocumentLine: NSObject
@property(readonly,nonatomic,strong) NSString* string;
@property(readonly,nonatomic) size_t index;

- (instancetype)initWithString:(NSString*)string index:(size_t)i NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@implementation TerminalDocumentLine
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

@class TerminalDocument;
@protocol TerminalDocumentObserver
- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSArray<TerminalDocumentLine*>*)lines;
@end

@interface TerminalDocument: NSObject
@property (nonatomic,weak) id<TerminalDocumentObserver> observer;
@property (nonatomic) size_t softWrapColumn;
@end

@implementation TerminalDocument {
	// Consider saving the original data.
	// NSMutableArray<dispatch_data_t>* _originalData;
	NSMutableArray<TerminalDocumentLine*>* _lines;
	NSMutableArray<TerminalDocumentLine*>* _softLines;
	dispatch_queue_t _queue;
	size_t _currentLine;
	tinybuf_t _buf;
	utf8_decode_context_t _utf8_decode_context;
}

- (instancetype)init {
	if ((self = [super init])) {
		_queue = dispatch_queue_create(
			self.class.className.UTF8String,
			DISPATCH_QUEUE_CONCURRENT
		);
		_lines = [NSMutableArray array];
		_currentLine = -1;
		tinybuf_init(&_buf);
	}
	return self;
}

- (void)dealloc {
	tinybuf_free(&_buf);
}

- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block {
	dispatch_sync(_queue, ^{ block(_lines); });
}

#if 0
- (NSArray<TerminalDocumentLine*>*)softWrapLine:(TerminalDocumentLine*)line
									 startIndex:(size_t)i {
	NSMutableArray* arr = [NSMutableArray array];
	for (NSString* hunk in line) {
	}
}
#endif

- (void)setSoftWrapColumn:(size_t)softWrapColumn {
	if (_softWrapColumn == softWrapColumn)
		return;
	_softWrapColumn = softWrapColumn;
}

- (void)append:(dispatch_data_t)data {
	dispatch_barrier_async(_queue, ^{ [self _append:data]; });
}

- (void)_append:(dispatch_data_t)data {
	__block size_t good_length = 0;
	// TODO: Use a queue to make safe, plz.
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
	size_t oldcount = _lines.count;
	for (size_t i = 0, start = 0; i < good_length; i++) {
		// TODO: Save in-progress line to an ivar.
		if (i == good_length - 1 || _buf.buf[i] == '\n') {
			[_lines addObject:[[TerminalDocumentLine alloc] initWithString:
				[[NSString alloc] initWithBytes:_buf.buf + start
										 length:(i - start) * sizeof(_buf.buf[0])
									   encoding:NSUTF32LittleEndianStringEncoding]
			index:_lines.count]];
			i++; // Skip the '\n'
			start = i;
		}
	}
	tinybuf_delete_front(&_buf, good_length);
	[_observer terminalDocument:self changedLines:[_lines subarrayWithRange:NSMakeRange(oldcount, _lines.count-oldcount)]];
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
@property(nonatomic,strong) TerminalDocumentLine* line;
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

- (void)setLine:(TerminalDocumentLine*)line {
	if (_line == line)
		return;
	_line = line;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	NSString* string = _line.string;
	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)([[NSAttributedString alloc] initWithString:string ? string : @"<nil>" attributes:@{
		NSFontAttributeName: _font,
	}]));
	[NSColor.whiteColor setFill];
	CGContextFillRect(context, dirtyRect);
	CGContextSetTextPosition(context, 0, ceil(-_font.descender));
	CTLineDraw(line, context);
	CFRelease(line);
}

@end

@protocol TerminalContentViewDataSource
- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block;
@end

@interface TerminalContentView: NSView
@property(nonatomic) id<TerminalContentViewDataSource> dataSource;
@end

@implementation TerminalContentView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
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

- (NSRect)lineRect {
	return [self backingAlignedRect:NSInsetRect(NSMakeRect(
		0, 0, NSWidth(self.bounds) - 8, NSHeight(_font.boundingRectForFont)
	), kLineXMargin, 0) options:NSAlignAllEdgesOutward];
}

- (void)prepareContentInRect:(const NSRect)rect {
	[_dataSource performWithLines:^(NSArray<TerminalDocumentLine*>* lines) {
		 [self _prepareContentInRect:rect withLines:lines];
	}];
}

- (void)_prepareContentInRect:(const NSRect)rect withLines:(NSArray<TerminalDocumentLine*>*)lines {
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
		if (NSMinY(lineRect) >= NSMaxY(outRect)) {
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
		lineView.line = lines[lines.count - 1 - firstLine - i];
		[_lineViews insertObject:lineView atIndex:i];
		[self addSubview:lineView];
		lineRect.origin.y += NSHeight(lineRect);
		i += 1;
	}
	[super prepareContentInRect:outRect];
}

- (void)invalidateChangedLines:(NSArray<TerminalDocumentLine*>*)lines {
	for (TerminalLineView* lineView in _lineViews) {
		lineView.line = lines[lineView.line.index];
	}
}

@end

@interface TerminalDocument(TerminalContentViewDataSource) <TerminalContentViewDataSource>
@end

@interface TerminalView: NSView<NSStreamDelegate, TerminalDocumentObserver>
@property(readonly,nonatomic) TerminalContentView* contentView;
@property(nonatomic,strong) TerminalDocument* document;
@end

@implementation TerminalView {
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

- (void)setDocument:(TerminalDocument*)document {
	_document.observer = nil;
	document.observer = self;
	_document = document;
	_contentView.dataSource = document;
}

- (void)viewWillDraw {
	[_document performWithLines:^(NSArray<TerminalDocumentLine*>* lines){
		[_contentView setFrameSize:NSMakeSize(
			NSWidth(self.frame),
			// TODO: Thread safety
			lines.count * NSHeight(_contentView.lineRect)
		)];
		[_contentView invalidateChangedLines:lines];
	}];
	[super viewWillDraw];
}

- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSArray<TerminalDocumentLine*>*)lines {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"the lines done changed");
		// TODO: Only redraw what needs to be redrawn.
		self.needsDisplay = YES;
	});
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
	NSApplication* app = [NSApplication sharedApplication];
	NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
	win.contentView.wantsLayer = YES;

	TerminalView* terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

	TerminalDocument* document = [[TerminalDocument alloc] init];
	terminalView.document = document;

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
				[document append:data];
			}
		);
	}

	AppDelegate* appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
