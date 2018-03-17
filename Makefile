CC = cc
CFLAGS += $(shell cat flags.compile.txt)
LINKFLAGS = $(shell cat flags.link.txt)

OBJECTS += $(patsubst src/%.mm, build/%.o, $(shell find src -type f -name '*.mm'))
OBJECTS += $(patsubst src/%.cpp, build/%.o, $(shell find src -type f -name '*.cpp'))
DEPS = $(shell find src -type f -name '*.h') Makefile flags.compile.txt flags.link.txt

build/%.o: src/%.m $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

build/%.o: src/%.mm $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

critty: $(OBJECTS) $(DEPS)
	$(CC) $(CFLAGS) $(LINKFLAGS) -o $@ $(OBJECTS)
