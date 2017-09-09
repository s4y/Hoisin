#import "TerminalContentView.h"

#import "TerminalLineView.h"
#import "ViewReusePool.h"
#import "TerminalDocument/TerminalDocument.h"

static const CGFloat kLineXMargin = 4;

@implementation TerminalContentView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
	NSFont* _font;
	CGFloat _lineHeight;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
		_lineViewReusePool = [[ViewReusePool alloc] init];
		self.font = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
	}
	return self;
}

- (BOOL)isFlipped {
	// A flipped coordinate space makes it easier to add lines: the existing
	// lines "stick" to the top and don't have to be repositioned or redrawn.
	return YES;
}

- (void)setFont:(NSFont*)font {
	_font = font;
	_lineHeight = NSHeight([self backingAlignedRect:_font.boundingRectForFont
											options:NSAlignAllEdgesOutward]);
}

- (CGFloat)heightForLineCount:(NSUInteger)lineCount {
	return lineCount * _lineHeight;
}

- (void)purgeLineViewAtIndex:(NSUInteger)i {
	TerminalLineView* lineView = _lineViews[i];
	[lineView removeFromSuperview];
	[_lineViews removeObjectAtIndex:i];
	[_lineViewReusePool returnObject:lineView];
}

- (void)prepareContentInRect:(const NSRect)rect {
	[_dataSource performWithLines:^(NSArray<TerminalDocumentLine*>* lines) {
		 [self _prepareContentInRect:rect withLines:lines];
	}];
}

- (void)_prepareContentInRect:(const NSRect)rect withLines:(NSArray<TerminalDocumentLine*>*)lines {
	const size_t firstLine = floor(NSMinY(rect) / _lineHeight);
	const size_t numLines = ceil(NSMaxY(rect) / _lineHeight) - firstLine;
	const NSRect preparedRect = NSMakeRect(
		rect.origin.x, firstLine * _lineHeight,
		rect.size.width, numLines * _lineHeight
	);

	NSRect lineRect = NSInsetRect(NSMakeRect(
		preparedRect.origin.x, preparedRect.origin.y,
		preparedRect.size.width, _lineHeight
	), kLineXMargin, 0);

	for (size_t i = 0;;) {
		TerminalLineView* lineView;
		if (i < _lineViews.count) {
			lineView = _lineViews[i];
			if (
				NSMinY(lineView.frame) < NSMinY(lineRect) ||
				NSMinY(lineRect) >= NSMaxY(preparedRect)
			) {
				[self purgeLineViewAtIndex:i];
				continue;
			} else if (!NSEqualRects(lineView.frame, lineRect))
				lineView = nil;
		}
		if (NSMinY(lineRect) >= NSMaxY(preparedRect))
			break;
		if (!lineView) {
			lineView = [_lineViewReusePool getObject];
			if (lineView) {
				lineView.frame = lineRect;
			} else {
				lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
				lineView.autoresizingMask = NSViewWidthSizable;
			}
			[_lineViews insertObject:lineView atIndex:i];
			[self addSubview:lineView];
		}
		lineView.line = lines[firstLine + i];
		lineView.font = _font;
		lineRect.origin.y += _lineHeight;
		i++;
	}
	[super prepareContentInRect:preparedRect];
}

- (void)changeLines:(NSArray<TerminalDocumentLine*>*)lines {
	// TODO: Passing in a dictionary, and dropping the index from the lines themselves, might make more sense.
	NSMutableDictionary<NSNumber*, TerminalDocumentLine*>* changedLinesDict = [NSMutableDictionary dictionary];
	for (TerminalDocumentLine* line in lines) {
		changedLinesDict[@(line.index)] = line;
	}
	for (TerminalLineView* lineView in _lineViews) {
		TerminalDocumentLine* newLine = changedLinesDict[@(lineView.line.index)];
		if (newLine)
			lineView.line = newLine;
	}
}

- (void)invalidateAllLines {
	while ([_lineViews firstObject])
		[self purgeLineViewAtIndex:0];
}

@end
