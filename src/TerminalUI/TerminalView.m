#import "TerminalView.h"
#import "TerminalContentView.h"

#import "TerminalDocument/TerminalDocument.h"

@interface TerminalDocument(TerminalContentViewDataSource) <TerminalContentViewDataSource>
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

- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSArray<TerminalDocumentLine*>*)addedLines {
	// TODO: Let us specify a queue for observing the document.
	dispatch_async(dispatch_get_main_queue(), ^{
		self.needsLayout = YES;
	});
}

- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSArray<TerminalDocumentLine*>*)changedLines {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_contentView changeLines:changedLines];
	});
}

- (void)terminalDocumentInvalidateAllLines:(TerminalDocument*)document {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_contentView invalidateAllLines];
	});
}

@end
