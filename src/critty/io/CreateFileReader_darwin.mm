#include "CreateFileReader.hpp"

#import <dispatch/dispatch.h>

namespace critty {
namespace io {

std::unique_ptr<Reader> CreateFileReader(const char* path) {
	struct FileReader final: Reader {
		dispatch_queue_t queue;
		dispatch_io_t channel;

		FileReader(const char* path) :
			channel{dispatch_io_create_with_path(
				DISPATCH_IO_STREAM, path, O_RDONLY, 0, queue, ^(int err){}
			)}
		{}

		void resume() {
			dispatch_io_read(
				channel, 0, SIZE_MAX, queue,
				^(bool done, dispatch_data_t data, int error){
					if (!data)
						return;
				}
			);
		}
		void pause() {}
		void close() {}
		
	};

	return std::make_unique<FileReader>(path);
}

}  // namespace io
}  // namespace critty
