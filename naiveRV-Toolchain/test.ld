OUTPUT_ARCH( "riscv" )
ENTRY( _start )

PROVIDE(__rom_size = 1K);
PROVIDE(__ram_size = 1K);
PROVIDE(__stack_size = 1K);

PROVIDE(__rom_start = 0x10000000);
PROVIDE(__ram_start = 0x20000000);
PROVIDE(__ram_end = __ram_start + __ram_size);
PROVIDE(__stack_start = __ram_end - __stack_size - 8);
PROVIDE(__stack_end = __ram_end - 8);

MEMORY
{

	rom (rxa) : ORIGIN = __rom_start, LENGTH = __rom_size
	ram (wxa) : ORIGIN = __ram_start, LENGTH = __ram_size
/*	rest (rxa) : ORIGIN = 0x30000000, LENGTH = 1M */
}


SECTIONS
{
/*
	.init :
	{
		_text = .;
		KEEP (*(SORT_NONE(.init)))
	} >rom AT>rom
*/	
	.text :
	{
		_text = .;
		*(.text)
		*(.text.unlikely .text.unlikely.*)
		*(.text.startup .text.startup.*)
/*		*(.text) */
		*(.text.*)
		*(.gnu.linkonce.t.*)
	} >rom AT>rom
	
	.init :
	{
		KEEP (*(SORT_NONE(.init)))
	} >rom AT>rom
	
	.fini :
	{
		KEEP (*(SORT_NONE(.fini)))
		_etext = .;
	} >rom AT>rom

	.rodata.align :
	{
		. = ALIGN(4);
		_rodata = .;
	} >rom AT>rom

	.rodata.start :
	{
		_rodata_lma = LOADADDR(.rodata.start);
	} >rom AT>rom

	.rodata :
	{
		*(.rdata)
		*(.rodata .rodata.*)
		*(.gnu.linkonce.r.*)

		. = ALIGN(4);
		_erodata = .;
	} >rom AT>rom

	.data.align :
	{
		. = ALIGN(4);
		_data = .;
	} >ram AT>rom

	.data.start :
	{
		_data_lma = LOADADDR(.data.start);
	} >ram AT>rom

	.data :
	{
		PROVIDE( __global_pointer$ = . + 0x800 );
		*(.data .data.*)
		*(.gnu.linkonce.d.*)
		. = ALIGN(8);
		*(.sdata .sdata.*)
		*(.sdata2 .sdata2.*)
		*(.gnu.linkonce.s.*)
		. = ALIGN(8);
		*(.srodata.cst16)
		*(.srodata.cst8)
		*(.srodata.cst4)
		*(.srodata.cst2)
		*(.srodata .srodata.*)

		. = ALIGN(4);
		_edata = .;
	} >ram AT>rom

	.bss.align :
	{
		. = ALIGN(4);
		_bss = .;
	} >ram AT>rom

	.bss.start :
	{
		_bss_lma = LOADADDR(.bss.start);
	} >ram AT>rom

	.bss :
	{
		*(.sbss*)
		*(.gnu.linkonce.sb.*)
		*(.bss .bss.*)
		*(.gnu.linkonce.b.*)
		*(COMMON)

		. = ALIGN(4);
		_ebss = .;
	} >ram AT>rom

	. = ALIGN(8);
	_end = .;
	PROVIDE(__heap_start = .);
	. = __stack_start;
	PROVIDE(__heap_end = .);
	.stack :
	{
		. += __stack_size;
		_stack_top = .;
	} >ram AT>ram

/*	
	.mopup :
	{
	*(.*)
	} >rest AT>rest
*/
}
