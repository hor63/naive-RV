library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use std.textio.all;
use std.env.finish;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_cpu_instruction_decoder.all;
use work.pkg_memory_rom.all;
use work.pkg_memory_ram.all;

entity naive_RV is
end naive_RV;

architecture testbench of naive_RV
is

    constant rom_addr_width: natural := 11; -- 2KB ROM

    signal l_clock: std_logic;
    signal l_reset_valid: std_logic;


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

-- start interface to the ROM
    signal l_rom_reset_ready: std_logic;

    signal l_rom_read_addr_valid: std_logic;
    signal l_rom_read_addr_ready: std_logic;
    signal l_rom_addr:    unsigned (rom_addr_width-1 downto 0);
    signal l_rom_read_width: enu_memory_access_width;

    signal l_rom_data: t_cpu_word;
    signal l_rom_data_valid: std_logic;
    signal l_rom_data_ready: std_logic;
    signal l_rom_alignment_error: std_logic;
-- end

-- start interface to the RAM
    signal l_ram_mem_rom_reset_done: std_logic;

    signal l_ram_read_addr_valid: std_logic;
    signal l_ram_read_addr:    t_cpu_word;
    signal l_ram_read_width: enu_memory_access_width;

    signal l_ram_read_data: t_cpu_word;
    signal l_ram_read_data_ready: std_logic;
    signal l_ram_read_alignment_error: std_logic;
    signal l_ram_read_out_of_address_range_error: std_logic;
    
    -- the write interface section
    signal l_ram_write_request: std_logic;
    signal l_ram_write_addr:    t_cpu_word;
    signal l_ram_write_width: enu_memory_access_width;
    signal l_ram_write_data: t_cpu_word;
    
    signal l_ram_write_data_ready: std_logic;
    signal l_ram_write_alignment_error: std_logic;
    signal l_ram_write_out_of_address_range_error: std_logic;

-- end

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

    l_memory_rom: ent_memory_rom
    generic map (
        gen_mem_rom_start_address => x"10000000",
        gen_addr_width => rom_addr_width, -- 2KB ROM
        gen_hex_file => "./test.hex"
    )
    port map (
        i_clock => l_clock,

        i_reset_valid => l_reset_valid,
        o_reset_ready => l_rom_reset_ready,

        i_read_addr_valid => l_rom_read_addr_valid,
        o_read_addr_ready => l_rom_read_addr_ready,
        i_read_addr => l_rom_addr,
        i_read_width => l_rom_read_width,

        o_data => l_rom_data,
        o_data_valid => l_rom_data_valid,
        i_data_ready => l_rom_data_ready,
        o_alignment_error => l_rom_alignment_error
        );
            
    l_memory_ram: ent_memory_ram
        generic map (
            gen_addr_width => 11 -- 2KB memory
        )
        port map(
            i_clock => l_clock,

            -- the read interface section
            i_read_addr_valid => l_ram_read_addr_valid ,
            i_read_addr => l_ram_read_addr ,
            i_read_width => l_ram_read_width ,
            o_read_data => l_ram_read_data ,
            o_read_data_ready => l_ram_read_data_ready ,
            o_read_alignment_error => l_ram_read_alignment_error ,
            o_read_out_of_address_range_error => l_ram_read_out_of_address_range_error ,
            
            -- the write interface section
            i_write_request => l_ram_write_request ,
            i_write_addr => l_ram_write_addr ,
            i_write_width => l_ram_write_width ,
            i_write_data => l_ram_write_data ,
            
            o_write_data_ready => l_ram_write_data_ready ,
            o_write_alignment_error => l_ram_write_alignment_error ,
            o_write_out_of_address_range_error => l_ram_write_out_of_address_range_error 

            );

    clock_gen: process is
    begin
        l_clock <= '1';
        wait for 5 ns;
        l_clock <= '0';
        wait for 5 ns;
    end process;

    rb: process is   
        variable log_line: line;
        constant c_str_start: string := "Start";
        variable st: string(1 to 5);
    begin
        file_open(f_logger,"./naive_RV.log",write_mode);
        
        write(log_line,get_string("Start program"));
        writeline(f_logger,log_line);

        l_rom_read_addr_valid <= '0';
        l_rom_data_ready <= '0';

        wait for 10 ns;

        l_reset_valid <= '1';
        wait for 30 ns;
        l_reset_valid <= '0';

        wait until l_rom_reset_ready = '1';

        -- Write the RAM
        wait until l_clock = '1';
        --wait for 10 ns;
        l_ram_write_addr <= x"20000008";
        l_ram_write_width <= c_memory_access_32_bit;
        l_ram_write_data <= x"01001011";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        --wait for 10 ns;
        l_ram_write_addr <= x"20000001";
        l_ram_write_width <= c_memory_access_32_bit;
        l_ram_write_data <= x"01001011";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;


        wait for 10 ns;
        l_ram_write_addr <= x"20000000";
        l_ram_write_width <= c_memory_access_8_bit;
        l_ram_write_data <= x"02002022";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000001";
        l_ram_write_width <= c_memory_access_8_bit;
        l_ram_write_data <= x"02002020";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000002";
        l_ram_write_width <= c_memory_access_8_bit;
        l_ram_write_data <= x"02002002";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000003";
        l_ram_write_width <= c_memory_access_8_bit;
        l_ram_write_data <= x"02002012";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000004";
        l_ram_write_width <= c_memory_access_16_bit;
        l_ram_write_data <= x"03003033";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000005";
        l_ram_write_width <= c_memory_access_16_bit;
        l_ram_write_data <= x"03003023";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        l_ram_write_addr <= x"20000006";
        l_ram_write_width <= c_memory_access_16_bit;
        l_ram_write_data <= x"03003023";
        l_ram_write_request <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_write_data_ready;
        end loop;

        -- Read from the RAM
        
        wait until l_clock = '1';
        --wait for 10 ns;
        l_ram_read_addr <= x"20000008";
        l_ram_read_width <= c_memory_access_32_bit;
        l_ram_read_addr_valid <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_read_data_ready;
        end loop;

        l_ram_read_addr <= x"20000001";
        l_ram_read_width <= c_memory_access_32_bit;
        l_ram_read_addr_valid <= '1';
        loop
            wait for 10 ns;
            exit when l_ram_read_data_ready;
        end loop;
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr <= x"20000000";
        l_ram_read_width <= c_memory_access_32_bit;
        l_ram_read_addr_valid <= '1';
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000000";
        l_ram_read_width <= c_memory_access_16_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';
        
        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000002";
        l_ram_read_width <= c_memory_access_16_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';
        
        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000001";
        l_ram_read_width <= c_memory_access_16_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000000";
        l_ram_read_width <= c_memory_access_8_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000001";
        l_ram_read_width <= c_memory_access_8_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000002";
        l_ram_read_width <= c_memory_access_8_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000003";
        l_ram_read_width <= c_memory_access_8_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';

        l_ram_read_addr_valid <= '1';
        l_ram_read_addr <= x"20000004";
        l_ram_read_width <= c_memory_access_8_bit;
        wait until l_ram_read_data_ready = '1';
        l_ram_read_addr_valid <= '0';
        wait until l_ram_read_data_ready = '0';


        wait until l_clock = '1';
        --wait for 10 ns;
        l_rom_addr <= resize(x"8",rom_addr_width);
        l_rom_read_width <= c_memory_access_32_bit;
        l_rom_read_addr_valid <= '1';
        --wait for 10 ns;
        loop
            wait until l_clock = '1';
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;
        l_rom_data_ready <= '1';
        wait for 10 ns;

        l_rom_addr <= resize(x"1",rom_addr_width);
        l_rom_read_width <= c_memory_access_32_bit;
        l_rom_read_addr_valid <= '1';
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_addr <= resize(x"0",rom_addr_width);
        l_rom_read_width <= c_memory_access_32_bit;
        l_rom_read_addr_valid <= '1';
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"0",rom_addr_width);
        l_rom_read_width <= c_memory_access_16_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"2",rom_addr_width);
        l_rom_read_width <= c_memory_access_16_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"1",rom_addr_width);
        l_rom_read_width <= c_memory_access_16_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"0",rom_addr_width);
        l_rom_read_width <= c_memory_access_8_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"1",rom_addr_width);
        l_rom_read_width <= c_memory_access_8_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"2",rom_addr_width);
        l_rom_read_width <= c_memory_access_8_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"3",rom_addr_width);
        l_rom_read_width <= c_memory_access_8_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
        wait for 10 ns;

        l_rom_read_addr_valid <= '1';
        l_rom_addr <= resize(x"4",rom_addr_width);
        l_rom_read_width <= c_memory_access_8_bit;
        loop
            wait for 10 ns;
            exit when l_rom_data_valid;
        end loop;
        l_rom_read_addr_valid <= '0';
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
        wait for 10 ns;

        finish;
        wait;
    end process;

end testbench;
