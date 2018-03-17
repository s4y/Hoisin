#pragma once

#import "TerminalDocument.h"

@interface TerminalDocumentLens: NSObject
@property (nonatomic,strong) TerminalDocument* document;
@property (nonatomic,weak) id<TerminalDocumentObserver> observer;
@property (nonatomic) size_t softWrapColumn;
@end
