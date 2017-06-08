#import <Cocoa/Cocoa.h>

@interface AppDelegate: NSObject<NSApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
@end

char tty[24][80] = {{0}};

int main() {
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
	win.contentView.wantsLayer = YES;
	[win center];
	[win makeKeyAndOrderFront:nil];

	auto appDelegate = [AppDelegate new];
	auto app = [NSApplication sharedApplication];
	app.delegate
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
