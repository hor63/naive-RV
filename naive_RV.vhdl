
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use std.textio.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_cpu_instruction_decoder.all;

entity naive_RV is
end naive_RV;

architecture testbench of naive_RV
is

-- start interface to the decoder

    

    signal l_instruction: t_instruction_std_word := x"00000000";

    signal l_opcode: t_opcode;
    signal l_func3: t_func3;
    signal l_func7: t_func7;
    
    signal l_immediate: t_cpu_sword;
            
    signal l_dest_reg: t_cpu_register_address;
    signal l_source_reg_1: t_cpu_register_address;
    signal l_source_reg_2: t_cpu_register_address;
    
    signal l_enab_alu: std_logic;
    signal l_enab_shifter: std_logic;
    signal l_enab_reg_load: std_logic;
    signal l_enab_load: std_logic;
    signal l_enab_store: std_logic;
    signal l_enab_jump: std_logic;
    signal l_enab_fence: std_logic;
    signal l_enab_system: std_logic;
    
    signal l_illegal_instruction: std_logic;
-- end interface to the decoder

    function get_string (i_str: string) return string
    is
    begin
        return i_str;
    end function;

begin

    l_decoder: ent_cpu_instruction_decoder
        port map (
            i_instruction => l_instruction,

            o_opcode => l_opcode,
            o_func3 => l_func3,
            o_func7 => l_func7,
            
            o_immediate => l_immediate,
                    
            o_dest_reg => l_dest_reg,
            o_source_reg_1 => l_source_reg_1,
            o_source_reg_2 => l_source_reg_2,
            
            o_enab_alu => l_enab_alu,
            o_enab_shifter => l_enab_shifter,
            o_enab_reg_load => l_enab_reg_load,
            o_enab_load => l_enab_load,
            o_enab_store => l_enab_store,
            o_enab_jump => l_enab_jump,
            o_enab_fence => l_enab_fence,
            o_enab_system => l_enab_system,

            o_illegal_instruction => l_illegal_instruction
            );
        

    rb: process is   
        variable log_line: line;
        constant c_str_start: string := "Start";
        variable st: string(1 to 5);
    begin
        file_open(f_logger,"./naive_RV.log",write_mode);
        
        write(log_line,get_string("Start program"));
        writeline(f_logger,log_line);
        
        wait for 10 ns;
        write(log_line,get_string("auipc   gp,0x10001"));
        writeline(f_logger,log_line);
        l_instruction <= x"10001197";
        wait for 10 ns;
        write(log_line,get_string("add     gp,gp,-2040"));
        writeline(f_logger,log_line);
        l_instruction <= x"80818193";
        wait for 10 ns;
        write(log_line,get_string("beq     t0,t1,10000040"));
        writeline(f_logger,log_line);
        l_instruction <= x"02628263";
        wait for 10 ns;
        write(log_line,get_string("beqz    t0,10000040"));
        writeline(f_logger,log_line);
        l_instruction <= x"02028063";
        wait for 10 ns;
        write(log_line,get_string("bgeu    t1,t2,10000040"));
        writeline(f_logger,log_line);
        l_instruction <= x"00737c63";
        wait for 10 ns;
        write(log_line,get_string("lw      t3,0(t0)"));
        writeline(f_logger,log_line);
        l_instruction <= x"0002ae03";
        wait for 10 ns;
        write(log_line,get_string("sw      t3,0(t1)"));
        writeline(f_logger,log_line);
        l_instruction <= x"01c32023";
        wait for 10 ns;
        write(log_line,get_string("jal     10000234"));
        writeline(f_logger,log_line);
        l_instruction <= x"1e4000ef";
        wait for 10 ns;
        
        
        write(log_line,get_string("End program"));
        writeline(f_logger,log_line);
        file_close(f_logger);
        wait;
    end process;

end testbench;
