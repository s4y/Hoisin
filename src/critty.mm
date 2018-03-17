#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

#import <AppKit/AppKit.h>

#include <critty/critty.hpp>

// #import "TerminalUI/TerminalUI.h"

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

#if 0
	TerminalView* terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];
#endif

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

#if 0
	TerminalDocument* document = [[TerminalDocument alloc] init];
	terminalView.contentView.document = document;

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
#endif

	AppDelegate* appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
