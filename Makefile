CC = cc
CFLAGS += $(shell cat flags)

SOURCES = $(wildcard src/**.m)
DEPS = $(wildcard src/**.h)

critty: $(SOURCES) $(DEPS)
	$(CC) $(CFLAGS) -o $@ $(SOURCES)
