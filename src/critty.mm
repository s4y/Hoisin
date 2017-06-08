#include <stdlib.h>

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

@interface TerminalContentView: NSView
@end

@implementation TerminalContentView
- (void)drawRect:(NSRect)dirtyRect {
	NSAttributedString* string = [[NSAttributedString alloc] initWithString:@"1234567890abcABCéø"];
	CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>(string));
	CTLineDraw(line, [NSGraphicsContext currentContext].CGContext);
}
@end

@interface TerminalView: NSView
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
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

char tty[24][80] = {{0}};

int main() {
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
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
