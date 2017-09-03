#pragma once

#include <inttypes.h>

typedef enum {
  UTF8_OK = 0,
  UTF8_ERROR = 4,
} utf8_decode_state_t;

typedef struct {
  utf8_decode_state_t state;
  uint32_t codepoint;
} utf8_decode_context_t;

static inline void utf8_decode(
  utf8_decode_context_t *context, unsigned char byte
) {
  switch ((int)context->state) {
    case UTF8_OK:							// We're not in the middle of a character
      if (byte < 0x80) {					// If the high bit is 0, it's ASCII
        context->codepoint = byte;			// Simple case, the remaining 7 bits are the codepoint
      } else if (byte < 0xc0){				// A leading byte should never match this pattern 10xxxxxx
        context->state = UTF8_ERROR;
      } else if (byte < 0xe0){				// 110xxxxx indicates that we're expecting 1 more byte of UTF-8 (that will match 10xxxxxx)
        context->state = 1;
        context->codepoint = byte & 0x1f;
      } else if (byte < 0xf0) {				// 1110xxxx indicates that we're expecting 2 more bytes of UTF-8 (that will match 10xxxxxx)
        context->state = 2;
        context->codepoint = byte & 0xf;
      } else if (byte < 0xf8) {				// 11110xxx -> 3 more bytes
        context->state = 3;
        context->codepoint = byte & 0x7;
      } else {
        context->state = UTF8_ERROR;
      }
      break;
    case 1:
    case 2:
    case 3:
      if (byte >= 0x80 && byte <= 0xbf) {	// 10000000 <-> 10111111 - Additional bytes should match 10xxxxxx
        context->state -= 1;
        context->codepoint =
          (context->codepoint << 6) | (byte & 0x3f); // Grab the last 6 bits of the byte and append them to the codepoint
      } else {
        context->state = UTF8_ERROR;
      }
  }
}
