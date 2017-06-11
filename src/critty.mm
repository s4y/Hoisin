#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NSFont* const systemFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

@interface TerminalContentView: NSView
@end

@implementation TerminalContentView {
	unsigned int _drawCount;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		self.canDrawConcurrently = YES;
	}
	return self;
}

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
@end

@interface TerminalView: NSView
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
	//TerminalContentView* _contentView;
	NSTextView* _contentView;
	CVDisplayLinkRef _displayLink;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 0)];
		_contentView.autoresizingMask = NSViewWidthSizable;
		NSLog(@"verticallyResizable was: %d", _contentView.verticallyResizable);
		_contentView.verticallyResizable = YES;
		_contentView.editable = NO;

		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.documentView = _contentView;
		[self addSubview:_scrollView];
	}
	return self;
}

#if 0
- (void)updateDisplayLink {
	CVReturn ret = CVDisplayLinkCreateWithCGDisplay(self.window.screen.deviceDescription[@"NSScreenNumber"], &_displayLink);
	_displayLink = CVDisplayLinkCreateWithCGDisplay(0);
}
#endif

- (BOOL)wantsUpdateLayer {
	return YES;
}

- (void)updateLayer {
	static NSString* const stuff = @"12 34 56 78 90 ";
	NSString* newStuff = [@"" stringByPaddingToLength:stuff.length * 10 withString:stuff startingAtIndex:0];
	NSLog(@"before: %@", NSStringFromRect(_contentView.bounds));
	[_contentView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:newStuff]];
	NSLog(@"after: %@", NSStringFromRect(_contentView.bounds));
	[_contentView scrollPoint:NSMakePoint(0, NSMaxY(_contentView.bounds))];
	//self.needsLayout = YES;
	[CATransaction setCompletionBlock:^{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
			self.needsDisplay = YES;
		});
	}];
}

- (void)layout {
}

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
