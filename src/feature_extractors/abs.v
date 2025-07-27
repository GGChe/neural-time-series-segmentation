module feature_abs (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    output reg data_out
);

    reg signed [15:0] x1, x2, x3;
    reg signed [16:0] result;
    reg threshold_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x1 <= 16'd0;
            x2 <= 16'd0;
            x3 <= 16'd0;
            result <= 17'd0;
            threshold_result <= 1'b0;
        end else begin
            x1 <= x2;
            x2 <= x3;
            x3 <= $signed(data_in);

            result <= {1'b0, x3} - {1'b0, x1};

            if (result > $signed(17'd500)) begin
                threshold_result <= 1'b1;
            end else begin
                threshold_result <= 1'b0;
            end
        end
    end

    always @(*) begin
        data_out = threshold_result;
    end

endmodule
