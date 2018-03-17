#import "TerminalDocument.h"

#include "utf8/utf8.h"
#include "tinybuf/tinybuf.h"

@implementation TerminalDocumentLine
- (instancetype)initWithString:(NSString*)string {
	if ((self = [super init])) {
		if (!string) {
			abort();
		}
		_string = string;
	}
	return self;
}
@end

@implementation TerminalDocument {
	// Consider saving the original data.
	// NSMutableArray<dispatch_data_t>* _originalData;
	NSMutableArray<TerminalDocumentLine*>* _lines;
	NSMutableArray<TerminalDocumentLine*>* _softLines;
	dispatch_queue_t _queue;
	size_t _currentLine;
	tinybuf_t _buf;
	utf8_decode_context_t _utf8_decode_context;
}

- (instancetype)init {
	if ((self = [super init])) {
		_queue = dispatch_queue_create(
			self.class.className.UTF8String,
			DISPATCH_QUEUE_CONCURRENT
		);
		_lines = [NSMutableArray array];
		_currentLine = -1;
		tinybuf_init(&_buf);
	}
	return self;
}

- (void)dealloc {
	tinybuf_free(&_buf);
}

- (void)performWithLines:(void(^)(NSArray<TerminalDocumentLine*>*))block {
	dispatch_sync(_queue, ^{ block(_lines); });
}

// DEBUG
- (void)replaceLastLine:(NSString*)string {
	dispatch_barrier_sync(_queue, ^{
		size_t i = _lines.count - 1;
		TerminalDocumentLine* newLine = [[TerminalDocumentLine alloc] initWithString:string];
		[_lines replaceObjectAtIndex:i withObject:newLine];
		[_observer terminalDocument:self changedLines:@{@(i): newLine}];
	});
}

- (void)setSoftWrapColumn:(size_t)softWrapColumn {
	if (_softWrapColumn == softWrapColumn)
		return;
	_softWrapColumn = softWrapColumn;
}

- (void)append:(dispatch_data_t)data {
	dispatch_barrier_sync(_queue, ^{ [self _append:data]; });
}

- (void)_append:(dispatch_data_t)data {
	__block size_t good_length = 0;
	dispatch_data_apply(data, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
		for (size_t i = 0; i < size; i++) {
			utf8_decode(&_utf8_decode_context, ((unsigned char*)buffer)[i]);
			switch (_utf8_decode_context.state) {
				case UTF8_OK:
					tinybuf_append(&_buf, _utf8_decode_context.codepoint);
					good_length = _buf.len;
					break;
				case UTF8_ERROR:
					/* Append a replacement character (�) */
					tinybuf_append(&_buf, 0xfffd);
					_utf8_decode_context.state = UTF8_OK;
					break;
				default:
					break;
			}
		}
		return true;
	});
	size_t oldcount = _lines.count;
	for (size_t i = 0, start = 0; i < good_length; i++) {
		// TODO: Save in-progress line to an ivar.
		if (i == good_length - 1 || _buf.buf[i] == '\n') {
			[_lines addObject:[[TerminalDocumentLine alloc] initWithString:
				[[NSString alloc] initWithBytes:_buf.buf + start
										 length:(i - start) * sizeof(_buf.buf[0])
									   encoding:NSUTF32LittleEndianStringEncoding]
			]];
			i++; // Skip the '\n'
			start = i;
		}
	}
	tinybuf_delete_front(&_buf, good_length);
	NSMutableDictionary* newLines = [NSMutableDictionary dictionary];
	for (size_t i = oldcount; i < _lines.count; i++) {
		newLines[@(i)] = _lines[i];
	}
	[_observer terminalDocument:self addedLines:newLines];
}
@end

