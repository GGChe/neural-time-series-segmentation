module aso (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output reg spike_detected
);

    localparam TRAINING = 1'b0;
    localparam OPERATION = 1'b1;

    reg state;
    reg signed [15:0] x1, x2, x3;
    reg signed [15:0] abs_diff;
    reg signed [15:0] threshold;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x1 <= 16'd0;
            x2 <= 16'd0;
            x3 <= 16'd0;
            abs_diff <= 16'd0;
            threshold <= 16'sd500;
            state <= TRAINING;
            spike_detected <= 1'b0;
        end else begin
            x1 <= x2;
            x2 <= x3;
            x3 <= data_in;

            case (state)
                TRAINING: begin
                    threshold <= 16'sd100;
                    state <= OPERATION;
                end

                OPERATION: begin
                    if (x3 > x1)
                        abs_diff <= x3 - x1;
                    else
                        abs_diff <= x1 - x3;

                    if (abs_diff > threshold)
                        spike_detected <= 1'b1;
                    else
                        spike_detected <= 1'b0;
                end
            endcase
        end
    end

endmodule
