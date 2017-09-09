#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

#import <AppKit/AppKit.h>

#import "TerminalDocument/TerminalDocument.h"
#import "TerminalUI/TerminalUI.h"

@interface TerminalDocument(TerminalContentViewDataSource) <TerminalContentViewDataSource>
@end

@interface TerminalView: NSView<NSStreamDelegate, TerminalDocumentObserver>
@property(readonly,nonatomic) TerminalContentView* contentView;
@property(nonatomic,strong) TerminalDocument* document;
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), 0)];
		_contentView.autoresizingMask = NSViewWidthSizable;
		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.contentView.copiesOnScroll = NO;
		_scrollView.documentView = _contentView;
		[self addSubview:_scrollView];
	}
	return self;
}

- (void)setDocument:(TerminalDocument*)document {
	_document.observer = nil;
	document.observer = self;
	_document = document;
	_contentView.dataSource = document;
}

- (void)layout {
	__block size_t lineCount;
	[_document performWithLines:^(NSArray<TerminalDocumentLine*>* lines){
		lineCount = lines.count;
	}];
	[_contentView setFrameSize:NSMakeSize(
		NSWidth(self.frame),
		[_contentView heightForLineCount:lineCount]
	)];
	const NSPoint newOrigin = NSMakePoint(0, NSMaxY(_contentView.bounds));
	[_contentView scrollPoint:newOrigin];
	[super layout];
}

- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSArray<TerminalDocumentLine*>*)addedLines changedLines:(NSArray<TerminalDocumentLine*>*)changedLines {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (addedLines) {
			self.needsLayout = YES;
		} else if (changedLines) {
			[_contentView changeLines:changedLines];
		}
	});
}

@end

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

	TerminalView* terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

	TerminalDocument* document = [[TerminalDocument alloc] init];
	terminalView.document = document;

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

	AppDelegate* appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
