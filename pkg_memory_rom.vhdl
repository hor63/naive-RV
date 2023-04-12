
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

package pkg_memory_rom is


    component ent_memory_rom is
        generic (

            --! \brief This start address is *only* needed for reading a HEX file into the ROM.
            --!
            --! At run time the ROM is addressed directly by the memory controller wich takes care of directly addressing
            --! ROM and RAM addresses within the respective modules.
            gen_mem_rom_start_address: unsigned (31 downto 0) := x"10000000";

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
            gen_addr_width: natural := 11;

            gen_hex_file: string := "./test.hex"
        );

        port (
            i_clock: in std_logic;

            i_reset_valid: in std_logic;
            o_reset_ready: out std_logic;

            i_read_addr_valid: in std_logic;
            o_read_addr_ready: out std_logic;
            i_read_addr:    in unsigned(gen_addr_width-1 downto 0);
            i_read_width: in enu_memory_access_width;


            o_data: out t_cpu_word;
            o_data_valid: out std_logic;
            i_data_ready: in std_logic;
            o_alignment_error: out std_logic
            );

    end component ent_memory_rom;

end pkg_memory_rom;
