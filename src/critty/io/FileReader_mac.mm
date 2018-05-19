#include "FileReader.hpp"

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

namespace critty {
namespace io {

std::unique_ptr<Reader> ReaderForFile(const char* path) {
	struct FileReader: Reader {
		dispatch_queue_t queue;
		dispatch_io_t channel;
		FileReader(dispatch_queue_t queue, dispatch_io_t channel) :
			queue{queue}, channel{channel} {}

		void read(std::function<void(const void* buf, size_t len)> cb) override {
			dispatch_io_read(channel, 0, SIZE_MAX, queue,
				^(bool done, dispatch_data_t data, int error){
					if (!data)
						return cb(nullptr, 0);
					dispatch_data_apply(data, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
						cb(buffer, size);
						return YES;
					});
				}
			);
		}
	};
	auto queue = dispatch_queue_create("critty::io::Reader", DISPATCH_QUEUE_SERIAL);
	if (auto channel = dispatch_io_create_with_path(
		DISPATCH_IO_STREAM, path, O_RDONLY, 0, queue, ^(int err){
			NSLog(@"FileReader failed: %d", err);
		}
	))
		return std::make_unique<FileReader>(queue, channel);
	return nullptr;
}

}  // namespace io
}  // namespace critty