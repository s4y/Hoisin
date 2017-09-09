#pragma once

// Maybe remove this dependency?
#import "TerminalDocument/TerminalDocument.h"

#import <AppKit/AppKit.h>

@class TerminalContentView;

@interface TerminalView: NSView<NSStreamDelegate, TerminalDocumentObserver>
@property(readonly,nonatomic) TerminalContentView* contentView;
@property(nonatomic,strong) TerminalDocument* document;
@end
