ASM  = nasm
SRC  = $(wildcard games/*.asm)
PROG = $(subst games/,bin/,$(basename $(SRC)))
ARG  = -f bin

all: $(PROG)

$(PROG): bin/% : games/%.asm
	$(ASM) $(ARG) -o $@.bin $< -w-number-overflow

clean:
	rm bin/*
