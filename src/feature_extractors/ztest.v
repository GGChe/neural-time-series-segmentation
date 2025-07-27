module ztest (
    input wire clk,
    input wire rst,
    input wire signed [15:0] data_in,
    output reg [31:0] mean_out,
    output reg spike_detected
);

    parameter TRAINING_SAMPLES = 128;

    // States
    localparam TRAINING_ACCUMULATE = 2'd0;
    localparam TRAINING_FINISHED = 2'd1;
    localparam OPERATION = 2'd2;

    reg [1:0] state;
    
    // Circular buffer
    reg signed [15:0] data_buffer [0:TRAINING_SAMPLES-1];
    
    reg signed [31:0] sum;
    reg signed [31:0] mean;
    reg signed [31:0] variance;
    reg signed [31:0] stddev;
    
    integer index;
    integer sample_count;
    
    reg signed [15:0] neo;
    reg signed [31:0] threshold;
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= TRAINING_ACCUMULATE;
            sum <= 32'd0;
            mean <= 32'd0;
            mean_out <= 32'd0;
            index <= 0;
            sample_count <= 0;
            
            for (i = 0; i < TRAINING_SAMPLES; i = i + 1) begin
                data_buffer[i] <= 16'd0;
            end
            
            neo <= 16'd0;
            spike_detected <= 1'b0;
            threshold <= 32'sd10000;
            
        end else begin
            case (state)
                TRAINING_ACCUMULATE: begin
                    if (sample_count < TRAINING_SAMPLES) begin
                        data_buffer[sample_count] <= data_in;
                        sum <= sum + data_in;
                        sample_count <= sample_count + 1;
                    end
                    
                    if (sample_count == TRAINING_SAMPLES) begin
                        state <= TRAINING_FINISHED;
                    end
                end
                
                TRAINING_FINISHED: begin
                    mean <= sum >>> 7; // Arithmetic right shift
                    mean_out <= (sum >>> 7);
                    state <= OPERATION;
                end
                
                OPERATION: begin
                    sum <= sum - data_buffer[index] + data_in;
                    mean <= (sum - data_buffer[index] + data_in) >>> 7;
                    mean_out <= (sum - data_buffer[index] + data_in) >>> 7;
                    
                    data_buffer[index] <= data_in;
                    index <= (index + 1) % TRAINING_SAMPLES;
                    
                    // Spike detection
                    if (data_in > mean)
                        neo <= data_in - mean;
                    else
                        neo <= mean - data_in;
                    
                    if (neo > threshold)
                        spike_detected <= 1'b1;
                    else
                        spike_detected <= 1'b0;
                end
            endcase
        end
    end

endmodule
