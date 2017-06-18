#include <math.h>
#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NSFont* const systemFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

@interface TerminalLineView: NSView
@property(nonatomic) NSString* string;
@end

@implementation TerminalLineView

- (void)setString:(NSString*)string {
	_string = string;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>([[NSAttributedString alloc] initWithString:self.string attributes:@{
		NSFontAttributeName: systemFont
	}]));
	CGContextSetTextPosition(context, 0, ceil(-systemFont.descender));
	CTLineDraw(line, context);
}
@end

@interface TerminalContentView: NSView {
	NSMutableArray<TerminalLineView*>* _lineViews;
}
@end

@implementation TerminalContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
	}
	return self;
}

#if 0
- (BOOL)wantsUpdateLayer {
	return YES;
}

- (void)updateLayer {
	NSLog(@"updateLayer: %@", NSStringFromRect(self.visibleRect));
}

- (void)drawRect:(NSRect)rect {
	NSLog(@"drawRect: %@", NSStringFromRect(rect));
}

- (NSRect)preparedContentRect {
	NSRect rect = [super preparedContentRect];
	NSLog(@"preparedContentRect %@", NSStringFromRect(rect));
	return rect;
}
#endif

- (void)prepareContentInRect:(const NSRect)rect {
	NSRect lineRect = [self backingAlignedRect:NSMakeRect(
		//0, NSMinY(rect) - fmod(NSMinY(rect), systemFontHeight),
		0, 0, NSWidth(self.bounds), systemFontHeight
	)options:NSAlignAllEdgesOutward];
	CGFloat yOffset = fmod(NSMinY(rect), NSHeight(lineRect));
	lineRect.origin.y = NSMinY(rect) - yOffset;
	const size_t visibleLines = ceil((NSHeight(rect) + yOffset) / NSHeight(lineRect));
	//NSLog(@"in: %@", NSStringFromRect(rect));
	const NSRect outRect = NSMakeRect(NSMinX(lineRect), NSMinY(lineRect), NSWidth(lineRect), visibleLines * NSHeight(lineRect));
	//NSLog(@"out: %@", NSStringFromRect(outRect));

	for (size_t i = 0;;) {
		//NSLog(@"lineRect: %@", NSStringFromRect(lineRect));
		if (i < _lineViews.count) {
			NSView* lineView = [_lineViews objectAtIndex:i];
			if (NSMinY(lineView.frame) == NSMinY(lineRect)) {
				lineRect.origin.y += NSHeight(lineRect);
				i++;
				continue;
			} else if (NSMinY(lineView.frame) < NSMinY(outRect) || NSMaxY(lineView.frame) > NSMaxY(outRect) ) {
				//NSLog(@"prune: %@", NSStringFromRect(lineView.frame));
				[lineView removeFromSuperview];
				[_lineViews removeObjectAtIndex:i];
				continue;
			}
		}
		if (NSMinY(lineRect) > NSMaxY(outRect)) {
			break;
		}
		TerminalLineView* lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
		//NSLog(@"add: %@", NSStringFromRect(lineView.frame));
		lineView.string = [NSString stringWithFormat:@"%@", NSStringFromRect(lineView.frame)];
		[_lineViews insertObject:lineView atIndex:i];
		[self addSubview:lineView];
		lineRect.origin.y += NSHeight(lineRect);
		i += 1;
	}
	[super prepareContentInRect:outRect];
}

@end

@interface TerminalView: NSView<NSStreamDelegate>
@end

@implementation TerminalView {
	NSScrollView* _scrollView;
	TerminalContentView* _contentView;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_contentView = [[TerminalContentView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.bounds), systemFontHeight * 1000000)];
		_contentView.autoresizingMask = NSViewWidthSizable;

		_scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.hasVerticalScroller = YES;
		_scrollView.documentView = _contentView;
		[self addSubview:_scrollView];

#if 0
		_randle = [NSInputStream inputStreamWithFileAtPath:@"/Users/sidney/manylines.txt"];
		_randle.delegate = self;
		[_randle open];
		[_randle scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#endif
	}
	return self;
}

#if 0
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	if (aStream != _randle) { abort(); }
	switch (eventCode) {
	case NSStreamEventHasBytesAvailable: {
		uint8_t buf[8192];
		NSUInteger len = [_randle read:buf maxLength:sizeof(buf)/sizeof(buf[0])];
		NSData* data = [NSData dataWithBytesNoCopy:buf length:len freeWhenDone:NO];
		_contentView.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		//[_contentView scrollToEndOfDocument:nil];
	} break;
	case NSStreamEventEndEncountered:
		[_randle close];
		_randle = nil;
		break;
	default:
		NSLog(@"unknown stream event: %tu", eventCode);
	}
}
#endif

@end

@interface AppDelegate: NSObject<NSApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
@end

char tty[24][80] = {{0}};

int main() {
	auto win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
	win.contentView.wantsLayer = YES;

	auto terminalView = [[TerminalView alloc] initWithFrame:win.contentView.frame];
	terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[win.contentView addSubview:terminalView];

	[win center];
	win.frameAutosaveName = @"Window";
	[win makeKeyAndOrderFront:nil];

	auto app = [NSApplication sharedApplication];
	auto appDelegate = [AppDelegate new];
	app.delegate = appDelegate;
	[app setActivationPolicy:NSApplicationActivationPolicyRegular];
	[app run];
}
