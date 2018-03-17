#pragma once

#include "Guts.hpp"
#include "Pipe.hpp"

#ifdef DARWIN

#import <dispatch/dispatch.h>

struct FileReaderPipe;
template <> struct critty::Guts<FileReaderPipe>{
	dispatch_queue_t queue;
	dispatch_io_t channel;
};
#endif

namespace critty {

struct FileReaderPipe final: Pipe {
	static FileReaderPipe Create(const char* path);

	void resume() override;
	void pause() override;
	void close() override;

	private:
	Guts<FileReaderPipe> guts_;
	FileReaderPipe(Guts<FileReaderPipe>&&);
};

}  // namespace critty
