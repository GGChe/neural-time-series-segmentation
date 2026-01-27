`timescale 1ns / 1ps

module classifier_tb;

    reg clk;
    reg rst;
    reg signed [15:0] data_in;
    
    wire [31:0] event_out;

    integer data_file;
    integer scan_file;
    integer sample_count;
    integer int_in;

    top_level_module uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .event_out(event_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus
    initial begin
        rst = 1;
        data_in = 0;
        sample_count = 0;

        #50;
        rst = 0;

        data_file = $fopen("20170224_slice02_04_CTRL2_0005_17_int_downsampled_chunk_int16.txt", "r");
        if (data_file == 0) begin
            $display("Error opening data file");
            $finish;
        end

        while (!$feof(data_file) && sample_count < 20000) begin
            scan_file = $fscanf(data_file, "%d\n", int_in);
            data_in = int_in;
            
            if (sample_count % 5000 == 0) begin
                $display("Processed: %d", sample_count);
            end

            sample_count = sample_count + 1;
            @(posedge clk);
        end

        $display("Simulation Finished");
        $fclose(data_file);
        
        #1000;
        $finish;
    end

    // Waveform dump for Icarus Verilog
    initial begin
        $dumpfile("classifier.vcd");
        $dumpvars(0, classifier_tb);
    end

endmodule
