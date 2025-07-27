----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2024 03:31:33 PM
-- Design Name: 
-- Module Name: ed - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ed is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        spike_detected : out STD_LOGIC  -- Spike detection signal
    );
end ed;

architecture Behavioral of ed is
    -- Generic for delay k (you can adjust k as needed)
    constant k : integer := 2;  -- Example: delay by 2 samples

    -- State enumeration
    type state_type is (TRAINING, OPERATION);
    signal state       : state_type := TRAINING;

    -- Internal signals
    type buffer_type is array (0 to k) of signed(15 downto 0); -- Shift register for delayed samples
    signal input_buffer : buffer_type := (others => (others => '0'));
    signal squared_diff : signed(31 downto 0) := (others => '0'); -- To store squared difference
    signal threshold     : signed(31 downto 0) := to_signed(500, 32); -- Larger threshold for squared values
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset signals
            input_buffer <= (others => (others => '0'));
            squared_diff <= (others => '0');
            threshold <= to_signed(500, 32); -- Default threshold
            state <= TRAINING;
            spike_detected <= '0';
        elsif rising_edge(clk) then
            -- Shift samples in the buffer
            for i in k downto 1 loop
                input_buffer(i) <= input_buffer(i - 1);
            end loop;
            input_buffer(0) <= signed(data_in); -- Load the newest sample

            -- State machine
            case state is
                when TRAINING =>
                    -- Training: set threshold and transition to OPERATION
                    threshold <= to_signed(10000, 32); -- Adjust threshold as needed
                    state <= OPERATION;

                when OPERATION =>
                    -- Calculate squared difference
                    squared_diff <= (input_buffer(0) - input_buffer(k)) * (input_buffer(0) - input_buffer(k));

                    -- Compare with threshold to detect spike
                    if squared_diff > threshold then
                        spike_detected <= '1';
                    else
                        spike_detected <= '0';
                    end if;

            end case;
        end if;
    end process;

end Behavioral;
