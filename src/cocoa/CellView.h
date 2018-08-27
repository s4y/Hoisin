#pragma once

#import <AppKit/AppKit.h>

#include "critty/Cell.hpp"

@interface CellView: NSView
@property (assign,nonatomic) critty::Cell* cell;
@end
