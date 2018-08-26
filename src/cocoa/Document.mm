#import "Document.h"

@interface Document ()
@property (readwrite,nonatomic) NSPoint cascadePoint;
@end

@implementation Document
+ (BOOL)autosavesInPlace {
	return YES;
}

- (void)makeWindowControllers {
	NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
	[window cascadeTopLeftFromPoint:NSMakePoint(100, 100)];
	NSWindowController* controller = [[NSWindowController alloc] initWithWindow:window];
	[window setFrameUsingName:@"Document Window" force:NO];
	controller.windowFrameAutosaveName = @"Document Window";
	NSPoint cascadePoint = NSMakePoint(NSMinX(window.frame), NSMaxY(window.frame));
	if (Document* currentDocument = NSDocumentController.sharedDocumentController.currentDocument)
		cascadePoint = currentDocument.cascadePoint;
	self.cascadePoint = [window cascadeTopLeftFromPoint:cascadePoint];
	[self addWindowController:controller];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	return [NSData data];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	return YES;
}
@end
