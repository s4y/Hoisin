CC = cc
CFLAGS += $(shell cat flags)

SOURCES = $(shell find src -type f -name '*.m')
DEPS = $(shell find src -type f -name '*.h') Makefile flags

critty: $(SOURCES) $(DEPS)
	echo Sources: $(SOURCES)
	echo Deps: $(DEPS)
	$(CC) $(CFLAGS) -o $@ $(SOURCES)
