#pragma once

#import <AppKit/AppKit.h>

@class TerminalDocumentLine;

@interface TerminalLineView: NSView
@property(nonatomic,strong) NSFont* font;
@property(nonatomic,strong) TerminalDocumentLine* line;
@end
