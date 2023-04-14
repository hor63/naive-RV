
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

package pkg_memory_ram is

    constant c_memory_word_bytes: natural := 2;
    constant c_memory_word_width: natural := c_memory_word_bytes * 8;
    constant c_mem_rom_num_bytes: natural := 2*1024;
    constant c_mem_ram_start_address: unsigned (31 downto 0) := x"20000000";

    subtype t_memory_word is unsigned(c_memory_word_width-1 downto 0);

    component ent_memory_ram
    is
    generic (
        -- The witdh of the address in bits. It implicitly defines the number of bytes of memory
        -- The memory fills out the entire address space of the address bus defined by this constant.
        -- Values are:
        --  9 = 512B
        -- 10 = 1KB
        -- 11 = 2KB
        -- 12 = 4KB
        -- 13 = 8KB
        -- 14 = 16KB
        -- and so forth
        gen_addr_width: natural -- := 12
    );

    port (
        i_clock: in std_logic;

        -- the read interface section
        i_read_addr_valid: in std_logic;
        o_read_addr_ready: out std_logic;
        i_read_addr:    in t_cpu_word;
        i_read_width: in enu_memory_access_width;
        o_read_data: out t_cpu_word;
        o_read_data_ready: out std_logic;
        o_read_alignment_error: out std_logic;
        o_read_out_of_address_range_error: out std_logic;

        -- the write interface section
        i_write_request: in std_logic;
        i_write_addr:    in t_cpu_word;
        i_write_width: in enu_memory_access_width;
        i_write_data: in t_cpu_word;

        o_write_data_ready: out std_logic;
        o_write_alignment_error: out std_logic;
        o_write_out_of_address_range_error: out std_logic
        );
    end component ent_memory_ram;

end pkg_memory_ram;
