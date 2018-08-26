CC = cc
CFLAGS := \
	-Wall \
	-Wpedantic \
	-Werror \
	-std=c++17 \
	-Os \
	-Isrc \
	-fobjc-arc \
	-mmacosx-version-min=10.13 \
	-g \

LDFLAGS = \
	-framework AppKit \
	-framework CoreGraphics \
	-framework QuartzCore \
	-lc++ \
	-flto \

SOURCES = $(shell find src -type f -name '*.mm' -or -name '*.cpp')
OBJECTS = $(patsubst src/%.cpp, build/%.o, $(SOURCES))
DEPS = $(shell find src -type f -name '*.hpp') Makefile flags.compile.txt flags.link.txt

build/%.o: src/%.m $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

build/%.o: src/%.mm $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

build/%.o: src/%.cpp $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

build/Critty.app: build/Critty.app/Contents/MacOS/Critty build/Critty.app/Contents/Info.plist
	touch "$@"

build/Critty.app/Contents/MacOS/Critty: $(OBJECTS) $(DEPS)
	mkdir -p $(shell dirname $@)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS)

build/Critty.app/Contents/Info.plist: src/cocoa/Info.plist
	mkdir -p $(shell dirname $@)
	cp "$<" "$@"
