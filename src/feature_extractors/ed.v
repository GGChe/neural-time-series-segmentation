module ed (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output reg spike_detected
);

    parameter k_delay = 2;

    localparam TRAINING = 1'b0;
    localparam OPERATION = 1'b1;

    reg state;
    reg signed [15:0] input_buffer [0:k_delay];
    reg signed [31:0] squared_diff;
    reg signed [31:0] threshold;
    
    wire signed [31:0] diff = $signed({{16{input_buffer[0][15]}}, input_buffer[0]}) - $signed({{16{input_buffer[k_delay][15]}}, input_buffer[k_delay]});
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<=k_delay; i=i+1) begin
                input_buffer[i] <= 16'd0;
            end
            squared_diff <= 32'd0;
            threshold <= 32'sd500;
            state <= TRAINING;
            spike_detected <= 1'b0;
        end else begin
            // Shift buffer
            for (i=k_delay; i>=1; i=i-1) begin
                input_buffer[i] <= input_buffer[i-1];
            end
            input_buffer[0] <= data_in;

            case (state)
                TRAINING: begin
                    threshold <= 32'sd10000;
                    state <= OPERATION;
                end

                OPERATION: begin
                    squared_diff <= diff * diff;

                    if (squared_diff > threshold)
                        spike_detected <= 1'b1;
                    else
                        spike_detected <= 1'b0;
                end
            endcase
        end
    end

endmodule
