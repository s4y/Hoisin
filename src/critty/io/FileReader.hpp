#pragma once

#include "Reader.hpp"

namespace critty {
namespace io {

std::unique_ptr<Reader> ReaderForFile(const char* path);

}  // namespace io
}  // namespace critty
