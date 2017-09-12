#pragma once

#import <AppKit/AppKit.h>

@interface TerminalDocumentLine: NSObject
@property(readonly,nonatomic,strong) NSString* string;
@property(readonly,nonatomic) size_t index;

- (instancetype)initWithString:(NSString*)string index:(size_t)index NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@class TerminalDocument;
@protocol TerminalDocumentObserver
// Lines were added.
- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSArray<TerminalDocumentLine*>*)addedLines;

// Lines were changed.
- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSArray<TerminalDocumentLine*>*)changedLines;

// Any lines, and the number of lines, may have changed. Currently used for
// re-wrapping. Should be replaced with something better, like a log of edits.
- (void)terminalDocumentInvalidateAllLines:(TerminalDocument*)document;
@end

@interface TerminalDocument: NSObject
@property (nonatomic,weak) id<TerminalDocumentObserver> observer;

// TODO: Move this into a "view" layer (view in the sense of "string view" or
// "buffer view", not NSView).
@property (nonatomic) size_t softWrapColumn;

- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block;
- (void)append:(dispatch_data_t)data;
@end
