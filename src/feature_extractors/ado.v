module ado (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output reg spike_detected
);

    localparam TRAINING = 1'b0;
    localparam OPERATION = 1'b1;

    reg state;
    reg signed [15:0] x1, x2, x3, x4;
    reg signed [15:0] ado_val;
    reg signed [15:0] threshold;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x1 <= 16'd0;
            x2 <= 16'd0;
            x3 <= 16'd0;
            x4 <= 16'd0;
            ado_val <= 16'd0;
            threshold <= 16'sd500;
            state <= TRAINING;
            spike_detected <= 1'b0;
        end else begin
            x1 <= x2;
            x2 <= x3;
            x3 <= x4;
            x4 <= data_in;

            case (state)
                TRAINING: begin
                    threshold <= 16'sd100;
                    state <= OPERATION;
                end

                OPERATION: begin
                    if (x4 > x1)
                        ado_val <= x4 - x1;
                    else
                        ado_val <= x1 - x4;

                    if (ado_val > threshold)
                        spike_detected <= 1'b1;
                    else
                        spike_detected <= 1'b0;
                end
            endcase
        end
    end

endmodule
