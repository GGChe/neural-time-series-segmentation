library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity ztest is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        data_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        mean_out      : out STD_LOGIC_VECTOR(31 downto 0); -- Output for mean
        spike_detected : out STD_LOGIC  -- Spike detection signal
    );
end ztest;

architecture Behavioral of ztest is
    -- State enumeration
    type state_type is (TRAINING_ACCUMULATE, TRAINING_FINISHED, OPERATION);
    signal state       : state_type := TRAINING_ACCUMULATE;

    -- Internal constants
    constant TRAINING_SAMPLES : integer := 128; -- Must be a power of 2 for bit-shifting

    -- Type declaration for circular buffer
    type buffer_type is array (0 to TRAINING_SAMPLES - 1) of signed(15 downto 0);

    -- Internal signals
    signal data_buffer : buffer_type := (others => (others => '0')); -- Circular buffer
    signal sum          : signed(31 downto 0) := (others => '0');     -- Accumulated sum
    signal mean         : signed(31 downto 0) := (others => '0');     -- Calculated mean
    signal variance     : signed(31 downto 0) := (others => '0');     -- Calculated variance
    signal stddev       : signed(31 downto 0) := (others => '0');     -- Calculated standard deviation
    signal index        : integer range 0 to TRAINING_SAMPLES - 1 := 0; -- Circular buffer index
    signal sample_count : integer range 0 to TRAINING_SAMPLES := 0;   -- Counter for training stage
    signal neo          : signed(15 downto 0) := (others => '0');     -- For spike detection
    signal threshold    : signed(31 downto 0) := to_signed(10000, 32); -- Default threshold
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all signals
            state <= TRAINING_ACCUMULATE;
            sum <= (others => '0');
            mean <= (others => '0');
            mean_out <= (others => '0'); -- Reset mean_out
            index <= 0;
            sample_count <= 0;

            -- Reset data_buffer with a loop
            for i in 0 to TRAINING_SAMPLES - 1 loop
                data_buffer(i) <= (others => '0');
            end loop;

            neo <= (others => '0');
            spike_detected <= '0';
            report "System reset. All signals reset to default values." severity NOTE;

        elsif rising_edge(clk) then
            case state is
                                when TRAINING_ACCUMULATE =>
                    -- Accumulate the first 128 samples
                    if sample_count < TRAINING_SAMPLES then
                        data_buffer(sample_count) <= signed(data_in); -- Store sample
                        sum <= sum + signed(data_in); -- Update sum
                        sample_count <= sample_count + 1;

                        report "TRAINING_ACCUMULATE: Sample Count = " & integer'image(sample_count) &
                               ", Current Sum = " & integer'image(to_integer(sum)) &
                               ", Current Data In = " & integer'image(to_integer(signed(data_in))) severity NOTE;
                    end if;

                    -- Check if training is complete
                    if sample_count = TRAINING_SAMPLES then
                        report "Transition to TRAINING_FINISHED: Final Sum = " & integer'image(to_integer(sum)) &
                               ", Sample Count = " & integer'image(sample_count) severity NOTE;
                        state <= TRAINING_FINISHED;
                    end if;

                when TRAINING_FINISHED =>
                    -- Calculate the mean using bit shift
                    mean <= sum srl 7; -- Right shift by 7 is equivalent to division by 128
                    mean_out <= std_logic_vector(mean); -- Correct conversion
                    report "TRAINING_FINISHED: Calculated Mean = " & integer'image(to_integer(mean)) &
                           ", Final Sum = " & integer'image(to_integer(sum)) severity NOTE;

                    -- Transition to OPERATION state
                    state <= OPERATION;

                when OPERATION =>
                    -- Subtract the sample leaving the buffer, add the new sample, and recalculate the mean
                    sum <= sum - data_buffer(index) + signed(data_in);
                    mean <= sum srl 7; -- Update mean using bit shift
                    mean_out <= std_logic_vector(mean); -- Continuously update mean_out
                
                    -- Update the circular buffer
                    data_buffer(index) <= signed(data_in);
                    index <= (index + 1) mod TRAINING_SAMPLES;
                
                    -- Spike detection logic
                    neo <= resize(abs(signed(data_in) - mean), neo'length);
                    if neo > threshold then
                        spike_detected <= '1';
                        report "Spike detected!" severity WARNING;
                    else
                        spike_detected <= '0';
                    end if;
                    report "Spike Detection: Data In = " & integer'image(to_integer(signed(data_in))) &
                           ", Mean = " & integer'image(to_integer(mean)) &
                           ", NEO = " & integer'image(to_integer(neo)) severity NOTE;
            end case;
        end if;
    end process;

end Behavioral;
