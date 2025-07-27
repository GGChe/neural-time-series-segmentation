module welford_variance (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output wire [31:0] variance_out,
    output wire done
);

    parameter N = 128;
    parameter SCALE_FACTOR = 1000;

    integer k;
    reg signed [31:0] M;
    reg signed [31:0] Mnext;
    reg signed [63:0] S;
    reg signed [63:0] variance;
    reg signed [31:0] delta;
    reg signed [31:0] delta2;
    reg signed [15:0] x;
    reg computation_done;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            k <= 0;
            M <= 32'd0;
            Mnext <= 32'd0;
            S <= 64'd0;
            delta <= 32'd0;
            delta2 <= 32'd0;
            variance <= 64'd0;
            computation_done <= 1'b0;
        end else begin
            if (k < N) begin
                x <= data_in;

                k <= k + 1;

                delta <= {{16{x[15]}}, x} - M;

                // Mnext depends on M and delta.
                Mnext <= M + (delta * $signed(SCALE_FACTOR)) / $signed(k); 

                delta2 <= {{16{x[15]}}, x} - Mnext;
                
                S <= S + (delta * delta2) / $signed(SCALE_FACTOR);
                
                M <= Mnext;
                
                if (k == N) begin
                    computation_done <= 1'b1;
                end

            end else if (computation_done) begin
                variance <= S / $signed(N - 1);
                computation_done <= 1'b0;
            end
        end
    end

    assign variance_out = variance[31:0];
    assign done = computation_done;

endmodule
