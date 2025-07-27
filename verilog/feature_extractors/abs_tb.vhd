library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity neo_tb is
end neo_tb;

architecture Behavioral of neo_tb is
    signal clk      : STD_LOGIC := '0';
    signal rst      : STD_LOGIC := '1';
    signal data_in  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal data_out : STD_LOGIC;
begin

    -- Instantiate the DUT (neo module)
    uut: entity work.neo
        Port Map (
            clk      => clk,
            rst      => rst,
            data_in  => data_in,
            data_out => data_out
        );

    -- Clock Generation
    clk_process : process
    begin
        while True loop
            clk <= '0';
            wait for 10 ns; -- Half clock period
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Stimulus Process
    stim_proc: process
        file data_file   : text open read_mode is "20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt"; -- Ensure the file contains integers
        variable row     : line;
        variable int_in  : integer;
    begin
        -- Wait for global reset to finish
        wait for 50 ns;
        rst <= '0';

        -- Read and apply data from the file
        while not endfile(data_file) loop
            readline(data_file, row);
            -- Read the line as an integer
            read(row, int_in);

            -- Convert the integer to STD_LOGIC_VECTOR
            data_in <= std_logic_vector(to_unsigned(int_in, data_in'length));

            -- Debug message
            report "Read integer: " & integer'image(int_in);

            wait until rising_edge(clk); -- Synchronize with clock
        end loop;

        -- End simulation after all data is read
        wait;
    end process;

end Behavioral;
