# [Minimalistic interrupt (IDT, PIC, IRQ) library]

.global init_idt, init_pic
.global set_interrupt_handler, clear_interrupt_handler, set_irq_handler, clear_irq_handler
.global enable_irq, disable_irq
.global end_of_irq0, end_of_irq1, end_of_irq2, end_of_irq3, end_of_irq4, end_of_irq5, end_of_irq6, end_of_irq7
.global end_of_irq8, end_of_irq9, end_of_irqA, end_of_irqB, end_of_irqC, end_of_irqD, end_of_irqE, end_of_irqF

.bss

	idt:
		.skip 0x800 # 256 entries * 8 bytes per entry

.text

	idt_ptr: # pointer to the IDT
		.short 0x800 - 1 # the size of the IDT, minus one
		.long idt        # the location of the IDT

	# Initialize the Interrupt Descriptor Table.
	# Note: see http://wiki.osdev.org/IDT
	init_idt:
		lidt idt_ptr
		ret

	# Initialize the Programmable Interrupt Controllers.
	# IRQs are mapped to interrupts 0x20..0x2F.
	# Note: See http://wiki.osdev.org/PIC
	init_pic:
		movb $0x11, %al # init command, ICW4 present
		outb %al, $0x20 # PIC1 command port
		outb %al, $0xA0 # PIC2 command port

		movb $0x20, %al # interrupt offset
		outb %al, $0x21 # PIC1 data port
		movb $0x28, %al # interrupt offset
		outb %al, $0xA1 # PIC2 data port

		movb $0x04, %al # IR4 is connected to a slave (PIC2)
		outb %al, $0x21 # PIC1 data port
		movb $0x02, %al # slave ID 2
		outb %al, $0xA1 # PIC2 data port

		movb $0x01, %al # 8086/88 mode
		outb %al, $0x21 # PIC1 data port
		movb $0x01, %al # 8086/88 mode
		outb %al, $0xA1 # PIC2 data port

		movb $0xFF, %al # disable all IRQs
		outb %al, $0x21 # PIC1 data port
		movb $0xFF, %al # disable all IRQs
		outb %al, $0xA1 # PIC2 data port

		pushl $spurious_interrupt_handler
		pushl $7
		call set_irq_handler
		addl $4, %esp
		pushl $15
		call set_irq_handler
		addl $8, %esp

		ret

	spurious_interrupt_handler:
		iret


	# Create/update an entry in the IDT for an interrupt specified by its index.
	# Note that an interrupt handler must end with iret, and shoud leave all registers in tact.
	set_interrupt_handler: # Parameters: interrupt_index, handler_address
		cli                          # disable interrupts before modifying the IDT
		movl 4(%esp), %ecx           # the interrupt index
		movw 8(%esp), %ax            # \ store the low word of the handler address ...
		movw %ax, 0+idt(,%ecx,8)     # /  ... in the right place of the IDT entry
		movw 10(%esp), %ax           # \ store the high word of the handler address ...
		movw %ax, 6+idt(,%ecx,8)     # /  ... in the right place of the IDT entry
		movw %cs, %ax                # \ store the code segment selector ...
		movw %ax, 2+idt(,%ecx,8)     # /  ... in the right place of the IDT entry
		movw $0x8E00, 4+idt(,%ecx,8) # store the attributes (0x8E00: 32-bit interrupt gate) in the IDT entry
		sti                          # we're done, enable interrupts again
		ret


	# Remove an entry in the IDT for an interrupt specified by its index.
	clear_interrupt_handler: # Parameters: interrupt_index
		movl 4(%esp), %ecx         # the interrupt index
		movw $0, 4+idt(,%ecx,8)    # store the attributes (0: not present) in the IDT entry
		ret


	# Create/update an entry in the IDT for an irq specified by its index.
	# Note that a irq handler must acknowledge the IRQ after processing it.
	# This can be done by jumping to end_of_irqN, see below.
	set_irq_handler: # Parameters: irq_index, handler_address
		movl 4(%esp), %ecx         # the IRQ index
		movl 8(%esp), %esi         # the handler address
		addl $0x20, %ecx           # IRQs are mapped to interrupts 0x20..0x2F
		pushl %esi                 # /  -> the handler address
		pushl %ecx                 # |  -> the interrupt index
		call set_interrupt_handler # \ set the interrupt handler
		addl $8, %esp              # (cleanup the stack)
		ret


	# Remove an entry in the IDT for an irq specified by its index.
	clear_irq_handler: # Parametrs: irq_index
		movl 4(%esp), %ecx           # the IRQ index
		addl $0x20, %ecx             # IRQs are mapped to interrupts 0x20..0x2F
		pushl %ecx                   # /  -> the interrupt index
		call clear_interrupt_handler # \ clear the interrupt handler
		addl $4, %esp                # (cleanup the stack)
		ret


	# Disable a specific irq.
	# Note: See http://wiki.osdev.org/PIC
	disable_irq: # Parameters: irq_index
		movw $0x21, %dx   # PIC1 data port
		movb 4(%esp), %al # IRQ index
		shlb $4, %al      # \ if the IRQ index ...
		andb $0x80, %al   # |  ... is higher than 8 ...
		addb %al, %dl     # /  ... use 0xA1 (PIC2) instead of 0x21 (PIC1)
		movb 4(%esp), %cl # \ IRQ index ...
		andb $0b0111, %cl # /  ... modulo 8
		movb $1, %bl      # \ create the right mask for this IRQ index
		shlb %cl, %bl     # / (set turn that bit, clear the rest)
		inb %dx, %al      # \ set the selected bit ...
		orb %bl, %al      # |  ... in the data register ...
		outb %al, %dx     # /  ... of the right PIC
		ret


	# Enable a specific irq.
	# Note: See http://wiki.osdev.org/PIC
	enable_irq: # Parameters: irq_index
		movw $0x21, %dx   # PIC1 data port
		movb 4(%esp), %al # IRQ index
		shlb $4, %al      # \ if the IRQ index ...
		andb $0x80, %al   # |  ... is higher than 8 ...
		addb %al, %dl     # /  ... use 0xA1 (PIC2) instead of 0x21 (PIC1)
		movb 4(%esp), %cl # \ IRQ index ...
		andb $0b0111, %cl # /  ... modulo 8
		movb $1, %bl      # \ create the right mask for this IRQ index
		shlb %cl, %bl     # / (set turn that bit, clear the rest)
		inb %dx, %al      # \ clear the selected bit ...
		notb %bl          # |  ... in the ...
		andb %bl, %al     # |  ... data register ...
		outb %al, %dx     # /  ... of the right PIC
		ret


	# Acknowledge a specific irq.
	# Jump to one of these instead of returning at the end of your irq handler.
	# Note: See http://wiki.osdev.org/PIC
	end_of_irq0:
	end_of_irq1:
	end_of_irq2:
	end_of_irq3:
	end_of_irq4:
	end_of_irq5:
	end_of_irq6:
	end_of_irq7:
		# IRQs 0..7 are controlled by PIC1
		pushl %eax
		movb $0x20, %al # end of interrupt command
		outb %al, $0x20 # PIC1 command port
		popl %eax
		iret
	end_of_irq8:
	end_of_irq9:
	end_of_irqA:
	end_of_irqB:
	end_of_irqC:
	end_of_irqD:
	end_of_irqE:
	end_of_irqF:
		# IRQs 8..F are controlled by PIC2 via PIC1
		pushl %eax
		movb $0x20, %al # end of interrupt command
		outb %al, $0xA0 # PIC2 command port
		outb %al, $0x20 # PIC1 command port
		popl %eax
		iret

