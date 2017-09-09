#import "TerminalLineView.h"

#import "TerminalDocument/TerminalDocument.h"

@implementation TerminalLineView

- (BOOL)isOpaque {
	return YES;
}

- (void)setLine:(TerminalDocumentLine*)line {
	if (_line == line)
		return;
	_line = line;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	NSString* string = _line.string;
	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)([[NSAttributedString alloc] initWithString:string ? string : @"<nil>" attributes:@{
		NSFontAttributeName: _font,
	}]));
	[NSColor.whiteColor setFill];
	CGContextFillRect(context, dirtyRect);
	CGContextSetTextPosition(context, 0, ceil(-_font.descender));
	CTLineDraw(line, context);
	CFRelease(line);
}

@end
