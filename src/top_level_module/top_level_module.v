module top_level_module (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    output wire [31:0] event_out
);

    wire spike_neo_sig;


    neo inst_neo (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_neo_sig)
    );

    classify_event_unit inst_classifier (
        .clk(clk),
        .reset(rst),
        .current_detection(spike_neo_sig),
        .event_out(event_out)
    );

endmodule
