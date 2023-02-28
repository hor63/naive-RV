
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;

package pkg_cpu_instruction_decoder is

component ent_cpu_instruction_decoder
is
    port (
        i_instruction: in t_instruction_std_word;

        o_opcode: out t_opcode;
        o_func3: out t_func3;
        o_func7: out t_func7;
        
        o_immediate: out t_cpu_sword;
                
        o_dest_reg: out t_cpu_register_address;
        o_source_reg_1: out t_cpu_register_address;
        o_source_reg_2: out t_cpu_register_address;
        
        o_enab_alu: out std_logic;
        o_enab_shifter: out std_logic;
        o_enab_reg_load: out std_logic;
        o_enab_load: out std_logic;
        o_enab_store: out std_logic;
        o_enab_jump: out std_logic;
        o_enab_fence: out std_logic;
        o_enab_system: out std_logic;
        
        o_illegal_instruction: out std_logic
    );

end component ent_cpu_instruction_decoder;


end package;
