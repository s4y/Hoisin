#include <math.h>
#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NSFont* const systemFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

@interface TerminalLineView: NSView
@property(nonatomic) NSString* string;
@end

@implementation TerminalLineView: NSView

- (void)setString:(NSString*)string {
	_string = string;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>([[NSAttributedString alloc] initWithString:self.string attributes:@{
		NSFontAttributeName: systemFont
	}]));
	CGContextSetTextPosition(context, 0, 0);
	CTLineDraw(line, context);
}
@end

@interface TerminalContentView: NSView {
	NSMutableArray<TerminalLineView*>* _lineViews;
}
@end

@implementation TerminalContentView

#if 0
- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
	}
	return self;
}

- (BOOL)wantsUpdateLayer {
	return YES;
}

- (void)updateLayer {
	NSLog(@"updateLayer: %@", NSStringFromRect(self.visibleRect));
}

- (void)drawRect:(NSRect)rect {
	NSLog(@"drawRect: %@", NSStringFromRect(rect));
}

- (NSRect)preparedContentRect {
	NSRect rect = [super preparedContentRect];
	NSLog(@"preparedContentRect %@", NSStringFromRect(rect));
	return rect;
}
#endif

- (void)prepareContentInRect:(NSRect)rect {
	NSLog(@"in: (%f) %@", systemFontHeight, NSStringFromRect(rect));
	[_lineViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	_lineViews = [NSMutableArray arrayWithCapacity:ceil(NSHeight(rect) / systemFontHeight)];
	rect.origin.y -= fmod(NSMinY(rect), systemFontHeight);
	rect.size.height += systemFontHeight - fmod(NSHeight(rect), systemFontHeight);
	NSLog(@"out: %@", NSStringFromRect(rect));
	for (
		NSRect lineRect = NSMakeRect(0, NSMinY(rect) - fmod(NSMinY(rect), systemFontHeight), NSWidth(self.bounds), systemFontHeight);
		NSMinY(lineRect) < NSMaxY(rect);
		lineRect.origin.y += systemFontHeight
	) {
		TerminalLineView* lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
		lineView.string = [NSString stringWithFormat:@"%@", NSStringFromRect(lineRect)];
		[_lineViews addObject:lineView];
		[self addSubview:lineView];
	}
	[super prepareContentInRect:rect];
}

@end

@interface TerminalView: NSView<NSStreamDelegate>
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
	TerminalContentView* _contentView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 10000)];
		_contentView.autoresizingMask = NSViewWidthSizable;

		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.documentView = _contentView;
		[self addSubview:_scrollView];

#if 0
		_randle = [NSInputStream inputStreamWithFileAtPath:@"/Users/sidney/manylines.txt"];
		_randle.delegate = self;
		[_randle open];
		[_randle scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#endif
	}
	return self;
}

#if 0
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	if (aStream != _randle) { abort(); }
	switch (eventCode) {
	case NSStreamEventHasBytesAvailable: {
		uint8_t buf[8192];
		NSUInteger len = [_randle read:buf maxLength:sizeof(buf)/sizeof(buf[0])];
		NSData* data = [NSData dataWithBytesNoCopy:buf length:len freeWhenDone:NO];
		_contentView.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		//[_contentView scrollToEndOfDocument:nil];
	} break;
	case NSStreamEventEndEncountered:
		[_randle close];
		_randle = nil;
		break;
	default:
		NSLog(@"unknown stream event: %tu", eventCode);
	}
}
#endif

@end

@interface AppDelegate: NSObject<NSApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
@end

char tty[24][80] = {{0}};

int main() {
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
	win.contentView.wantsLayer = YES;

	auto terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

	auto app = [NSApplication sharedApplication];
	auto appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
