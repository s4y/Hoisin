#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NSFont* const systemFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

@interface TerminalLineView: NSView
@end

@implementation TerminalLineView: NSView
@end

@interface TerminalContentView: NSView
@end

@implementation TerminalContentView

#if 0
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
	NSLog(@"prepareContentInRect: %@", NSStringFromRect(rect));
	NSView* rectView = [[NSView alloc] initWithFrame:rect];
	// rectView.editable = NO;
	// rectView.wantsLayer = YES;
	rectView.layer.borderColor = NSColor.blackColor.CGColor;
	rectView.layer.borderWidth = 10;
	[self addSubview:rectView];
}

#if 0
- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	for (
		CGFloat pos = NSMinY(dirtyRect) - fmod(NSMinY(dirtyRect), systemFontHeight);
		pos < NSMaxY(dirtyRect);
		pos += systemFontHeight
	) {
		NSString* string = [NSString stringWithFormat:@"%fx%f (%d)", NSMinX(dirtyRect), pos, _drawCount];
		CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>([[NSAttributedString alloc] initWithString:string attributes:@{
			NSFontAttributeName: systemFont
		}]));
		CGContextSetTextPosition(context, NSMinX(dirtyRect), pos);
		CTLineDraw(line, context);
	}
	_drawCount++;
}
#endif
@end

@interface TerminalView: NSView<NSStreamDelegate>
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
	TerminalContentView* _contentView;
	//NSTextView* _contentView;
	NSInputStream* _randle;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 10000)];
#if 0
		_contentView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 0)];
		_contentView.autoresizingMask = NSViewWidthSizable;
		_contentView.editable = NO;
		_contentView.richText = NO;
		_contentView.font = [NSFont userFixedPitchFontOfSize:0];
		_contentView.layoutManager.allowsNonContiguousLayout = YES;
#endif

		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.documentView = _contentView;
		[self addSubview:_scrollView];

		_randle = [NSInputStream inputStreamWithFileAtPath:@"/Users/sidney/manylines.txt"];
		_randle.delegate = self;
		[_randle open];
		[_randle scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
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
