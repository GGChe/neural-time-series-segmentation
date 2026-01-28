module classify_event_unit (
    input wire clk,
    input wire reset,
    input wire current_detection,
    output reg [31:0] event_out
);

    // Event types
    localparam EVENT_C = 2'd0;
    localparam EVENT_B = 2'd1;
    localparam EVENT_A = 2'd2;

    reg [1:0] event_state;
    reg [1:0] previous_event;

    // Constants
    parameter SAMPLE_RATE = 2000;
    parameter MAX_EXCITABILITY = 100;
    parameter SATURATION_EXCITABILITY = 10;
    parameter CLASS_A_THRESHOLD = 5;
    parameter CLASS_B_THRESHOLD = 1;
    parameter ICTAL_REFRACTORY_PERIOD = 5 * SAMPLE_RATE;
    parameter TIMEOUT_PERIOD = 5 * SAMPLE_RATE;
    parameter DECAY_STEP_PERIOD = SAMPLE_RATE / 2;
    parameter COUNTER_CONFIRMATION_A_THRESH = 5;
    parameter COUNTER_CONFIRMATION_B_THRESH = 1;

    integer excitability;
    integer sample_count;
    integer last_peak_sample_count;
    integer last_event_sample_count;
    integer counter_confirmation_a;
    integer counter_confirmation_b;
    integer last_a_section_end;
    integer last_b_section_end;
    integer event_start;
    integer k;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            excitability <= 0;
            sample_count <= 0;
            last_peak_sample_count <= 0;
            last_event_sample_count <= 0;
            event_state <= EVENT_C;
            previous_event <= EVENT_C;
            counter_confirmation_a <= 0;
            counter_confirmation_b <= 0;
            last_a_section_end <= 0;
            last_b_section_end <= 0;
            event_start <= 0;
            event_out <= 0;
        end else begin
            sample_count <= sample_count + 1;

            if (current_detection) begin
                if ((excitability + MAX_EXCITABILITY) > (SATURATION_EXCITABILITY * MAX_EXCITABILITY))
                    excitability <= (SATURATION_EXCITABILITY * MAX_EXCITABILITY);
                else
                    excitability <= excitability + MAX_EXCITABILITY;

                last_event_sample_count <= sample_count;
                last_peak_sample_count <= sample_count;
            end else begin
                // k update handled by non-blocking assignment below
                // In VHDL logic:
                // k <= sample_count - last_peak_sample_count;
                // if k >= DECAY_STEP_PERIOD (this uses OLD k)
                // Actually VHDL code: `k <= ...` then `if k >= ...` in same process.
                // VHDL `if` uses OLD `k`.
                // So here in Verilog, I should use `k_reg` or carefully structure it.
                // But `last_peak_sample_count` is updated in `current_detection` branch.
                // In `else`, we read `sample_count` and `last_peak_sample_count`.
                // Let's rely on standard sequential update logic of Verilog registers.
                // k here is just temporary for calc. But VHDL used a signal, meaning delay.
                // `k <= sample_count - last_peak...` implies k updates at end of cycle.
                // `if k >= ...` checks k from PREVIOUS cycle.
                // I will use a separate register for k to replicate this delay properly.
                // Although, maybe it wasn't intended. But I strictly follow code.
                // Wait, if I declare appropriate reg k outside, it will hold value.
            end
            
            // Re-implement k to match VHDL signal behavior
            // k is updated every cycle? No, only in else branch in VHDL?
            // "k <= sample_count - last_peak_sample_count;" is inside "else" of "if current_detection".
            // So k holds old value if current_detection is true?
            // Yes.
            
            // Logic for k update in Verilog (simulating VHDL signal):
            if (!current_detection)
                 k <= sample_count - last_peak_sample_count;
            
            // Logic for excitability decay uses OLD k (from prev cycle)
            if (!current_detection) begin
                if (k >= DECAY_STEP_PERIOD)
                    excitability <= 0;
                else
                    excitability <= excitability; // Hold
            end

            // Timeout
            if ((sample_count - last_event_sample_count) > TIMEOUT_PERIOD) begin
                event_state <= EVENT_C;
            end

            // Classification
            if (excitability >= (CLASS_A_THRESHOLD * MAX_EXCITABILITY)) begin
                counter_confirmation_a <= counter_confirmation_a + 1;
                if (counter_confirmation_a > COUNTER_CONFIRMATION_A_THRESH) begin
                    if (event_state != EVENT_A) begin
                        previous_event <= event_state;
                        event_start <= sample_count;
                    end
                    event_state <= EVENT_A;
                end
            end else if (excitability >= (CLASS_B_THRESHOLD * MAX_EXCITABILITY)) begin
                if ((event_state != EVENT_B) && ((sample_count - last_a_section_end) > ICTAL_REFRACTORY_PERIOD)) begin
                    previous_event <= event_state;
                    event_state <= EVENT_B;
                    event_start <= sample_count;
                end else begin
                    counter_confirmation_b <= counter_confirmation_b + 1;
                end
            end else begin
                if ((event_state == EVENT_A) && ((sample_count - last_a_section_end) > ICTAL_REFRACTORY_PERIOD)) begin
                    if (excitability > (CLASS_B_THRESHOLD * MAX_EXCITABILITY))
                        event_state <= EVENT_B;
                    else
                        event_state <= EVENT_C;
                end else begin
                    if (previous_event != EVENT_C) begin
                        counter_confirmation_a <= 0;
                        counter_confirmation_b <= 0;
                        if (event_state == EVENT_B)
                            last_b_section_end <= sample_count;
                        else if (event_state == EVENT_A)
                            last_a_section_end <= sample_count;
                        previous_event <= event_state;
                    end
                    event_state <= EVENT_C;
                end
            end

            // Output
            case (event_state)
                EVENT_A: event_out <= 2;
                EVENT_B: event_out <= 1;
                default: event_out <= 0;
            endcase
            
        end
    end

endmodule
