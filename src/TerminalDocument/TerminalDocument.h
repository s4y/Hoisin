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
- (void)terminalDocument:(TerminalDocument*)document addedLines:(NSArray<TerminalDocumentLine*>*)addedLines changedLines:(NSArray<TerminalDocumentLine*>*)changedLines;
@end

@interface TerminalDocument: NSObject
@property (nonatomic,weak) id<TerminalDocumentObserver> observer;
@property (nonatomic) size_t softWrapColumn;

- (void)append:(dispatch_data_t)data;
@end
