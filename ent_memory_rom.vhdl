library IEEE;

use std.textio.all;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_memory_rom.all;

entity ent_memory_rom is

    generic (
        gen_num_bytes: natural := 2*1024;
        gen_hex_file: string := "./test.hex"
    );

    port ( 
        i_clock: in std_logic;
        
        i_reset: in std_logic;
        o_reset_done: in std_logic;
        
        i_request: in std_logic;
        i_addr:    in t_cpu_word;
        i_read_width: in enu_memory_access_width;
        
        o_data: out t_cpu_word;
        o_data_ready: out std_logic;
        o_alignment_error: out std_logic;
        o_out_of_address_range_error: out std_logic
        );

end ent_memory_rom;

architecture rtl of ent_memory_rom is

    type t_status is (L_IDLE,L_GET_FIRST_MEM_WORD,L_DONE);

    type t_mem_array is array (c_num_memory_words-1 downto 0) of t_memory_word;

    constant c_num_memory_words: natural := gen_num_bytes*(XLEN/c_memory_word_width);

    signal l_mem_array: t_mem_array;
    
    signal l_status := L_IDLE;

begin

    process rtl of ent_memory_rom ( i_clock) is
        variable l_reset_done: std_logic;
        variable l_data: t_cpu_word;
        variable l_data_ready: std_logic;
        variable l_alignment_error: std_logic;
    
    begin
    
        if (raising_edge(i_clock))
        then

            -- Reset first
            if i_reset and 
        
        end if;
    
    end process;


end rtl;
