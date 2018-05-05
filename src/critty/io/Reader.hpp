#pragma once

#include <functional>

namespace critty {
namespace io {

struct Reader {
	virtual ~Reader() = default;
	virtual void read(std::function<void(const void* buf, size_t len)>) = 0;
};

}  // namespace io
}  // namespace critty
