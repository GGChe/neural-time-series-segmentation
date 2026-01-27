module detectors_wrapper (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    output wire spike_neo,
    output wire spike_ado,
    output wire spike_aso,
    output wire spike_ed
);

    neo inst_neo (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_neo)
    );

    ado inst_ado (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_ado)
    );

    aso inst_aso (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_aso)
    );

    ed inst_ed (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .spike_detected(spike_ed)
    );
    

endmodule
