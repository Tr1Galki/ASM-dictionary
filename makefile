ASM=nasm
ASMFLAGS=-f elf64
.PHONY: clean

%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

main.o: main.asm words.inc lib.inc
	$(ASM) $(ASMFLAGS) -o $@ $<

main: main.o dict.o lib.o
	ld -o $@ $^

clean:
	rm *.o main