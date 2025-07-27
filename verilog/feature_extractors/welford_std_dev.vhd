library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity welford_variance is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0); -- 16-bit signed input
        variance_out  : out STD_LOGIC_VECTOR(31 downto 0); -- Output for variance (scaled)
        done          : out STD_LOGIC -- Indicates when variance computation is complete
    );
end welford_variance;

architecture Behavioral of welford_variance is
    -- Internal constants
    constant N : integer := 128; -- Number of samples for variance calculation
    constant SCALE_FACTOR : integer := 1000; -- Scaling factor for fixed-point arithmetic

    -- Signals
    signal k               : integer range 0 to N := 0; -- Sample count
    signal M               : signed(31 downto 0) := (others => '0'); -- Mean (scaled)
    signal Mnext           : signed(31 downto 0) := (others => '0'); -- Next mean (scaled)
    signal S               : signed(63 downto 0) := (others => '0'); -- Sum of squares (scaled)
    signal variance        : signed(63 downto 0) := (others => '0'); -- Sum of squares (scaled)
    signal delta           : signed(31 downto 0) := (others => '0'); -- x - M (scaled)
    signal delta2          : signed(31 downto 0) := (others => '0'); -- x - Mnext (scaled)
    signal x               : signed(15 downto 0); -- Converted input data
    signal computation_done: STD_LOGIC := '0';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all signals
            k               <= 0;
            M               <= (others => '0');
            Mnext           <= (others => '0');
            S               <= (others => '0');
            delta           <= (others => '0');
            delta2          <= (others => '0');
            computation_done<= '0';
            report "DUT Reset Activated: All internal signals reset." severity note;
        elsif rising_edge(clk) then
            if k < N then
                -- Convert input data to signed integer
                x <= signed(data_in);
                report "Sample " & integer'image(k + 1) & ": Received data_in = " & integer'image(to_integer(x)) severity note;

                -- Increment sample count
                k <= k + 1;
                report "Sample " & integer'image(k) & ": Incremented sample_count to " & integer'image(k) severity note;

                -- Calculate delta = x - M
                delta <= resize(x, 32) - resize(M, 32);
                report "Sample " & integer'image(k) & ": Delta (x - M) = " & integer'image(to_integer(delta)) severity note;

                -- Compute Mnext = M + (delta / k)
                -- To handle division, multiply delta by SCALE_FACTOR before division
                Mnext <= M + (resize(delta, 32) * to_signed(SCALE_FACTOR, 32)) / to_signed(k, 32);
                report "Sample " & integer'image(k) & ": Mnext = M + (delta / k) = " & integer'image(to_integer(Mnext)) severity note;

                -- Calculate delta2 = x - Mnext
                delta2 <= resize(x, 32) - resize(Mnext, 32);
                report "Sample " & integer'image(k) & ": Delta2 (x - Mnext) = " & integer'image(to_integer(delta2)) severity note;

                -- Update S = S + (delta * delta2) / SCALE_FACTOR
                -- To maintain scaling, divide the product by SCALE_FACTOR
                S <= S + (delta * delta2) / to_signed(SCALE_FACTOR, 32);
                report "Sample " & integer'image(k) & ": Updated sum_squares S = " & integer'image(to_integer(S)) severity note;

                -- Update M = Mnext
                M <= Mnext;
                report "Sample " & integer'image(k) & ": Updated mean M = " & integer'image(to_integer(M)) severity note;

                -- Check if computation is done
                if k = N then
                    computation_done <= '1';
                    report "All samples processed. computation_done set to '1'." severity note;
                end if;

            elsif computation_done = '1' then
                -- Finalize variance computation: variance = S / (k -1)
                variance <= S / to_signed(N - 1, 64);
                report "Final Variance Computation: Variance = " & integer'image(to_integer(variance)) severity note;

                -- Indicate computation is complete
                computation_done <= '0';
                report "Computation_done reset to '0'." severity note;
            end if;
        end if;
    end process;

    -- Outputs-------------------
    variance_out <= std_logic_vector(resize(variance(31 downto 0), variance_out'length)); -- Convert lower 32 bits
    done <= computation_done;

end Behavioral;
