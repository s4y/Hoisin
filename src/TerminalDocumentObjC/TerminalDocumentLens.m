#import "TerminalDocumentLens.h"

@interface TerminalDocumentLens(TerminalDocumentObserver) <TerminalDocumentObserver>
@end

@implementation TerminalDocumentLens
- (void)setDocument:(TerminalDocument*)document {
	_document.observer = nil;
	_document = document;
	_document.observer = self;
}
@end

@implementation TerminalDocumentLens(TerminalDocumentObserver)

- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSDictionary<NSNumber*,TerminalDocumentLine*>*)addedLines {
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
