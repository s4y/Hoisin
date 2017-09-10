CC = cc
CFLAGS += $(shell cat flags.compile.txt)
LINKFLAGS = $(shell cat flags.link.txt)

OBJECTS = $(patsubst src/%.m, out/%.o, $(shell find src -type f -name '*.m'))
DEPS = $(shell find src -type f -name '*.h') Makefile flags.compile.txt flags.link.txt

out/%.o: src/%.m $(DEPS)
	@mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

critty: $(OBJECTS) $(DEPS)
	$(CC) $(CFLAGS) $(LINKFLAGS) -o $@ $(OBJECTS)
