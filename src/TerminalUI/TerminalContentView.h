#pragma once

#import <AppKit/AppKit.h>

@class TerminalDocumentLine;

@protocol TerminalContentViewDataSource
- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block;
@end

@interface TerminalContentView: NSView
@property(nonatomic) id<TerminalContentViewDataSource> dataSource;
@property(nonatomic) NSFont* font;

// TODO: Change to a model where we're the observer and inform the document
// view when we want to change size.
- (CGFloat)heightForLineCount:(NSUInteger)lineCount;
- (void)changeLines:(NSArray<TerminalDocumentLine*>*)lines;
- (void)invalidateAllLines;
@end
