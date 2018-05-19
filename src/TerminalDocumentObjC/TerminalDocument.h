#pragma once

#import <AppKit/AppKit.h>

@interface TerminalDocumentLine: NSObject
@property(readonly,nonatomic,strong) NSString* string;

- (instancetype)initWithString:(NSString*)string;
- (instancetype)init NS_UNAVAILABLE;
@end

@class TerminalDocument;
@protocol TerminalDocumentObserver
// Lines were added.
- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSDictionary<NSNumber*,TerminalDocumentLine*>*)addedLines;

// Lines were changed.
- (void)terminalDocument:(TerminalDocument*)document changedLines:(NSDictionary<NSNumber*,TerminalDocumentLine*>*)changedLines;

// Any lines, and the number of lines, may have changed. Currently used for
// re-wrapping. Should be replaced with something better, like a log of edits.
- (void)terminalDocumentInvalidateAllLines:(TerminalDocument*)document;
@end

@interface TerminalDocument: NSObject
@property (nonatomic,weak) id<TerminalDocumentObserver> observer;

- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block;
- (void)append:(dispatch_data_t)data;
@end