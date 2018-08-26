#include <math.h>
#include <stdlib.h>
#include <string>

#import <AppKit/AppKit.h>

#include "critty/Cell.hpp"
#include "critty/Document.hpp"
#include "critty/io/FileReader.hpp"

#include "cocoa/AppDelegate.h"
#include "cocoa/Document.h"

// #import "TerminalUI/TerminalUI.h"

// Data model:
// - A critty window is a document.
// - A document contains zero or more cells, usually displayed sequentially in
//   a scroll area, but may be displayed in other ways (pinned to the top or
//   bottom of the viewport, for example).
// - A cell may be have arbitrary content. Some types of cells might be:
//   - Static text
//   - A possibly-interactive pty with scrollback.
//   - An image or HTML document.

int main(int argc, char* argv[]) {
	NSApplication* app = [NSApplication sharedApplication];

#if 0
	TerminalView* terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];
#endif

	// if (argc != 2)
	// 	return 1;

	// critty::Document document;

	// if (std::unique_ptr<char> path {realpath(argv[1], nullptr)}) {
	// 	if (std::unique_ptr<critty::io::Reader> reader =
	// 		critty::io::ReaderForFile(path.get())) {
	// 		critty::Cell cell;
	// 		cell.AddInput(std::move(reader));
	// 		document.AddCell(std::move(cell));
	// 	}
	// }
	// return 2;

	// std::unique_ptr<critty::io::Reader> reader =
	// 	critty::io::ReaderForFile(argv[1]);
	// if (!reader) {
	// 	return 1;
	// }

	// reader->read([&](const void* buf, size_t len){
	// 		NSLog(@"Read: %p of size %zu", buf, len);
	// });

	AppDelegate* appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
