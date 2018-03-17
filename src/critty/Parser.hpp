#pragma once

#include <cstddef>

template <typename Delegate>
struct Parser {
	void Feed(const void* buffer, size_t size);
};
