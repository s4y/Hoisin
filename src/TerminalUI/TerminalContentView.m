#import "TerminalContentView.h"

#import "TerminalDocument/TerminalDocument.h"
#import "TerminalLineView.h"
#import "ViewReusePool.h"

static const CGFloat kLineXMargin = 4;

@interface TerminalContentView (TerminalDocumentObserver) <TerminalDocumentObserver>
@end

@implementation TerminalContentView {
	NSMutableDictionary<NSNumber*,TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
	NSFont* _font;
	CGFloat _lineHeight;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableDictionary dictionary];
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

- (void)setDocument:(TerminalDocument*)document {
	_document.observer = nil;
	document.observer = self;
	_document = document;
}

- (void)setFont:(NSFont*)font {
	_font = font;
	_lineHeight = NSHeight([self backingAlignedRect:_font.boundingRectForFont
											options:NSAlignAllEdgesOutward]);
}

- (NSUInteger)maxCharactersForWidth:(CGFloat)width {
	return floor(width / _font.maximumAdvancement.width);
}

- (void)purgeLineView:(NSUInteger)i {
	TerminalLineView* lineView = _lineViews[@(i)];
	[lineView removeFromSuperview];
	[_lineViews removeObjectForKey:@(i)];
	[_lineViewReusePool returnObject:lineView];
}

- (void)prepareContentInRect:(const NSRect)rect {
	[_document performWithLines:^(NSArray<TerminalDocumentLine*>* lines) {
		 [self _prepareContentInRect:rect withLines:lines];
	}];
}

- (void)_prepareContentInRect:(const NSRect)rect withLines:(NSArray<TerminalDocumentLine*>*)lines {
	const size_t firstLine = floor(NSMinY(rect) / _lineHeight);
	const size_t numLines = ceil(NSMaxY(rect) / _lineHeight) - firstLine;
	for (NSNumber* k in _lineViews.allKeys) {
		NSUInteger i = k.unsignedIntegerValue;
		if (i < firstLine || i >= firstLine + numLines)
			[self purgeLineView:i];
	}
	const NSRect preparedRect = NSMakeRect(
		0, firstLine * _lineHeight,
		NSWidth(self.bounds), numLines * _lineHeight
	);
	for (size_t i = firstLine; i < firstLine + numLines; i++) {
		TerminalLineView* lineView = _lineViews[@(i)];
		if (!lineView) {
			NSRect lineRect = NSInsetRect(NSMakeRect(
				0, _lineHeight * i, NSWidth(preparedRect), _lineHeight
			), kLineXMargin, 0);

			lineView = [_lineViewReusePool getObject];
			if (lineView) {
				lineView.frame = lineRect;
			} else {
				lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
				lineView.autoresizingMask = NSViewWidthSizable;
			}
			_lineViews[@(i)] = lineView;
			[self addSubview:lineView];
		}
		lineView.line = lines[i];
		lineView.font = _font;
	}
	[super prepareContentInRect:preparedRect];
}

- (CGFloat)desiredHeight {
	__block CGFloat desiredHeight = 0;
	[_document performWithLines:^(NSArray<TerminalDocumentLine*>* lines) {
		desiredHeight = _lineHeight * lines.count;
	}];
	return desiredHeight;
}

@end

@implementation TerminalContentView (TerminalDocumentObserver)

- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSDictionary<NSNumber*,TerminalDocumentLine*>*)addedLines {
	// TODO: Let us specify a queue for observing the document.
	dispatch_async(dispatch_get_main_queue(), ^{
		[_delegate terminalContentViewMaybeChangedHeight:self];
	});
}

- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSDictionary<NSNumber*,TerminalDocumentLine*>*)changedLines {
	dispatch_async(dispatch_get_main_queue(), ^{
		[changedLines enumerateKeysAndObjectsUsingBlock:^(NSNumber* k, TerminalDocumentLine* v, BOOL* stop) {
			TerminalLineView* lineView = _lineViews[k];
			if (lineView)
				lineView.line = v;
		}];
	});
}

- (void)terminalDocumentInvalidateAllLines:(TerminalDocument*)document {
	dispatch_async(dispatch_get_main_queue(), ^{
		for (NSNumber* k in _lineViews.allKeys)
			[self purgeLineView:k.unsignedIntegerValue];
		[_delegate terminalContentViewMaybeChangedHeight:self];
	});
}

@end
