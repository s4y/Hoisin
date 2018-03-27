#pragma once

#include <memory>

namespace critty {
namespace io {

struct Reader {
	struct Observer {
		virtual ~Observer() {}
		virtual void didRead(void* buf, size_t len) = 0;
	};
	virtual ~Reader() = 0;
};

}  // namespace io
}  // namespace critty
