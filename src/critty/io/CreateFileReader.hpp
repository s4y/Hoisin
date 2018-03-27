#pragma once

#include "Reader.hpp"

namespace critty {
namespace io {

std::unique_ptr<Reader> CreateFileReader(
	const char* path,
	std::unique_ptr<Reader::Observer>
);

}  // namespace io
}  // namespace critty
