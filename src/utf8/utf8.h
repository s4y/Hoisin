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
    case UTF8_OK:
      if (byte < 0x80) {
        context->codepoint = byte;
      } else if (byte < 0xc0){
        context->state = UTF8_ERROR;
      } else if (byte < 0xe0){
        context->state = 1;
        context->codepoint = byte & 0x1f;
      } else if (byte < 0xf0) {
        context->state = 2;
        context->codepoint = byte & 0xf;
      } else if (byte < 0xf8) {
        context->state = 3;
        context->codepoint = byte & 0x7;
      } else {
        context->state = UTF8_ERROR;
      }
      break;
    case 1:
    case 2:
    case 3:
      if (byte >= 0x80 && byte <= 0xbf) {
        context->state -= 1;
        context->codepoint =
          (context->codepoint << 6) | (byte & 0x3f);
      } else {
        context->state = UTF8_ERROR;
      }
  }
}
