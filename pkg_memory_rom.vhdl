
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

package pkg_memory_rom is

    constant c_memory_word_bytes: natural := 2;
    constant c_memory_word_width: natural := c_memory_word_bytes * 8;
    constant c_mem_rom_num_bytes: natural := 2*1024;
    constant c_mem_rom_start_address: unsigned (31 downto 0) := x"10000000";

    subtype t_memory_word is unsigned(c_memory_word_width-1 downto 0);

    component ent_memory_rom
    is
        generic (
            gen_hex_file: string := "./test.hex"
        );

        port (
            i_clock: in std_logic;

            i_reset: in std_logic;
            o_reset_done: out std_logic;

            i_request: in std_logic;
            i_addr:    in t_cpu_word;
            i_read_width: in enu_memory_access_width;

            o_data: out t_cpu_word;
            o_data_ready: out std_logic;
            o_alignment_error: out std_logic;
            o_out_of_address_range_error: out std_logic
            );
    end component ent_memory_rom;

end pkg_memory_rom;
