#pragma once

/*
 * // - Yields bytes from the world.
 * struct TaskPipe {
 * };
 *
 * // - Accepts bytes.
 * // - Yields Unicode text and VT commands.
 * // - Maintains state of partial characters and commands.
 * struct TerminalParser {
 * };
 *
 * // - Accepts text and commands.
 * // - Yields terminal events (chars changed, line added, cursor moved…).
 * // - Maintains state of terminal (size, scrollback, cursor, text attributes…)
 * struct TerminalWindow {
 *
 *   // A line of scrollback.
 *   struct Line {
 *   };
 *
 * };
 *
 */

namespace stream {

template <typename T>
struct Sink;

template <typename T>
struct Source {
	template <typename Input>
	Input&& operator<<(Input&& target) {
	}
};

template <typename T>
struct Sink {
	template <typename Next>
	Next& operator<<(Next& target) {
	}
};

}
