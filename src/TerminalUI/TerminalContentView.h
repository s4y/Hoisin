#pragma once

#import <AppKit/AppKit.h>

@class TerminalDocument;

@interface TerminalContentView: NSView
@property(nonatomic) TerminalDocument* document;
@property(nonatomic) NSFont* font;

@property(readonly) CGFloat desiredHeight;
@end
