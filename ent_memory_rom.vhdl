library IEEE;

use std.textio.all;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pkg_cpu_global.all;
use work.pkg_cpu_register_file.all;
use work.pkg_memory_rom.all;

entity ent_memory_rom is
    generic (

        --! \brief This start address is *only* needed for reading a HEX file into the ROM.
        --!
        --! At run time the ROM is addressed directly by the memory controller wich takes care of directly addressing
        --! ROM and RAM addresses within the respective modules.
        gen_mem_rom_start_address: unsigned (31 downto 0); -- := x"10000000";

        -- The witdh of the address in bits. It implicitly defines the number of bytes of memory
        -- The memory fills out the entire address space of the address bus defined by this constant.
        -- Values are:
        --  9 = 512B
        -- 10 = 1KB
        -- 11 = 2KB
        -- 12 = 4KB
        -- 13 = 8KB
        -- 14 = 16KB
        -- and so forth
        gen_addr_width: natural; -- := 11;

        gen_hex_file: string := "./test.hex"
    );

    port ( 
        i_clock: in std_logic;
        
        i_reset_valid: in std_logic;
        o_reset_ready: out std_logic;
        
        i_read_addr_valid: in std_logic;
        o_read_addr_ready: out std_logic;
        i_read_addr:    in unsigned(gen_addr_width-1 downto 0);
        i_read_width: in enu_memory_access_width;


        o_data: out t_cpu_word;
        o_data_valid: out std_logic;
        i_data_ready: in std_logic;
        o_alignment_error: out std_logic
        );

end ent_memory_rom;

architecture rtl of ent_memory_rom is
    constant c_memory_word_bytes: natural := 2;
    constant c_memory_word_width: natural := c_memory_word_bytes * 8;

    constant c_mem_rom_num_bytes: natural := 2**gen_addr_width;
    constant c_num_memory_words: natural := c_mem_rom_num_bytes*(XLEN/c_memory_word_width);
    
    subtype t_memory_word is unsigned(c_memory_word_width-1 downto 0);

    type t_status is (L_RESET,L_IDLE,L_GET_FIRST_MEM_WORD,L_DONE);

    type t_mem_array is array (c_num_memory_words-1 downto 0) of t_memory_word;

    -- the registers within this architecture
    signal r_mem_array: t_mem_array := (others => x"0000");
    
    signal r_status:t_status := L_IDLE;

    signal r_mem_array_addr: unsigned (gen_addr_width-3 downto 0); -- Only on 4-byte boundaries
    signal r_out_word: t_memory_word := (others => '0');

    signal r_data: t_cpu_word  := (others => '0');
    signal r_data_valid: std_logic := '0';
    signal r_alignment_error: std_logic := '0';

    -- intermediates which store the results of the combinatoric process
    -- until they are copied into the outputs on the rising clock edge
    -- note, these are not registers but driven real-time by combinatoric logic.
    signal l_reset_ready: std_logic;

    signal l_read_addr_ready: std_logic;

    signal l_data: t_cpu_word;
    signal l_data_valid: std_logic;
    signal l_alignment_error: std_logic;

    signal l_status:t_status;
    signal l_mem_array_addr: unsigned (gen_addr_width-3 downto 0); -- Only on 4-byte boundaries
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

        checksum := x"0000";        -- variable l_data_ready: std_logic;
        -- variable l_alignment_error: std_logic;



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
                mem_array_addr := mem_array_addr - gen_mem_rom_start_address;
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
            when x"01" => -- end of file. Stop reading. You are finished.
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

    -- Copy the internally stored values to the outputs immediately
    o_data <= r_data;
    o_data_valid <= r_data_valid;
    o_alignment_error <= r_alignment_error;


    -- All the combinatoric logic is in here.
    -- The clock only triggers copying the processed stuff from the internal intermediates
    -- into the outputs and updates the status machine status
    process  (

        i_reset_valid, i_read_addr_valid, i_read_addr,i_data_ready,
        r_status, r_mem_array_addr, r_out_word
    ) is
        variable mem_array_addr: unsigned (gen_addr_width-1 downto 0);
        variable mem_array_index: integer;
        variable device_free: boolean;
    begin

        device_free := false;

        -- ensure that no latches are being generated.
        l_reset_ready <= '0';
        l_read_addr_ready <= '0';
        l_data <= r_data;
        l_data_valid <= r_data_valid;
        l_alignment_error <= r_alignment_error;
        l_status <= r_status;
        l_mem_array_addr <= r_mem_array_addr;
        l_out_word <= r_out_word;

        -- Reset circuit first
        if i_reset_valid
        then
            if r_status /= L_RESET
            then
                l_status <= L_RESET;
                l_data_valid <= '0';
                l_alignment_error <= '0';
                l_out_word <= (others => '0');
                l_mem_array_addr <= (others => '0');
                l_data <= (others => '0');
                load_memory (r_mem_array);
            end if;
            l_reset_ready <= '1';
        else -- if i_reset_valid
            case r_status is
            when  L_RESET =>
                l_reset_ready <= '0';
                l_status <= L_IDLE;
            when L_DONE =>
                -- wait until the reader has consumed the data
                -- If the reader is not ready keep the entity occupied,
                -- and so not accept new read requests.
                if i_data_ready
                then
                    device_free := true;
                    l_status <= L_IDLE;
                    l_data_valid <= '0';
                    l_data <= (others => '0');
                end if;
            when L_IDLE =>
                device_free := true;
            when L_GET_FIRST_MEM_WORD =>
                -- All checks have passed in the previous cycle.
                -- Finish the read process directly here.
                l_data_valid <= '1';
                l_data <= r_mem_array(to_integer(r_mem_array_addr & b"1")) & r_out_word;
                l_status <= L_DONE;
            end case; -- case r_status
        end if; -- if i_reset_valid

        if device_free
        then
            if i_read_addr_valid
            then

                mem_array_addr := i_read_addr;
                -- Remember, the memory cells are 16-bit words.
                -- Therefore the index into the memory array is built by stripping the LSB.
                mem_array_index := to_integer(mem_array_addr (gen_addr_width-1 downto 1));

                case i_read_width is
                    when c_memory_access_8_bit =>
                        -- 8-bit access always works.
                        -- Depending on the LSB of the address I need to pick the upper or
                        -- lower byte from the 16-bit memory word.
                        if mem_array_addr(0) = '1'
                        then
                            l_data <= x"000000" & r_mem_array(mem_array_index)(15 downto 8);
                        else
                            l_data <= x"000000" & r_mem_array(mem_array_index)(7 downto 0);
                        end if;
                        l_data_valid <= '1';
                        l_status <= L_DONE;
                        l_alignment_error <= '0';
                    when c_memory_access_16_bit =>
                        -- 16-bit access is a bit more complex because
                        -- I need to check the alignment.
                        -- On the other side when the alignment fits
                        -- I can simply copy the memory word at once.

                        -- check alignment
                        if mem_array_addr(0) /= '0'
                        then
                            l_alignment_error <= '1';
                            l_data <= x"00000000";
                        else
                            l_data <= x"0000" & r_mem_array(mem_array_index);
                            l_alignment_error <= '0';
                        end if;
                        l_data_valid <= '1';
                        l_status <= L_DONE;
                    when c_memory_access_32_bit =>
                        -- This is the most complex case.
                        -- I need to check the alignment
                        -- and the access is split over two cycles,
                        -- I need to store the memory word from this cycle in a register
                        -- for the next cycle which will concatenate the saved value
                        -- and the next memory word into the 32-bit output.

                        -- check alignment
                        if mem_array_addr(1 downto 0) /= b"00"
                        then
                            l_data_valid <= '1';
                            l_alignment_error <= '1';
                            l_data <= x"00000000";
                            l_status <= L_DONE;
                        else
                            l_status <= L_GET_FIRST_MEM_WORD;
                            l_out_word <= r_mem_array(mem_array_index);
                            l_mem_array_addr <= mem_array_addr(gen_addr_width-1 downto 2);
                            l_alignment_error <= '0';
                        end if;
                        l_read_addr_ready <= '1';
                end case;
            end if; -- if i_read_addr_valid
        end if;
    end process;

    process  ( i_clock) is
    begin
        if (rising_edge(i_clock))
        then
            -- simply copy the values over into the registers
            -- all logic happened in the combinatorical process above.
            o_reset_ready <= l_reset_ready;
            o_read_addr_ready <= l_read_addr_ready;
            r_data <= l_data;
            r_data_valid <= l_data_valid;
            r_alignment_error <= l_alignment_error;
            r_status <= l_status;
            r_mem_array_addr <= l_mem_array_addr;
            r_out_word <= l_out_word;
        end if;  -- if (rising_edge(i_clock))
    end process;


end rtl;
