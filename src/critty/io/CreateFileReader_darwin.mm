#include "CreateFileReader.hpp"

#import <dispatch/dispatch.h>

namespace critty {
namespace io {

std::unique_ptr<Reader> CreateFileReader(
	const char* path,
	std::unique_ptr<Reader::Observer> observer
) {
	struct FileReader final: Reader {
		dispatch_queue_t queue =
			dispatch_queue_create("critty::io::Reader", DISPATCH_QUEUE_SERIAL);
		dispatch_io_t channel;

		const std::unique_ptr<Observer> observer;

		FileReader(
			const char* path,
			std::unique_ptr<Reader::Observer> observer
		) :
			channel{dispatch_io_create_with_path(
				DISPATCH_IO_STREAM, path, O_RDONLY, 0, queue, ^(int err){}
			)},
			observer{std::move(observer)}
		{
			dispatch_io_read(
				channel, 0, SIZE_MAX, queue,
				^(bool done, dispatch_data_t data, int error){
					if (!data)
						return;
				}
			);
		};

		~FileReader() = default;
		
	};

	return std::make_unique<FileReader>(path, std::move(observer));
}

}  // namespace io
}  // namespace critty
