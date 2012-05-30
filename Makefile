
boot.elf: $(wildcard bootlib/*.s *.s)
	gcc -g -nostdlib -m32 -Wl,-Tbootlib/boot.ld -o $@ $^

boot.img: boot.elf
	objcopy -S $< $@

floppy.img: bootlib/floppy_template.img boot.img
	cat $^ > $@

.PHONY: test
test: floppy.img
	bochs -f bootlib/bochs.bxrc

.PHONY: clean
clean:
	rm -f boot.elf boot.img floppy.img

