#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

#import <AppKit/AppKit.h>

#import "TerminalDocument/TerminalDocument.h"

static const CGFloat kLineXMargin = 4;

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

size_t lineId = 0;

@interface TerminalLineView: NSView
@property(nonatomic,strong) NSFont* font;
@property(nonatomic,strong) TerminalDocumentLine* line;
@end

@implementation TerminalLineView

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
@property(nonatomic) NSFont* font;
@end

@implementation TerminalContentView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
	NSFont* _font;
	CGFloat _lineHeight;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
		_lineViewReusePool = [[ViewReusePool alloc] init];
		self.font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
	}
	return self;
}

- (BOOL)isFlipped {
	// A flipped coordinate space makes it easier to add lines: the existing
	// lines "stick" to the top and don't have to be repositioned or redrawn.
	return YES;
}

- (void)setFont:(NSFont*)font {
	_font = font;
	_lineHeight = NSHeight([self backingAlignedRect:_font.boundingRectForFont
											options:NSAlignAllEdgesOutward]);
}

- (CGFloat)heightForLineCount:(NSUInteger)lineCount {
	return lineCount * _lineHeight;
}

- (void)prepareContentInRect:(const NSRect)rect {
	[_dataSource performWithLines:^(NSArray<TerminalDocumentLine*>* lines) {
		 [self _prepareContentInRect:rect withLines:lines];
	}];
}

- (void)_prepareContentInRect:(const NSRect)rect withLines:(NSArray<TerminalDocumentLine*>*)lines {
	const size_t firstLine = floor(NSMinY(rect) / _lineHeight);
	const size_t numLines = ceil(NSMaxY(rect) / _lineHeight) - firstLine;
	const NSRect preparedRect = NSMakeRect(
		rect.origin.x, firstLine * _lineHeight,
		rect.size.width, numLines * _lineHeight
	);

	NSRect lineRect = NSInsetRect(NSMakeRect(
		preparedRect.origin.x, preparedRect.origin.y,
		preparedRect.size.width, _lineHeight
	), kLineXMargin, 0);

	for (size_t i = 0;;) {
		TerminalLineView* lineView;
		if (i < _lineViews.count) {
			lineView = _lineViews[i];
			if (
				NSMinY(lineView.frame) < NSMinY(lineRect) ||
				NSMinY(lineRect) >= NSMaxY(preparedRect)
			) {
				[lineView removeFromSuperview];
				[_lineViews removeObjectAtIndex:i];
				[_lineViewReusePool returnObject:lineView];
				continue;
			} else if (!NSEqualRects(lineView.frame, lineRect))
				lineView = nil;
		}
		if (NSMinY(lineRect) >= NSMaxY(preparedRect))
			break;
		if (!lineView) {
			lineView = [_lineViewReusePool getObject];
			if (lineView) {
				lineView.frame = lineRect;
			} else {
				lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
				lineView.autoresizingMask = NSViewWidthSizable;
			}
			[_lineViews insertObject:lineView atIndex:i];
			[self addSubview:lineView];
		}
		lineView.line = lines[firstLine + i];
		lineView.font = _font;
		lineRect.origin.y += _lineHeight;
		i++;
	}
	[super prepareContentInRect:preparedRect];
}

- (void)changeLines:(NSArray<TerminalDocumentLine*>*)lines {
	// TODO: Passing in a dictionary, and dropping the index from the lines themselves, might make more sense.
	NSMutableDictionary<NSNumber*, TerminalDocumentLine*>* changedLinesDict = [NSMutableDictionary dictionary];
	for (TerminalDocumentLine* line in lines) {
		changedLinesDict[@(line.index)] = line;
	}
	for (TerminalLineView* lineView in _lineViews) {
		TerminalDocumentLine* newLine = changedLinesDict[@(lineView.line.index)];
		if (newLine)
			lineView.line = newLine;
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
		_scrollView.contentView.copiesOnScroll = NO;
		_scrollView.documentView = _contentView;
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

- (void)layout {
	__block size_t lineCount;
	[_document performWithLines:^(NSArray<TerminalDocumentLine*>* lines){
		lineCount = lines.count;
	}];
	[_contentView setFrameSize:NSMakeSize(
		NSWidth(self.frame),
		[_contentView heightForLineCount:lineCount]
	)];
	const NSPoint newOrigin = NSMakePoint(0, NSMaxY(_contentView.bounds));
	[_contentView scrollPoint:newOrigin];
	[super layout];
}

- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSArray<TerminalDocumentLine*>*)addedLines changedLines:(NSArray<TerminalDocumentLine*>*)changedLines {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (addedLines) {
			self.needsLayout = YES;
		} else if (changedLines) {
			[_contentView changeLines:changedLines];
		}
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
