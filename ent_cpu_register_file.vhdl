
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

entity ent_cpu_register_file
is
    
    port(
        i_clk: in std_logic;
        i_write_enable: in std_logic;
        i_write_reg_addr: in t_cpu_register_address;
        i_reg_val: in t_cpu_word;
        
        i_read_reg_addrs: in t_read_reg_addrs;
        o_reg_vals: out t_out_reg_vals
    );
end ent_cpu_register_file;

architecture rtl of ent_cpu_register_file
is
    type t_register_file is array (c_cpu_num_registers-1 downto 0) of t_cpu_word;
    signal register_file: t_register_file;
begin
    

    process (i_clk) is
    begin
        if rising_edge(i_clk)
        then
            if (i_write_enable = '1')
            then
                register_file(to_integer(i_write_reg_addr)) <= i_reg_val;
            end if;
        end if; -- if rising_edge(i_clk)
    end process;

    process(i_read_reg_addrs, register_file) is
        --variable i: natural;
    begin
        for i in 0 to c_cpu_register_out_bus_width-1 loop
            o_reg_vals(i) <= register_file(to_integer(i_read_reg_addrs(i)));
        end loop;
    end process;
    
end rtl;
