#import "Document.h"

#import "critty/Document.hpp"
#include "critty/io/FileReader.hpp"

@interface Document ()
@property (readwrite,nonatomic) NSPoint cascadePoint;
@end

@implementation Document {
	critty::Document document_;
	std::unique_ptr<critty::Document::Handle> cell_added_handle_;
}

- (instancetype)init {
	if ((self = [super init])) {
		cell_added_handle_ = document_.addObserver([&] (critty::Document::CellAddedEvent e){
			[self handleCellAdded:e.cell];
		});
	}
	return self;
}

- (void)handleCellAdded:(critty::Cell&)cell {
}

// + (BOOL)autosavesInPlace {
// 	return YES;
// }

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

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError {
	if (UTTypeConformsTo((__bridge CFStringRef)(typeName), kUTTypePlainText)) {
		if (NSFileHandle* readHandle = [NSFileHandle fileHandleForReadingFromURL:url error:outError]) {
			critty::Cell cell;
			cell.AddInput(critty::io::ReaderForFile(dup(readHandle.fileDescriptor)));
			document_.AddCell(std::move(cell));
			return YES;
		}
	}
	return NO;
}
@end
