library IEEE;

use std.textio.all;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_memory_rom.all;

entity ent_memory_rom is
    generic (
        gen_hex_file: string := "./test.hex"
    );

    port ( 
        i_clock: in std_logic;
        
        i_reset: in std_logic;
        o_reset_done: out std_logic;
        
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
    constant c_num_memory_words: natural := c_mem_rom_num_bytes*(XLEN/c_memory_word_width);

    type t_status is (L_RESET,L_IDLE,L_GET_FIRST_MEM_WORD,L_DONE);

    type t_mem_array is array (c_num_memory_words-1 downto 0) of t_memory_word;

    signal l_mem_array: t_mem_array := (others => x"0000");
    
    signal l_status:t_status := L_IDLE;

    signal l_mem_array_addr: unsigned (29 downto 0); -- Only on 4-byte boundaries
    signal l_out_word: t_memory_word;

    procedure clear_memory (signal mem_array: out t_mem_array ) is
    begin
        for i in 0 to c_num_memory_words-1
        loop
            mem_array(i) <= (others => '0');
        end loop;
    end clear_memory;

    procedure read_byte_hex(val: out unsigned (7 downto 0);
        variable hex_line: inout line) is
        variable bval: Bit_Vector(7 downto 0);
        variable good: boolean;
    begin
        Hread(hex_line,bval,good);
        assert good report "ent_memory_rom: Cannot read hex value" severity failure;
        val := unsigned(to_stdlogicvector(bval));
    end read_byte_hex;

    procedure process_line (
        signal mem_array: out t_mem_array;
        variable hex_line: inout line;
        variable end_file: inout boolean;
        variable ext_addr: inout unsigned (15 downto 0)
        ) is
        variable c: character;
        variable good: boolean;
        variable u_byte: unsigned (7 downto 0);
        variable u_word: unsigned (15 downto 0);
        variable checksum: unsigned (15 downto 0);
        variable len_record: integer;
        variable address: unsigned  (15 downto 0);
        variable mem_array_addr: unsigned (31 downto 0);
        variable mem_array_index: integer;
    begin
        -- look for the start of the record.
        loop
            read (hex_line,c,good);
            assert good report "ent_memory_rom: Did not find start of record." severity failure;
            exit when c = ':';
        end loop;

        checksum := x"0000";

        -- first byte is the record length
        read_byte_hex (u_byte,hex_line);
        checksum := checksum + resize(u_byte,16);
        len_record := to_integer(u_byte);

        read_byte_hex (u_byte,hex_line);
        checksum := checksum + resize(u_byte,16);
        address (15 downto 8) := u_byte;
        read_byte_hex (u_byte,hex_line);
        checksum := checksum + resize(u_byte,16);
        address (7 downto 0) := u_byte;

        -- read the record type
        read_byte_hex (u_byte,hex_line);
        checksum := checksum + resize(u_byte,16);


        case u_byte is
            when x"00" => -- data
                mem_array_addr := ext_addr & address;
                mem_array_addr := mem_array_addr - c_mem_rom_start_address;

                for i in 0 to len_record-1 loop
                    mem_array_index := to_integer(mem_array_addr (31 downto 1));
                    read_byte_hex (u_byte,hex_line);
                    checksum := checksum + resize(u_byte,16);
                    if mem_array_addr(0) = '0'
                    then
                        mem_array(mem_array_index)(7 downto 0) <= u_byte;
                    else
                        mem_array(mem_array_index)(15 downto 8) <= u_byte;
                    end if;

                    mem_array_addr := mem_array_addr + 1;

                end loop;
            when x"01" => -- data
                end_file := true;
                return;
            when x"02" => -- extended segment address
                assert false report "ent_memory_rom: Record type ""extended segment address"" is not supported." severity failure;
            when x"03" => -- start segment address
                assert false report "ent_memory_rom: Record type ""start segment address"" is not supported." severity failure;
            when x"04" => -- extended linear address
                assert len_record = 2 report "ent_memory_rom: Data len for extended linear address is not 4." severity failure;
                read_byte_hex (u_byte,hex_line);
                checksum := checksum + resize(u_byte,16);
                ext_addr(15 downto 8) := u_byte;

                read_byte_hex (u_byte,hex_line);
                checksum := checksum + resize(u_byte,16);
                ext_addr(7 downto 0) := u_byte;
            when x"05" => -- start segment address
                assert len_record = 4 report "ent_memory_rom: Data len for extended linear address is not 4." severity failure;
            when others =>
                assert false report "ent_memory_rom: unknown record type." severity failure;
        end case;
    end;

    procedure load_memory (signal mem_array: out t_mem_array ) is
        -- The upper 16 bit of the hex file extended address
        variable ext_addr: unsigned (15 downto 0) := x"0000";
        file hexfile: text;
        variable hex_line: line;
        variable end_file: boolean := false;
    begin
        clear_memory(mem_array);

        file_open(hexfile,gen_hex_file,read_mode);

        while (not end_file)
        loop
            readline(hexfile,hex_line);

            process_line (
                mem_array,
                hex_line,
                end_file,
                ext_addr
                );

        end loop;

    end load_memory;

begin

    process  ( i_clock) is
        -- variable l_data_ready: std_logic;
        -- variable l_alignment_error: std_logic;
    
        variable mem_array_addr: unsigned (31 downto 0);
        variable mem_array_index: integer;
    begin
    
        if (rising_edge(i_clock))
        then

            -- Reset circuit first
            if i_reset
            then
                if l_status /= L_RESET
                then
                    o_reset_done <= '0';
                    l_status <= L_RESET;
                    o_data <= (others => '0');
                    o_data_ready <= '0';
                    o_alignment_error <= '0';
                    o_out_of_address_range_error <= '0';
                    
                    load_memory (l_mem_array);
                end if;
            else -- if i_reset
                case l_status is
                when  L_RESET =>
                    o_reset_done <= '1';
                    l_status <= L_IDLE;
                when L_IDLE | L_DONE =>
                    if i_request
                    then

                        mem_array_addr := i_addr - c_mem_rom_start_address;
                        mem_array_index := to_integer(mem_array_addr (31 downto 1));

                        case i_read_width is
                            when c_memory_access_8_bit =>
                                if mem_array_addr(0) = '1'
                                then
                                    o_data <= x"000000" & l_mem_array(mem_array_index)(15 downto 8);
                                else
                                    o_data <= x"000000" & l_mem_array(mem_array_index)(7 downto 0);
                                end if;
                                o_data_ready <= '1';
                                o_alignment_error <= '0';
                                l_status <= L_DONE;
                            when c_memory_access_16_bit =>
                                -- check alignment
                                if mem_array_addr(0) /= '0'
                                then
                                    o_alignment_error <= '1';
                                    o_data <= x"00000000";
                                else
                                    o_alignment_error <= '0';
                                    o_data <= x"0000" & l_mem_array(mem_array_index);
                                end if;
                                o_data_ready <= '1';
                                l_status <= L_DONE;
                            when c_memory_access_32_bit =>
                                -- check alignment
                                if mem_array_addr(1 downto 0) /= b"00"
                                then
                                    o_data_ready <= '1';
                                    o_alignment_error <= '1';
                                    o_data <= x"00000000";
                                    l_status <= L_DONE;
                                else
                                    o_data_ready <= '0';
                                    o_alignment_error <= '0';
                                    l_status <= L_GET_FIRST_MEM_WORD;
                                    l_out_word <= l_mem_array(mem_array_index);
                                    l_mem_array_addr <= mem_array_addr(31 downto 2);
                                end if;
                        end case;
                    else -- if i_request
                        if l_status = L_DONE
                        then
                            l_status <= L_IDLE;
                            o_data_ready <= '0';
                            o_alignment_error <= '0';
                            o_data <= x"00000000";
                        end if;
                    end if; -- if i_request
                when L_GET_FIRST_MEM_WORD =>
                    o_data_ready <= '1';
                    o_data <= l_mem_array(to_integer(l_mem_array_addr & b"1")) & l_out_word;
                    l_status <= L_DONE;
                end case; -- case l_status
            end if; -- if i_reset
        
        end if;  -- if (rising_edge(i_clock))
    
    end process;


end rtl;
