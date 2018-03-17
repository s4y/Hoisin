#pragma once

#include <memory>

namespace critty {
namespace io {

struct Reader {
	struct Observer {
		virtual ~Observer() {}
		virtual void didRead(void* buf, size_t len) = 0;
	};

	std::unique_ptr<Observer> observer;

	virtual void resume() = 0;
	virtual void pause() = 0;
	virtual void close() = 0;
};

}  // namespace io
}  // namespace critty
