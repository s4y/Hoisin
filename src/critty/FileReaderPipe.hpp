#pragma once

#include "Pipe.hpp"

namespace critty {

class FileReaderPipe final: Pipe {
	static FileReaderPipe Create(const char* path);

	FileReaderPipe(FileReaderPipe&&) = default;

	void resume() override;
	void pause() override;
	void close() override;

	private:
	struct guts;
	FileReaderPipe(guts);
};

}  // namespace critty
