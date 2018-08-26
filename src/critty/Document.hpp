#pragma once

#include "critty/Cell.hpp"

namespace critty {

class Document {
	std::vector<critty::Cell> cells;

	public:
	Document() = default;
	Document(const Document&) = delete;

	void AddCell(Cell cell) {
		cells.push_back(std::move(cell));
	}
};

}  // namespace critty
