#pragma once

#include <stdlib.h>
#include <string.h>

#define TINYBUF_GROW 1024

typedef struct {
	size_t cap;
	size_t len;
	uint32_t* buf;
} tinybuf_t;

static inline void tinybuf_init(tinybuf_t* tbuf) {
	*tbuf = (tinybuf_t){0};
}

static inline void tinybuf_free(tinybuf_t* tbuf) {
	if (!tbuf->buf)
		return;
	free(tbuf->buf);
}

static inline void tinybuf_append(tinybuf_t* tbuf, uint32_t val) {
	if (tbuf->len == tbuf->cap) {
		tbuf->cap += TINYBUF_GROW;
		tbuf->buf = realloc(tbuf->buf, tbuf->cap * sizeof(uint32_t));
	}
	tbuf->buf[tbuf->len++] = val;
}

static inline void tinybuf_delete_front(tinybuf_t* tbuf, size_t count) {
	const size_t delbytes = count * sizeof(uint32_t);
	memmove(tbuf->buf, tbuf->buf + delbytes, delbytes);
	tbuf->len -= count;
	size_t newcap = tbuf->len + (TINYBUF_GROW - tbuf->len % TINYBUF_GROW);
	if (newcap != tbuf->cap) {
		tbuf->cap = newcap;
		tbuf->buf = realloc(tbuf->buf, tbuf->cap * sizeof(uint32_t));
	}
}
