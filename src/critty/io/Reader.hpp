#pragma once

#include <memory>

namespace critty {
namespace io {

struct Reader {
	struct Observer {
		virtual ~Observer() {}
		virtual void didRead(const void* buf, size_t len) = 0;
	};

	Reader() = default;
	Reader(const Reader&) = delete;
	virtual ~Reader() = default;
};

}  // namespace io
}  // namespace critty
