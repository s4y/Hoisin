#pragma once

#include "critty/Cell.hpp"
#include "critty/Observer.hpp"

namespace critty {

struct DocumentEvents {
	struct CellAddedEvent{
		critty::Cell& cell;
	};
	struct CellRemovedEvent{
		critty::Cell& cell;
	};
};

class Document :
	public DocumentEvents,
	public Observable<DocumentEvents::CellAddedEvent, DocumentEvents::CellRemovedEvent>
{
	std::vector<critty::Cell> cells;

	public:
	Document() = default;
	Document(const Document&) = delete;

	void AddCell(Cell cell) {
		cells.push_back(std::move(cell));
		emit(CellAddedEvent{cell});
	}
};

}  // namespace critty
