#pragma once

#include "Reader.hpp"

namespace critty {
namespace io {

std::unique_ptr<Reader> ReaderForFile(int fd);

}  // namespace io
}  // namespace critty
