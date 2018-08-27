#pragma once

#include "critty/Cell.hpp"
#include "critty/Observable.hpp"

namespace critty {

struct DocumentEvents {
	struct CellAddedEvent{
		critty::Cell& cell;
	};
	struct CellRemovedEvent{
		critty::Cell& cell;
	};

	typedef Observable<CellAddedEvent, CellRemovedEvent> Observable;
};

class Document :
	public DocumentEvents,
	public DocumentEvents::Observable
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
