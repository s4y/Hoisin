#import "TerminalView.h"

#import "TerminalContentView.h"

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

- (void)layout {
	[_contentView setFrameSize:NSMakeSize(NSWidth(self.bounds), _contentView.desiredHeight)];
	const NSPoint newOrigin = NSMakePoint(0, NSMaxY(_contentView.bounds));
	[_contentView scrollPoint:newOrigin];
	[super layout];
}

@end
