#include "FileReaderPipe.hpp"

#import <dispatch/dispatch.h>

namespace critty {

FileReaderPipe FileReaderPipe::Create(const char* path) {
	return FileReaderPipe{Guts<FileReaderPipe>{}};
}

FileReaderPipe::FileReaderPipe(Guts<FileReaderPipe>&& guts) : guts_{std::move(guts)} {
}

void FileReaderPipe::resume() {
}

void FileReaderPipe::pause() {
}

void FileReaderPipe::close() {
}

}  // namespace critty
