CXX = c++
CXXFLAGS += $(shell cat flags)

SOURCES = $(wildcard src/**.cc)
DEPS = $(wildcard src/**.h)

critty: $(SOURCES) $(DEPS)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCES)
