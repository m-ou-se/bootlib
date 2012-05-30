
.global set_timer_frequency, set_timer_rate

.text

	# Set the frequency of the timer that fires IRQ0.
	# Note: See http://wiki.osdev.org/PIT
	set_timer_frequency: # Parameters: frequency in Hz
		movl $0, %edx
		movl $1193046, %eax
		divl 4(%esp)
		pushl %eax
		call set_timer_rate
		addl $4, %esp
		ret

	# Set the rate of the timer that fires IRQ0.
	# Note: See http://wiki.osdev.org/PIT
	set_timer_rate: # Parameters: timer_rate
		movb $0x34, %al # channel 0, rate generator mode -> ...
		outb %al, $0x43 #  ... PIT Mode/Command port
		movl 4(%esp), %eax
		outb %al, $0x40 # low byte -> PIT channel 0 data port
		movb %ah, %al   # high byte -> ...
		outb %al, $0x40 #  ... PIT channel 0 data port
		ret


