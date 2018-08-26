#pragma once

#include "critty/Cell.hpp"

#include <set>

namespace critty {

struct ObservableBase {
	ObservableBase() {}
	ObservableBase(const ObservableBase&) = delete;

	struct Handle {
		Handle() = default;
		Handle(const Handle&) = delete;
		virtual ~Handle() {}
	};
};

template <typename T>
class ObservableImpl {
	class HandleImpl: public ObservableBase::Handle {
		friend class ObservableImpl;

		ObservableImpl* to_ = nullptr;
		std::function<void(T)> cb_;

		public:
		HandleImpl(ObservableImpl* to, std::function<void(T)> cb) : to_(to), cb_(cb) {}
		~HandleImpl() override {
			if (!to_)
				return;
			to_->handles_.erase(this);
		}
	};

	std::set<HandleImpl*> handles_;

	public:
	~ObservableImpl() {
		for (auto* handle : handles_)
			handle->to_ = nullptr;
	}

	std::unique_ptr<ObservableBase::Handle> addObserver(std::function<void(T)> cb) {
		auto handle = std::make_unique<HandleImpl>(this, std::move(cb));
		handles_.insert(handle.get());
		return handle;
	}

	void emit(const T& e) {
		for (auto* handle_ : handles_)
			handle_->cb_(e);
	}
};

template <typename ...T>
class Observable :
	public ObservableBase,
	public ObservableImpl<T>...
{
	protected:
		using ObservableImpl<T>::emit...;
	public:
		using ObservableImpl<T>::addObserver...;
};

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
