ENTRY (boot)

SECTIONS{
	. = 0x00100000;

	.text : {
		*(.text)
	}

	.rodata ALIGN (0x1000) : {
		*(.rodata)
	}

	.data ALIGN (0x1000) : {
		*(.data)
	}

	.bss : {
		bss_start = ABSOLUTE(.);
		*(.bss)
		bss_size = ABSOLUTE(.) - bss_start;
	}
}
