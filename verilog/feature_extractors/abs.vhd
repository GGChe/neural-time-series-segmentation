library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neo is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        data_in  : in  STD_LOGIC_VECTOR(15 downto 0);
        data_out : out STD_LOGIC  -- Single-bit output: '1' or '0'
    );
end neo;

architecture Behavioral of neo is
    signal x1, x2, x3 : unsigned(15 downto 0) := (others => '0');
    signal result     : signed(16 downto 0) := (others => '0');
    signal threshold_result : boolean := false;  -- Internal boolean signal
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Initialize all signals during reset
            x1 <= (others => '0');
            x2 <= (others => '0');
            x3 <= (others => '0');
            result <= (others => '0');
            threshold_result <= false;
        elsif rising_edge(clk) then
            -- Shift inputs for difference computation
            x1 <= x2;
            x2 <= x3;
            x3 <= unsigned(data_in);

            -- Compute the signed difference
            result <= signed('0' & x3) - signed('0' & x1);

            -- Compare result with 500 and store in boolean signal
            if result > to_signed(500, result'length) then
                threshold_result <= true;
            else
                threshold_result <= false;
            end if;
        end if;
    end process;

    -- Assign the boolean result to the output as STD_LOGIC
    data_out <= '1' when threshold_result = true else '0';

end Behavioral;
