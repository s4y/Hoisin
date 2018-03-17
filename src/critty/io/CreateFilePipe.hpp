#pragma once

#include "Pipe.hpp"

namespace critty {
namespace io {

std::unique_ptr<Pipe> CreateFilePipe(const char* path);

}  // namespace io
}  // namespace critty
