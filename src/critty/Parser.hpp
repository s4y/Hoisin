#pragma once

#include <cstddef>
#include <functional>

namespace critty {

class Parser {
	public:
	std::function<void()> onRead;

	void FeedBytes(const void* buffer, size_t size);
};

}  // namespace critty
