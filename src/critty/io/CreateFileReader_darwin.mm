#include "CreateFileReader.hpp"

#import <dispatch/dispatch.h>

namespace critty {
namespace io {

std::unique_ptr<Reader> CreateFileReader(const char* path) {
	struct FileReaderReader: Reader {
		dispatch_queue_t queue;
		dispatch_io_t channel;
	};

	return nullptr;
}

}  // namespace io
}  // namespace critty
