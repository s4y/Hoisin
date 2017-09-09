#pragma once

#import <AppKit/AppKit.h>

@class TerminalDocumentLine;

@protocol TerminalContentViewDataSource
- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block;
@end

@interface TerminalContentView: NSView
@property(nonatomic) id<TerminalContentViewDataSource> dataSource;
@property(nonatomic) NSFont* font;

- (CGFloat)heightForLineCount:(NSUInteger)lineCount;
- (void)changeLines:(NSArray<TerminalDocumentLine*>*)lines;
@end
