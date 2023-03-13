
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use std.textio.all;

package pkg_cpu_global is

    --! \brief Logging with TEXTIO only for simulators.
    --!
    --! For synthesis the flag must be off since TEXTIO is not syntheziable.
    constant c_enable_trace_glob: boolean := true;
    --! \brief The logger text file.
    --!
    --! This one must *never* be used when \ref c_enable_trace_glob is false.
    --! Otherwise you will not be able to synthesize the whole design.
    file f_logger: text;

    --! \brief The CPU register width. This determines whether it is a 32-bit or 54-bit processor.
    --!
    --! The constant name is from the RV32I Base Integer Instruction Set, Version 2.1
    constant XLEN: natural := 32;
    
    --! \brief Width of a standard RISC-V instruction
    --!
    --! This is applicable for all architectures.
    constant c_instruction_std_len: natural := 32;
    
    --! \brief Width of a compressed instruction
    constant c_instruction_compressed_len: natural := 16;
    
    constant c_opcode_len: natural := 7;
    constant c_func3_len: natural := 3;
    constant c_func7_len: natural := 7;
        
    --! \brief Type of one CPU register, and base type for the CPU data busses.
    subtype t_cpu_word is unsigned (XLEN-1 downto 0);
    subtype t_cpu_sword is signed (XLEN-1 downto 0);
    
    subtype t_instruction_std_word is unsigned (c_instruction_std_len-1 downto 0);
    subtype t_instruction_compressed_word is unsigned (c_instruction_compressed_len-1 downto 0);
    
    subtype t_20bit_immediate is signed (19 downto 0);
    subtype t_12bit_immediate is signed (11 downto 0);
    
    subtype t_opcode is unsigned (c_opcode_len-1 downto 0);
    subtype t_func3 is unsigned (c_func3_len-1 downto 0);
    subtype t_func7 is unsigned (c_func7_len-1 downto 0);
    
    -- memory access width. Used by ROM as well as RAM
    type enu_memory_access_width is (
        c_memory_access_8_bit,
        c_memory_access_16_bit,
        c_memory_access_32_bit);
    

    
end pkg_cpu_global;
