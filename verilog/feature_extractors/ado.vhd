----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2024 11:22:17 AM
-- Design Name: 
-- Module Name: ado - Behavioral
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

entity ado is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        spike_detected : out STD_LOGIC  -- Spike detection signal
    );
end ado;


architecture Behavioral of ado is
    -- State enumeration
    type state_type is (TRAINING, OPERATION);
    signal state       : state_type := TRAINING;

    -- Internal signals
    signal x1, x2, x3, x4 : signed(15 downto 0) := (others => '0'); -- Delayed samples
    signal ado   : signed(15 downto 0) := (others => '0'); -- Absolute difference
    signal threshold  : signed(15 downto 0) := to_signed(500, 16); -- Fixed threshold
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset signals
            x1 <= (others => '0');
            x2 <= (others => '0');
            x3 <= (others => '0');
            x4 <= (others => '0');
            ado <= (others => '0');
            threshold <= to_signed(500, 16);
            state <= TRAINING;
            spike_detected <= '0';
        elsif rising_edge(clk) then
            -- Shift samples
            x1 <= x2;
            x2 <= x3;
            x3 <= x4;
            x4 <= signed(data_in);

            -- State machine
            case state is
                when TRAINING =>
                    -- Training: set threshold (fixed at 500) and transition to OPERATION
                    threshold <= to_signed(100, 16);
                    state <= OPERATION;

                when OPERATION =>
                    ado <= abs(x4 - x1);
                    if ado > threshold then
                        spike_detected <= '1';
                    else
                        spike_detected <= '0';
                    end if;

            end case;
        end if;
    end process;
end Behavioral;