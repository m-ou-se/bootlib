.global boot, halt

.bss

		.skip 0x0004000 # 16 KiB stack
	stack:

.text

	multiboot_header: # this header contains some magic values to let the bootloader (grub/lilo/whatever) find our entrypoint
		.long 0x1BADB002
		.long 0x00000000
		.long 0xE4524FFE
		jmp boot


	# global descriptor table, see http://wiki.osdev.org/GDT
	gdt:
		.quad 0x0000000000000000   #  0 - unused 'null' section
		.quad 0x00CF9A000000FFFF   #  8 - code section (0x00000000 - 0xFFFFFFFF, executable)
		.quad 0x00CF92000000FFFF   # 16 - data section (0x00000000 - 0xFFFFFFFF, readable, writable)
	gdt_ptr: # pointer to the GDT
		.short (gdt_ptr - gdt) - 1 # the size of the GDT, minus one
		.long gdt                  # the location of the GDT

	init_gdt:
		lgdt gdt_ptr

		movw $16, %ax # load the right section (16 for the data section) ...
		movw %ax, %ds #  ... into DS,
		movw %ax, %es #  ... ES,
		movw %ax, %fs #  ... FS,
		movw %ax, %gs #  ... GS,
		movw %ax, %ss #  ... and SS. (these are all sections except CS, the code section)

		ljmp $8, $init_gdt_end # load the right section (8 for the code section) into CS

	init_gdt_end:
		ret


	boot:

		# Set up our environment, gdt, idt, etc.

		cli                     # turn off interrupts, we don't want to be interrupted while setting up our environment

		movb $0, %al            # \
		movl $bss_start, %edi   # |
		movl $bss_size, %ecx    # | Clear the .BSS section.
		cld                     # |
		rep stosb               # /

		movl $stack, %esp       # set up the stack

		pushl $0                # \ clear ...
		popf                    # /  ... all flags

		call init_gdt           # load the GDT
		call init_idt           # load the IDT
		call init_pic           # initialize the PICs

		sti                     # end of critical section, so interrupts can be enabled again

		# Everything is set up, now execute the user application
		call main

	halt:
		cli                     # turn off interrupts, we don't want to be awaken from death
		hlt                     # halt the CPU
		jmp halt                # die, again, if the CPU got out of the halt state (for example, by a NMI)

