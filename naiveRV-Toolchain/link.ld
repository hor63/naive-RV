 OUTPUT_ARCH( "riscv" )
 ENTRY( _start )
 SECTIONS
 {
 /* text: test code section */
 . = 0x10000;
 .text :
 {
 *(.text)
 *(.*text*)
 _etext = .;
 }
 /* data: Initialized data segment */
 . = 0x20000;
 __global_pointer$ = . + 0x800;
 _data = .;
 .data :
 {
 *(.data)
 *(.*data*)
 _edata = .;
 }
 .bss :
 {
 *(.bss)
 *(.*bss*)
 }

 /* End of uninitalized data segement */
 _end = .;
 
 . = 0x30000;
 .others :
 {
 *(.*)
 }
 }
