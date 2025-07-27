library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity processing_unit is
    Port (
        clk                 : in  STD_LOGIC;
        rst                 : in  STD_LOGIC;
        data_in             : in  STD_LOGIC_VECTOR(15 downto 0);
        spike_detection     : out STD_LOGIC;
        event_out           : out INTEGER
    );
end processing_unit;

architecture Behavioral of processing_unit is

    -- Signal declarations
    signal spike_detected     : STD_LOGIC;
    
    -- Component declarations
    component neo is
        Port (
            clk            : in  STD_LOGIC;
            rst            : in  STD_LOGIC;
            data_in        : in  STD_LOGIC_VECTOR(15 downto 0);
            spike_detected : out STD_LOGIC  -- Spike detection signal
        );
    end component;
    
    component classify_event_unit is
        Port (
            clk                 : in  std_logic;
            reset               : in  std_logic;
            current_detection   : in  std_logic;
            event_out           : out integer  -- Encoded as: 0->C, 1->B, 2->A
        );
    end component;

begin

    -- Instantiate the neo spike detector
    neo_inst : neo
        Port map (
            clk            => clk,
            rst            => rst,
            data_in        => data_in,
            spike_detected => spike_detected
        );

    -- Instantiate the classify_event_unit
    classifier_inst : classify_event_unit
        Port map (
            clk                 => clk,
            reset               => rst,
            current_detection   => spike_detected,
            event_out           => event_out
        );

    -- Assign the internal spike_detected signal to the output port
    spike_detection <= spike_detected;

end Behavioral;
