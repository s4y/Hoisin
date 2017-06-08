#include <stdlib.h>

#import <Cocoa/Cocoa.h>

#ifndef DEBUG
#define DEBUG 0
#endif

@interface TerminalView: NSView
@end

@implementation TerminalView
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
	terminalView.autoresizingMask = NSviewwidthsizable | NSViewHeightSizable;

	[win.contentView addSubview:[[TerminalView alloc] initWithFrame:NSZeroRect];
	[win center];
	[win makeKeyAndOrderFront:nil];

	auto app = [NSApplication sharedApplication];
	auto appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	if (DEBUG && getenv("CRITTY_ACTIVATE_ON_LAUNCH")) {
		[app activateIgnoringOtherApps:YES];
	}
	[app run];
}
