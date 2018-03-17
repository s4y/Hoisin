#include "CreateFileReader.hpp"

#import <dispatch/dispatch.h>

namespace critty {
namespace io {

namespace {

struct FileReaderReader: Reader {
	dispatch_queue_t queue;
	dispatch_io_t channel;
};

}  // namespace

std::unique_ptr<Reader> CreateFileReader(const char* path) {
	return nullptr;
}

}  // namespace io
}  // namespace critty
