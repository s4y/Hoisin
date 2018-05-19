CC = cc
CFLAGS := \
	-Wall \
	-Wpedantic \
	-Werror \
	-std=c++14 \
	-Os \
	-Isrc \
	-fobjc-arc \
	-g \

LDFLAGS = \
	-framework AppKit \
	-framework CoreGraphics \
	-framework QuartzCore \
	-lc++ \
	-flto \

SOURCES = $(shell find src -type f -name '*.mm' -or -name '*.cpp')
OBJECTS = $(patsubst src/%.cpp, build/%.o, $(SOURCES))
DEPS = $(shell find src -type f -name '*.h') Makefile flags.compile.txt flags.link.txt

build/%.o: src/%.m $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

build/%.o: src/%.mm $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

critty: $(OBJECTS) $(DEPS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS)
