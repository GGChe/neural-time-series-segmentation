library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity neo is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        spike_detected : out STD_LOGIC  -- Spike detection signal
    );
end neo;

architecture Behavioral of neo is
    -- State enumeration
    type state_type is (TRAINING, OPERATION);
    signal state       : state_type := TRAINING;

    -- Internal signals
    signal x1, x2, x3 : signed(15 downto 0) := (others => '0'); -- Delayed samples
    signal neo        : signed(15 downto 0) := (others => '0'); -- Absolute difference
    signal threshold  : signed(19 downto 0) := to_signed(10000, 20); -- Larger threshold

    -- Intermediate signals for wider calculations
    signal mult_x2_x2, mult_x3_x1 : signed(31 downto 0);
    signal diff_result            : signed(31 downto 0);

begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset signals
            x1 <= (others => '0');
            x2 <= (others => '0');
            x3 <= (others => '0');
            neo <= (others => '0');
            threshold <= to_signed(25000, threshold'length); -- Set a larger reset value
            state <= TRAINING;
            spike_detected <= '0';
        elsif rising_edge(clk) then
            -- Shift samples
            x1 <= x2;
            x2 <= x3;
            x3 <= signed(data_in);

            -- State machine
            case state is
                when TRAINING =>
                    threshold <= to_signed(25000, threshold'length);
                    state <= OPERATION;

                when OPERATION =>
                    -- Perform calculations
                    mult_x2_x2 <= x2 * x2;
                    mult_x3_x1 <= x3 * x1;
                    diff_result <= abs(mult_x2_x2 - mult_x3_x1);
                    neo <= resize(diff_result, neo'length);

                    -- Debug messages
                    report "x2*x2: " & integer'image(to_integer(mult_x2_x2)) severity NOTE;
                    report "x3*x1: " & integer'image(to_integer(mult_x3_x1)) severity NOTE;
                    report "NEO difference: " & integer'image(to_integer(diff_result)) severity NOTE;

                    -- Spike detection with resized neo
                    if resize(neo, threshold'length) > threshold then
                        spike_detected <= '1';
                        report "Spike detected!" severity WARNING;
                    else
                        spike_detected <= '0';
                    end if;

            end case;
        end if;
    end process;
end Behavioral;
