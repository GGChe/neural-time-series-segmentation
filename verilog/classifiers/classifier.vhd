library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity classify_event_unit is
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;
        current_detection   : in  std_logic;
        event_out           : out integer
    );
end classify_event_unit;

architecture Behavioral of classify_event_unit is

    -- Enumerated type for events
    type Event_type is (C, B, A);
    signal event           : Event_type := C;
    signal previous_event  : Event_type := C;

    -- Constants
    constant SAMPLE_RATE                    : integer := 2000;
    constant MAX_EXCITABILITY               : integer := 100;
    constant SATURATION_EXCITABILITY        : integer := 10;
    constant CLASS_A_THRESHOLD              : integer := 5;
    constant CLASS_B_THRESHOLD              : integer := 1;
    constant ICTAL_REFRACTORY_PERIOD        : integer := 5 * SAMPLE_RATE;
    constant TIMEOUT_PERIOD                 : integer := 5 * SAMPLE_RATE;
    constant DECAY_STEP_PERIOD              : integer := SAMPLE_RATE / 2;
    constant COUNTER_CONFIRMATION_A_THRESH  : integer := 5;
    constant COUNTER_CONFIRMATION_B_THRESH  : integer := 1;

    -- Signals (Variables)
    signal excitability             : integer range 0 to SATURATION_EXCITABILITY * MAX_EXCITABILITY := 0;
    signal sample_count             : integer range 0 to integer'high := 0;
    signal last_peak_sample_count   : integer range 0 to integer'high := 0;
    signal last_event_sample_count  : integer range 0 to integer'high := 0;
    signal counter_confirmation_a   : integer range 0 to integer'high := 0;
    signal counter_confirmation_b   : integer range 0 to integer'high := 0;
    signal last_a_section_end       : integer range 0 to integer'high := 0;
    signal last_b_section_end       : integer range 0 to integer'high := 0;
    signal event_start              : integer range 0 to integer'high := 0;
    signal k                        : integer range 0 to integer'high := 0;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all signals
            excitability            <= 0;
            sample_count            <= 0;
            last_peak_sample_count  <= 0;
            last_event_sample_count <= 0;
            event                   <= C;
            previous_event          <= C;
            counter_confirmation_a  <= 0;
            counter_confirmation_b  <= 0;
            last_a_section_end      <= 0;
            last_b_section_end      <= 0;
            event_start             <= 0;
            event_out               <= 0;
        elsif rising_edge(clk) then
            -- Update sample count
            sample_count <= sample_count + 1;

            -- Update excitability based on current detection
            if current_detection = '1' then
                excitability <= excitability + MAX_EXCITABILITY;
                if excitability > (SATURATION_EXCITABILITY * MAX_EXCITABILITY) then
                    excitability <= SATURATION_EXCITABILITY * MAX_EXCITABILITY;
                end if;
                last_event_sample_count  <= sample_count;
                last_peak_sample_count   <= sample_count;
            else
                k <= sample_count - last_peak_sample_count;
                -- Implement step decay function
                if k >= DECAY_STEP_PERIOD then
                    excitability <= 0;
                else
                    -- Keep excitability constant within the decay period
                    excitability <= excitability;
                end if;
            end if;

            -- Handle timeout to revert to Event C
            if (sample_count - last_event_sample_count) > TIMEOUT_PERIOD then
                event <= C;
            end if;

            -- Event Classification based on excitability levels
            if excitability >= (CLASS_A_THRESHOLD * MAX_EXCITABILITY) then
                -- Class A Event Detection
                counter_confirmation_a <= counter_confirmation_a + 1;
                if counter_confirmation_a > COUNTER_CONFIRMATION_A_THRESH then
                    if event /= A then
                        previous_event <= event;
                        event_start    <= sample_count;
                    end if;
                    event <= A;
                end if;
            elsif excitability >= (CLASS_B_THRESHOLD * MAX_EXCITABILITY) then
                -- Class B Event Detection
                if (event /= B) and ((sample_count - last_a_section_end) > ICTAL_REFRACTORY_PERIOD) then
                    previous_event <= event;
                    event          <= B;
                    event_start    <= sample_count;
                else
                    counter_confirmation_b <= counter_confirmation_b + 1;
                    -- Additional logic can be placed here if necessary
                end if;
            else
                -- Gradual decay towards Event C
                if (event = A) and ((sample_count - last_a_section_end) > ICTAL_REFRACTORY_PERIOD) then
                    if excitability > (CLASS_B_THRESHOLD * MAX_EXCITABILITY) then
                        -- Transition to Event B while decaying excitability
                        event <= B;
                    else
                        -- Transition to Event C when excitability is sufficiently low
                        event <= C;
                    end if;
                else
                    if previous_event /= C then
                        -- Reset confirmation counters
                        counter_confirmation_a <= 0;
                        counter_confirmation_b <= 0;

                        -- Update section end counts based on current event
                        if event = B then
                            last_b_section_end <= sample_count;
                        elsif event = A then
                            last_a_section_end <= sample_count;
                        end if;
                        previous_event <= event;
                    end if;
                    event <= C;
                end if;
            end if;

            -- Output the event as encoded std_logic_vector
            case event is
                when A =>
                    event_out <= 2;
                when B =>
                    event_out <= 1;
                when others =>
                    event_out <= 0;  -- Event C
            end case;

        end if;
    end process;

end Behavioral;
