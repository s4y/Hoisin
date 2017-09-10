#pragma once

#import <AppKit/AppKit.h>

@class TerminalContentView;
@class TerminalDocument;

@protocol TerminalContentViewDelegate
- (void)terminalContentViewMaybeChangedHeight:(TerminalContentView*)terminalContentView;
@end

@interface TerminalContentView: NSView
@property(nonatomic) id<TerminalContentViewDelegate> delegate;
@property(nonatomic) TerminalDocument* document;
@property(nonatomic) NSFont* font;

@property(readonly) CGFloat desiredHeight;
@end
