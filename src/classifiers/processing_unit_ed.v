module processing_unit_ed (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    output wire spike_detection,
    output wire [31:0] event_out
);

    wire spike_detected_sig;

    // Note: VHDL code instantiated 'neo', so we instantiate 'neo' here too.
    neo neo_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_detected_sig)
    );

    classify_event_unit classifier_inst (
        .clk(clk),
        .reset(rst),
        .current_detection(spike_detected_sig),
        .event_out(event_out)
    );

    assign spike_detection = spike_detected_sig;

endmodule
