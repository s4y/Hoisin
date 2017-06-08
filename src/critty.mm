#import <Cocoa/Cocoa.h>

char tty[24][80] = {{0}};

int main() {
	auto pp = [NSApplication sharedApplication];
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
	[win center];
	[win makeKeyAndOrderFront:nil];

	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
