#include <math.h>
#include <stdlib.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

extern "C" {
void CGContextSetFontSmoothingStyle(CGContextRef, int);
CGBlendMode CGContextGetBlendMode(CGContextRef);
}

NSFont* const systemFont = [NSFont userFixedPitchFontOfSize:[NSFont systemFontSize]];
const CGFloat systemFontHeight = NSHeight(systemFont.boundingRectForFont);

@interface ViewReusePool<__covariant ViewType:NSView*>: NSObject
@property(nonatomic,strong) NSMutableArray<ViewType>* freeObjects;

- (ViewType)getObject;
- (void)returnObject:(ViewType)object;
@end

@implementation ViewReusePool
- (instancetype)init {
	if ((self = [super init])) {
		self.freeObjects = [NSMutableArray array];
	}
	return self;
}

- (id)getObject {
	id ret = [_freeObjects lastObject];
	if (ret) { [_freeObjects removeLastObject]; }
	return ret;
}

- (void)returnObject:(id)object {
	[object prepareForReuse];
	[_freeObjects addObject:object];
}
@end

@interface TerminalLineView: NSView
@property(nonatomic,strong) NSString* string;
@end

@implementation TerminalLineView

- (CALayer*)makeBackingLayer {
	CALayer* layer = [super makeBackingLayer];
	layer.backgroundColor = NSColor.whiteColor.CGColor;
	layer.opaque = YES;
	return layer;
}

// - (BOOL)isOpaque {
// 	return YES;
// }

- (void)setString:(NSString*)string {
	_string = string;
	self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	CTLineRef line = CTLineCreateWithAttributedString(static_cast<CFAttributedStringRef>([[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", self.string, NSStringFromRect(self.frame)] attributes:@{
		NSFontAttributeName: systemFont,
	}]));
	NSLog(@"%d", CGContextGetBlendMode(context));
	CGContextSetBlendMode(context, kCGBlendModeMultiply);
	[NSColor.whiteColor setFill];
	CGContextFillRect(context, dirtyRect);
	CGContextSetFontSmoothingStyle(context, 48);
	CGContextSetAllowsFontSmoothing(context, true);
	CGContextSetShouldSmoothFonts(context, true);
	//CGContextSetAllowsAntialiasing(context, false);
	CGContextSetShouldSubpixelQuantizeFonts(context, true);
	CGContextSetAllowsFontSubpixelQuantization(context, true);

	CGContextSetTextPosition(context, 0, ceil(-systemFont.descender));
	CTLineDraw(line, context);
	CFRelease(line);
}

@end

@interface TerminalContentView: NSView {
	NSMutableArray<TerminalLineView*>* _lineViews;
	ViewReusePool<TerminalLineView*>* _lineViewReusePool;
}
@end

@implementation TerminalContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_lineViews = [NSMutableArray array];
		_lineViewReusePool = [[ViewReusePool alloc] init];
	}
	return self;
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[self prepareContentInRect:self.visibleRect];
}

- (void)prepareContentInRect:(const NSRect)rect {
	NSRect lineRect = [self backingAlignedRect:NSMakeRect(
		0, 0, NSWidth(self.bounds), systemFontHeight
	) options:NSAlignAllEdgesOutward];
	CGFloat yOffset = fmod(NSMinY(rect), NSHeight(lineRect));
	lineRect.origin.y = NSMinY(rect) - yOffset;
	const size_t visibleLines = ceil((NSHeight(rect) + yOffset) / NSHeight(lineRect));
	const size_t firstLine = NSMinY(lineRect) / NSHeight(lineRect);
	const NSRect outRect = NSMakeRect(NSMinX(lineRect), NSMinY(lineRect), NSWidth(lineRect), visibleLines * NSHeight(lineRect));

	for (size_t i = 0;;) {
		if (i < _lineViews.count) {
			TerminalLineView* lineView = [_lineViews objectAtIndex:i];
			if (NSMinY(lineView.frame) < NSMinY(outRect) || NSMaxY(lineView.frame) > NSMaxY(outRect) ) {
				[lineView removeFromSuperview];
				[_lineViews removeObjectAtIndex:i];
				[_lineViewReusePool returnObject:lineView];
				continue;
			} else if (NSMinY(lineView.frame) == NSMinY(lineRect)) {
				lineRect.origin.y += NSHeight(lineRect);
				i += 1;
				continue;
			}
		}
		if (NSMinY(lineRect) > NSMaxY(outRect)) {
			break;
		}
		TerminalLineView* lineView = [_lineViewReusePool getObject];
		if (lineView) {
			lineView.frame = lineRect;
		} else {
			lineView = [[TerminalLineView alloc] initWithFrame:lineRect];
			lineView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
			lineView.layerContentsPlacement = NSViewLayerContentsPlacementBottomLeft;
			lineView.autoresizingMask = NSViewWidthSizable;
		}
		lineView.string = [NSString stringWithFormat:@"%zu", firstLine + i];
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
