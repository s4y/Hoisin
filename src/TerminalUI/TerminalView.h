#pragma once

#import <AppKit/AppKit.h>

@class TerminalContentView;

@interface TerminalView: NSView
@property(readonly,nonatomic) TerminalContentView* contentView;
@end
