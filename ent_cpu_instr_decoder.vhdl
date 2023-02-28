
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_cpu_instruction_decoder.all;

entity ent_cpu_instruction_decoder
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

end ent_cpu_instruction_decoder;

architecture rtl of ent_cpu_instruction_decoder
is

    alias a_opcode: t_opcode is i_instruction(6 downto 0);
    alias a_func_3: t_func3 is i_instruction(14 downto 12);
    alias a_func_7: t_func7 is i_instruction(31 downto 25);

    alias a_dest_reg: t_cpu_register_address is i_instruction(11 downto 7);
    alias a_source_reg_1: t_cpu_register_address is i_instruction(19 downto 15);
    alias a_source_reg_2: t_cpu_register_address is i_instruction(24 downto 20);
    
    function i_immediate (i_instr: t_instruction_std_word) 
        return t_cpu_sword 
    is
    begin
        return resize(signed(i_instr(31 downto 20)) , XLEN);
    end function;

    function s_immediate (i_instr: t_instruction_std_word) 
        return t_cpu_sword 
    is
    begin
        return resize(signed(std_logic_vector(i_instr(31 downto 25)) & std_logic_vector(i_instr(11 downto 7))) , XLEN);
    end function;

    function b_immediate (i_instr: t_instruction_std_word) 
        return t_cpu_sword 
    is
    begin
        return resize(signed(std_logic(i_instr(31)) & std_logic(i_instr(7)) & std_logic_vector(i_instr(30 downto 25)) & std_logic_vector(i_instr(11 downto 8)) & '0') , XLEN);
    end function;
    
    function u_immediate (i_instr: t_instruction_std_word) 
        return t_cpu_sword 
    is
    begin
        return signed(std_logic_vector(i_instr(31 downto 12)) & x"000");
    end function;
    
    function j_immediate (i_instr: t_instruction_std_word) 
        return t_cpu_sword 
    is
    begin
        return resize(signed(i_instr(31) & i_instr(19 downto 12) & i_instr(20) & i_instr(30 downto 21) & '0') , XLEN);
    end function;
    
begin

    process (i_instruction) is
        variable opcode: t_opcode;
        variable func3: t_func3;
        variable func7: t_func7;
    begin
    
        opcode := a_opcode;
        func3 := a_func_3;
        func7 := a_func_7;
    
        o_opcode <= opcode;
        o_func3 <= func3;
        o_func7 <= func7;
           
        -- Set the register addresses unconditionally.
        -- It saves me some circuitry here.
        -- Their use depends on the operational block which is enabled.
        o_dest_reg <= i_instruction(11 downto 7);
        o_source_reg_1 <= i_instruction(19 downto 15);
        o_source_reg_2 <= i_instruction(24 downto 20);
        
        o_enab_alu <= '0';
        o_enab_shifter <= '0';
        o_enab_reg_load <= '0';
        o_enab_load <= '0';
        o_enab_store <= '0';
        o_enab_jump <= '0';
        o_enab_fence <= '0';
        o_enab_system <= '0';

        o_illegal_instruction <= '0';

        -- 1st level: The opcode determines the basic type of instruction, and the instruction word structure.
        case opcode is
            when b"0110111" => -- LUI
                o_enab_reg_load <= '1';
                o_immediate <= u_immediate(i_instruction);
            
            when b"0010111" => -- AUIPC
                o_enab_reg_load <= '1';
                o_immediate <= u_immediate(i_instruction);
            
            when b"1101111" => -- JAL
                o_enab_jump <= '1';
                o_immediate <= j_immediate(i_instruction);
            
            when b"1100111" => -- JALR
                if func3 = b"000" then
                    o_enab_jump <= '1';
                    o_immediate <= j_immediate(i_instruction);
                else
                    o_illegal_instruction <= '1';
                end if;

            when b"1100011" => -- Conditional Branches
                o_enab_jump <= '1';
                o_immediate <= b_immediate(i_instruction);
            
            when b"0000011" => -- Load
                o_enab_load <= '1';
                o_immediate <= i_immediate(i_instruction);
            
            when b"0100011" => -- Store
                o_enab_store <= '1';
                o_immediate <= s_immediate(i_instruction);
            
            when b"0010011" => -- OP-Immediate
                if func3 = b"001" or func3 = b"101" then
                    o_enab_shifter <= '1';
                else
                    o_enab_alu <= '1';
                end if;
                o_immediate <= i_immediate(i_instruction);
            
            when b"0110011" => -- OP
                if func3 = b"001" or func3 = b"101" then
                    o_enab_shifter <= '1';
                else
                    o_enab_alu <= '1';
                end if;
                -- Avoid latch condition.
                o_immediate <= x"0000_0000";
            
            when b"0001111" => -- MISC-MEM/Fence
                o_enab_fence <= '0';
                o_immediate <= i_immediate(i_instruction);
            
            when "1110011" => -- SYSTEM/ ECALL-EBREAK
                o_enab_system <= '0';
                o_immediate <= i_immediate(i_instruction);
            
            when others =>
                o_illegal_instruction <= '1';
                -- Avoid latch condition.
                o_immediate <= x"0000_0000";
        end case;
        
        
    end process;
    

end rtl;
