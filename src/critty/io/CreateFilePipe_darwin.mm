#include "CreateFilePipe.hpp"

#import <dispatch/dispatch.h>

namespace critty {
namespace io {

namespace {

struct FileReaderPipe: Pipe {
	dispatch_queue_t queue;
	dispatch_io_t channel;
};

}  // namespace

std::unique_ptr<Pipe> CreateFilePipe(const char* path) {
	return nullptr;
}

}  // namespace io
}  // namespace critty
