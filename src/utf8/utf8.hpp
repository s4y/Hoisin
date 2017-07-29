#pragma once

#include <inttypes.h>

namespace utf8 {

struct Decoder {
	enum class State {
	  OK,
	  More1,
	  More2,
	  More3,
	  Error,
	};

	void Decode(unsigned char byte) {
		switch (state) {
			case State::OK:
				if (byte < 0x80) {
					codepoint = byte;
				} else if (byte < 0xc0){
					state = State::Error;
				} else if (byte < 0xe0){
					state = State::More1;
					codepoint = byte & 0x1f;
				} else if (byte < 0xf0) {
					state = State::More2;
					codepoint = byte & 0xf;
				} else if (byte < 0xf8) {
					state = State::More3;
					codepoint = byte & 0x7;
				} else {
					state = State::Error;
				}
				break;
			case State::More1:
			case State::More2:
			case State::More3:
				if (byte >= 0x80 && byte <= 0xbf) {
					state = static_cast<State>(static_cast<int>(state)-1);
					codepoint =
						(codepoint << 6) | (byte & 0x3f);
				} else {
					state = State::Error;
				}
			case State::Error:
				break;
		}
	}

	State state = State::OK;
	uint32_t codepoint = 0;
};
}
