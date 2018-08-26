#import "AppDelegate.h"

static void addSubmenu(NSMenu* menu, NSString* title, void(^build)(NSMenu*)) {
	NSMenu* submenu = [[NSMenu alloc] initWithTitle:title];
	build(submenu);
	[menu addItemWithTitle:title action:nil keyEquivalent:@""].submenu = submenu;
}

@implementation AppDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	NSString* appName = NSBundle.mainBundle.infoDictionary[(NSString*)kCFBundleNameKey];
	NSMenu* mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
	addSubmenu(mainMenu, appName, ^(NSMenu* appMenu){
		[appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
	});
	addSubmenu(mainMenu, @"File", ^(NSMenu* fileMenu){
		[fileMenu addItemWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];
		[fileMenu addItemWithTitle:@"Open…" action:@selector(openDocument:) keyEquivalent:@"o"];
		[fileMenu addItem:[NSMenuItem separatorItem]];
		[fileMenu addItemWithTitle:@"Close" action:@selector(performClose:) keyEquivalent:@"w"];
	});
	NSLog(@"mainMenu: %@", mainMenu);
	NSApp.mainMenu = mainMenu;
}
@end
