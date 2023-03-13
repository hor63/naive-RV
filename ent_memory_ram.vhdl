library IEEE;

use std.textio.all;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_memory_ram.all;

entity ent_memory_ram is
    generic (
        gen_hex_file: string := "./test.hex"
    );

    port ( 
        i_clock: in std_logic;

        -- the read interface section
        i_read_request: in std_logic;
        i_read_addr:    in t_cpu_word;
        i_read_width: in enu_memory_access_width;
        o_read_data: out t_cpu_word;
        o_read_data_ready: out std_logic;
        o_read_alignment_error: out std_logic;
        o_read_out_of_address_range_error: out std_logic;
        
        -- the write interface section
        i_write_request: in std_logic;
        i_write_addr:    in t_cpu_word;
        i_write_width: in enu_memory_access_width;
        i_write_data: in t_cpu_word;
        
        o_write_data_ready: out std_logic;
        o_write_alignment_error: out std_logic;
        o_write_out_of_address_range_error: out std_logic
        );

end ent_memory_ram;

architecture rtl of ent_memory_ram is
    constant c_num_memory_words: natural := c_mem_rom_num_bytes*(XLEN/c_memory_word_width);

    type t_status is (L_IDLE,L_GET_FIRST_MEM_WORD,L_DONE);

    type t_mem_array is array (c_num_memory_words-1 downto 0) of t_memory_word;

    -- the memory does not need to be initialized.
    -- This is the job of the startup code of the processor.
    signal l_mem_array: t_mem_array; -- := (others => x"0000");
    
    signal l_read_status:t_status := L_IDLE;

    signal l_read_mem_array_addr: unsigned (29 downto 0); -- Only on 4-byte boundaries
    signal l_read_out_word: t_memory_word;

    
    signal l_write_status:t_status := L_IDLE;

    signal l_write_mem_array_addr: unsigned (29 downto 0); -- Only on 4-byte boundaries
    signal l_write_out_word: t_memory_word;

begin

    read_mem: process ( i_clock) is
        variable mem_array_addr: unsigned (31 downto 0);
        variable mem_array_index: integer;
    begin
    
        if (rising_edge(i_clock))
        then

            case l_read_status is
            when L_IDLE | L_DONE =>
                if i_read_request
                then

                    mem_array_addr := i_read_addr - c_mem_ram_start_address;
                    mem_array_index := to_integer(mem_array_addr (31 downto 1));

                    case i_read_width is
                        when c_memory_access_8_bit =>
                            if mem_array_addr(0) = '1'
                            then
                                o_read_data <= x"000000" & l_mem_array(mem_array_index)(15 downto 8);
                            else
                                o_read_data <= x"000000" & l_mem_array(mem_array_index)(7 downto 0);
                            end if;
                            o_read_data_ready <= '1';
                            o_read_alignment_error <= '0';
                            l_read_status <= L_DONE;
                        when c_memory_access_16_bit =>
                            -- check alignment
                            if mem_array_addr(0) /= '0'
                            then
                                o_read_alignment_error <= '1';
                                o_read_data <= x"00000000";
                            else
                                o_read_alignment_error <= '0';
                                o_read_data <= x"0000" & l_mem_array(mem_array_index);
                            end if;
                            o_read_data_ready <= '1';
                            l_read_status <= L_DONE;
                        when c_memory_access_32_bit =>
                            -- check alignment
                            if mem_array_addr(1 downto 0) /= b"00"
                            then
                                o_read_data_ready <= '1';
                                o_read_alignment_error <= '1';
                                o_read_data <= x"00000000";
                                l_read_status <= L_DONE;
                            else
                                o_read_data_ready <= '0';
                                o_read_alignment_error <= '0';
                                l_read_status <= L_GET_FIRST_MEM_WORD;
                                l_read_out_word <= l_mem_array(mem_array_index);
                                l_read_mem_array_addr <= mem_array_addr(31 downto 2);
                            end if;
                    end case;
                else -- if i_request
                    if l_read_status = L_DONE
                    then
                        l_read_status <= L_IDLE;
                        o_read_data_ready <= '0';
                        o_read_data <= x"00000000";
                    end if;
                end if; -- if i_request
            when L_GET_FIRST_MEM_WORD =>
                o_read_data_ready <= '1';
                o_read_data <= l_mem_array(to_integer(l_read_mem_array_addr & b"1")) & l_read_out_word;
                l_read_status <= L_DONE;
            end case; -- case l_status
        
        end if;  -- if (rising_edge(i_clock))
    
    end process;

    write_mem: process ( i_clock) is
        variable mem_array_addr: unsigned (31 downto 0);
        variable mem_array_index: integer;
    begin
    
        if (rising_edge(i_clock))
        then

            case l_write_status is
            when L_IDLE | L_DONE =>
                if i_write_request
                then

                    mem_array_addr := i_write_addr - c_mem_ram_start_address;
                    mem_array_index := to_integer(mem_array_addr (31 downto 1));

                    case i_write_width is
                        when c_memory_access_8_bit =>
                            if mem_array_addr(0) = '1'
                            then
                                l_mem_array(mem_array_index)(15 downto 8) <= i_write_data(7 downto 0);
                            else
                                l_mem_array(mem_array_index)(7 downto 0) <= i_write_data(7 downto 0);
                            end if;
                            o_write_data_ready <= '1';
                            o_write_alignment_error <= '0';
                            l_write_status <= L_DONE;
                        when c_memory_access_16_bit =>
                            -- check alignment
                            if mem_array_addr(0) /= '0'
                            then
                                o_write_alignment_error <= '1';
                            else
                                o_write_alignment_error <= '0';
                                l_mem_array(mem_array_index) <= i_write_data(15 downto 0);
                            end if;
                            o_write_data_ready <= '1';
                            l_write_status <= L_DONE;
                        when c_memory_access_32_bit =>
                            -- check alignment
                            if mem_array_addr(1 downto 0) /= b"00"
                            then
                                o_write_data_ready <= '1';
                                o_write_alignment_error <= '1';
                                l_write_status <= L_DONE;
                            else
                                o_write_data_ready <= '0';
                                o_write_alignment_error <= '0';
                                l_write_status <= L_GET_FIRST_MEM_WORD;
                                l_write_out_word <= i_write_data(31 downto 16);
                                l_mem_array(mem_array_index) <= i_write_data(15 downto 0);
                                l_write_mem_array_addr <= mem_array_addr(31 downto 2);
                            end if;
                    end case;
                else -- if i_request
                    if l_write_status = L_DONE
                    then
                        l_write_status <= L_IDLE;
                        o_write_data_ready <= '0';
                        o_write_alignment_error <= '0';
                    end if;
                end if; -- if i_request
            when L_GET_FIRST_MEM_WORD =>
                o_write_data_ready <= '1';
                l_mem_array(to_integer(l_write_mem_array_addr & b"1")) <= l_write_out_word;
                l_write_status <= L_DONE;
            end case; -- case l_status
        
        end if;  -- if (rising_edge(i_clock))
    
    end process;


end rtl;
