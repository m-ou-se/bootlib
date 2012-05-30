# A simple example that uses bootlib.

.global main

.text
	main:
		# Set the timer frequency to 1000Hz
		pushl $1000
		call set_timer_frequency
		addl $4, %esp

		# Register the handle for the timer IRQ (IRQ0) and enable it.
		pushl $irq0
		pushl $0
		call set_irq_handler
		call enable_irq
		addl $8, %esp

		# Set up VGA stuff
		call color_text_mode
		call hide_cursor

		# Clear the screen
		movb $' ', %al
		movb $0x4E, %ah
		movl $25*80, %ecx
		movl $vga_memory, %edi
		cld
		rep stosw

		# Write some text
		movb $'T', vga_memory + 160*11+60
		movb $'i', vga_memory + 160*11+62
		movb $'m', vga_memory + 160*11+64
		movb $'e', vga_memory + 160*11+66
		movb $':', vga_memory + 160*11+68

		movb $'m', vga_memory + 160*12+84
		movb $'s', vga_memory + 160*12+86

		# Continiously show the time
	loop:
		movl time, %eax
		movl $vga_memory + 160*12+80, %edi
		movl $10, %ebx
	print_loop:
		movl $0, %edx
		divl %ebx
		addb $0x30, %dl
		movb %dl, (%edi)
		subl $2, %edi
		test %eax, %eax
		jnz print_loop
		jmp loop

	# Timer IRQ handler
	irq0:
		# increment the time and go on.
		incl time
		jmp end_of_irq0

.data
	time: .long 0

