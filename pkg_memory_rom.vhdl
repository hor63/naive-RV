
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

package pkg_memory_rom is

    constant c_memory_word_width: natural := 16;

    type enu_memory_access_width is (
        c_memory_access_8_bit,
        c_memory_access_16_bit,
        c_memory_access_32_bit);
    
    subtype t_memory_word is unsigned(c_memory_word_width-1 downto 0);

    component ent_memory_rom
    is
        
        port(
            i_clk: in std_logic;
            i_write_enable: in std_logic;
            i_write_reg_addr: in t_cpu_register_address;
            i_reg_val: in t_cpu_word;
            
            i_read_reg_addrs: in t_read_reg_addrs;
            o_reg_vals: out t_out_reg_vals
        );
    end component ent_memory_rom;

end pkg_memory_rom;
