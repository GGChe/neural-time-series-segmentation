module neo (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output reg spike_detected
);

    localparam TRAINING = 1'b0;
    localparam OPERATION = 1'b1;

    reg state;
    reg signed [15:0] x1, x2, x3;
    reg signed [15:0] neo_val;
    reg signed [19:0] threshold;

    reg signed [31:0] mult_x2_x2;
    reg signed [31:0] mult_x3_x1;
    reg signed [31:0] diff_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x1 <= 16'd0;
            x2 <= 16'd0;
            x3 <= 16'd0;
            neo_val <= 16'd0;
            threshold <= 20'sd20000;
            state <= TRAINING;
            spike_detected <= 1'b0;
        end else begin
            x1 <= x2;
            x2 <= x3;
            x3 <= data_in;

            case (state)
                TRAINING: begin
                    threshold <= 20'sd20000;
                    state <= OPERATION;
                end

                OPERATION: begin
                    mult_x2_x2 <= x2 * x2;
                    mult_x3_x1 <= x3 * x1;
                    
                    if (mult_x2_x2 > mult_x3_x1)
                        diff_result <= mult_x2_x2 - mult_x3_x1;
                    else
                        diff_result <= mult_x3_x1 - mult_x2_x2;

                    neo_val <= diff_result[15:0]; // Resize

                    if (neo_val > threshold)
                        spike_detected <= 1'b1;
                    else
                        spike_detected <= 1'b0;
                end
            endcase
        end
    end

endmodule
