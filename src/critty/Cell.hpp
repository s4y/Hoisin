#pragma once

#include <vector>

#include "critty/io/Reader.hpp"

namespace critty {

class Cell {
	std::vector<std::unique_ptr<io::Reader>> inputs;

	public:
	Cell() = default;
	Cell(Cell&&) = default;
	Cell(const Cell&) = delete;

	void AddInput(std::unique_ptr<io::Reader> reader) {
		inputs.push_back(std::move(reader));
		inputs.back()->read([&](const void* buf, size_t len){
			fprintf(stderr, "Read %zu bytes.\n", len);
		});
	}
};

}  // namespace critty
