
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;

package pkg_cpu_register_file is

    --! \brief Number of bits required to address the registers in the bank
    -- 
    -- for 32 registers you need 5 bits
    constant c_num_bits_num_registers: natural := 5; 
    --! \brief Number of CPU registers
    constant c_cpu_num_registers : natural := 2**c_num_bits_num_registers;
    
    --! \brief Width of the output bus from the register cpu_register_file
    --
    -- The is the number of parallel read paths into the register file. \n  
    -- Please note that you can write one register at one time.
    constant c_cpu_register_out_bus_width: natural := 2;
    
    subtype t_cpu_register_address is unsigned(c_num_bits_num_registers-1 downto 0);
    type t_read_reg_addrs is array (c_cpu_register_out_bus_width-1 downto 0) of t_cpu_register_address;
    type t_out_reg_vals is array (c_cpu_register_out_bus_width-1 downto 0) of t_cpu_word;
    
    component ent_cpu_register_file
    is
        
        port(
            i_clk: in std_logic;
            i_write_enable: in std_logic;
            i_write_reg_addr: in t_cpu_register_address;
            i_reg_val: in t_cpu_word;
            
            i_read_reg_addrs: in t_read_reg_addrs;
            o_reg_vals: out t_out_reg_vals
        );
    end component ent_cpu_register_file;

end pkg_cpu_register_file;
