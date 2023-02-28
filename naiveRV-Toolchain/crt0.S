/* Copyright (c) 2017  SiFive Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

#include "newlib.h"

#=========================================================================
# crt0.S : Entry point for RISC-V user programs
#=========================================================================

  .text
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax
#1:auipc gp, %pcrel_hi(__global_pointer$)
#  addi  gp, gp, %pcrel_lo(1b)
  la gp,__global_pointer$
.option pop

  # Setup the stack pointer
  la sp, _stack_top

  # when .data is stored in the ROM/Flash the location is marked by _data_lma
  # Then _data_lma is not 0, and the initial data is copied from
  # _data_lma to _data below.
  # In case that initialized data is stored in .data from the start
  # the week definition here takes effect, and the copy loop below is by-passed.
  .weak _data_lma
  
  # Load data section
  la t0, _data_lma
  la t1, _data
  beq t0, t1, 2f
  beqz t0, 2f
  la t2, _edata
  bgeu t1, t2, 2f
1:
  lw t3, 0(t0)
  sw t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  bltu t1, t2, 1b
2:

  # Clear the bss segment
  la      a0, _edata
  la      a2, _end
  sub     a2, a2, a0
  li      a1, 0
  call    memset
#ifdef _LITE_EXIT
  # Make reference to atexit weak to avoid unconditionally pulling in
  # support code.  Refer to comments in __atexit.c for more details.
  .weak   atexit
  la      a0, atexit
  beqz    a0, .Lweak_atexit
  .weak   __libc_fini_array
#endif

  la      a0, __libc_fini_array   # Register global termination functions
  call    atexit                  #  to be called upon exit
#ifdef _LITE_EXIT
.Lweak_atexit:
#endif
  call    __libc_init_array       # Run global initialization functions

  lw      a0, 0(sp)                  # a0 = argc
  addi    a1, sp, __SIZEOF_POINTER__ # a1 = argv
  li      a2, 0                      # a2 = envp = NULL
  call    main
  tail    exit
  .size  _start, .-_start
