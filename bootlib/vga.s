# [Minimalistic VGA text mode driver]

# See
#  - http://wiki.osdev.org/VGA_Hardware
#  - http://corbatech.sourceforge.net/appleII/SecondSightVGARegisters.pdf


.global vga_memory, color_text_mode, hide_cursor, vsync

.equ vga_memory, 0xB8000

.text

	# Sets a lot of VGA registers to get to 16 color 80*25 text mode
	color_text_mode:

		# Set I/OAS to 1 in Miscellaneous Output Register
		movw $0x3CC, %dx       # read Miscellaneous Output Register ...
		inb %dx, %al           #  ... into AL
		andb $0b11110011, %al  # select clock 00 (25 MHz)
		orb  $0b00000011, %al  # set Ram Enable and I/OAS
		movw $0x3C2, %dx       # write the new value back
		outb %al, %dx          # "

		# CRT Vertical Retrace End
		movb $0x11, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		inb %dx, %al
		andb $0b01110000, %al # unset bit 7 and 0 to 3
		outb %al, %dx         # write the new value

		# CRT Mode Control Register
		movb $0x17, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movw $0x3D5, %dx      # read current value ...
		inb %dx, %al          #  ... into AL
		andb $0b01111111, %al # unset Sync Enable bit
		outb %al, %dx         # write the new value back

		# CRT Horizontal Total Register
		movb $0x00, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $77, %al         # horizontal total
		outb %al, %dx         # write the new value

		# CRT End Horizontal Display
		movb $0x01, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $80, %al         # last character clock to output?
		outb %al, %dx         # write the new value

		# CRT Start Horizontal Blanking
		movb $0x02, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $80, %al         # last character clock to output?
		outb %al, %dx         # write the new value

		# CRT End Horizontal Blanking
		movb $0x03, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b10000001, %al # first character clock to output?
		outb %al, %dx         # write the new value

		# CRT Start Horizontal Retrace
		movb $0x04, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $81, %al         # first character clock to not output?
		outb %al, %dx         # write the new value

		# CRT End Horizontal Retrace
		movb $0x05, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b00000000, %al # retrace all the way, right?
		outb %al, %dx         # write the new value

		# CRT Vertical Total
		movb $0x06, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b10010001, %al # last scanline, lower 8 bits
		outb %al, %dx         # write the new value

		# CRT Overflow
		movb $0x07, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b00001111, %al # overflows
		outb %al, %dx         # write the new value

		# CRT Preset Row Scan Register
		movb $0x08, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0, %al          # no panning and no preset row
		outb %al, %dx         # write the new value

		# CRT Maximum Scan Line
		movb $0x09, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $15, %al         # maximum scan line, all the rest 0
		outb %al, %dx         # write the new value

		# CRT Cursor Start
		movb $0x0A, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b00100000, %al # no cursor >:[
		outb %al, %dx         # write the new value

		# CRT Vertical Retrace Start
		movb $0x10, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b10010010, %al # lower 8 bits
		outb %al, %dx         # write the new value

		# CRT Vertical Display End
		movb $0x12, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $0b10010001, %al # lower 8 bits
		outb %al, %dx         # write the new value

		# CRT Start Vertical Blanking
		movb $0x15, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		inb %dx, %al
		andb $0b10010001, %al # lower 8 bits
		outb %al, %dx         # write the new value

		# CRT End Vertical Blanking
		movb $0x15, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movb $1, %al          # first scanline not to blank
		outb %al, %dx         # write the new value

		# select text mode
		movw $0x3DA, %dx
		inb %dx, %al

		movb $0x30, %al
		movw $0x3C0, %dx
		outb %al, %dx

		movb $0x00, %al
		outb %al, %dx

		# set sequencer register index to 0x01: Clocking Mode Register
		movb $0x01, %al
		movw $0x3C4, %dx
		outb %al, %dx
		# read current Clocking Mode Register
		movw $0x3C5, %dx
		inb %dx, %al
		# set 9/8 Dot Mode bit to 1 (8 pixels wide characters)
		orb $0b00000001, %al
		outb %al, %dx


		# set sequencer register index to 0x03: Character Map Select Register
		movb $0x03, %al      # sequencer register index
		movw $0x3C4, %dx     # sequencer address register port
		outb %al, %dx        # output it
		# set font A and B to 000 (plane 2 0x0000 - 0x1FFF)
		movb $0, %al            # set font bits to 0
		movw $0x3C5, %dx        # sequencer data register port
		outb %al, %dx           # output it

		# Sequencer Memory Mode Register
		movb $0x04, %al      # sequencer register index
		movw $0x3C4, %dx     # sequencer address register port
		outb %al, %dx        # output it
		movb $0b0000, %al       #
		movw $0x3C5, %dx        # sequencer data register port
		outb %al, %dx           # output it


		# Set/Reset Register
		movb $0x00, %al    # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0xFF, %al    # enable all bits
		movw $0x3CF, %dx
		outb %al, %dx

		# Enable Set/Reset Register
		movb $0x01, %al    # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0x00, %al    # disable all bits
		movw $0x3CF, %dx
		outb %al, %dx

		# Data Rotate Register
		movb $0x03, %al    # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0x00, %al    # disable all bits (don't touch mah data)
		movw $0x3CF, %dx
		outb %al, %dx

		# Graphics Mode Register
		movb $0x05, %al        # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0x10, %al
		movw $0x3CF, %dx
		outb %al, %dx

		# Miscellaneous Graphics Register
		movb $0x06, %al        # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0b1110, %al
		movw $0x3CF, %dx
		outb %al, %dx

		# Bit Mask Register
		movb $0x08, %al        # select correct graph register
		movw $0x3CE, %dx
		outb %al, %dx
		movb $0xFF, %al        # set all bits to 1
		movw $0x3CF, %dx
		outb %al, %dx

		# CRT Mode Control Register
		movb $0x17, %al       # Select CRT register
		movw $0x3D4, %dx      # "
		outb %al, %dx         # "
		movw $0x3D5, %dx      # read current value ...
		inb %dx, %al          #  ... into AL
		orb $0b10000000, %al  # set Sync Enable bit
		outb %al, %dx         # write the new value back

		ret


	# Hide the text mode cursor
	hide_cursor:
		movb $0x0A, %al
		movw $0x3D4, %dx
		outb %al, %dx

		movb $0x10, %al
		movw $0x3D5, %dx
		outb %al, %dx

		ret

	# Wait for vertical retrace to end
	vsync:
		movw $0x3DA, %dx                 # move port address of VGA status register to DX
	vsync_1:
		inb %dx, %al                     # read the current VGA status register
		test $0b00001000, %al            # check bit 3 ...
		jnz vsync_1                      #  ... and loop until it's 0
		# Wait for vertical retrace to start
	vsync_2:
		inb %dx, %al                     # read the current VGA status register
		test $0b00001000, %al            # check bit 3 ...
		jz vsync_2                       #  ... and loop until it's 1
		ret

