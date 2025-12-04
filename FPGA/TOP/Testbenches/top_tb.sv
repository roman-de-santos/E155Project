`timescale 1ns / 1ps

module top_tb ();

localparam WIDTH = 16;
localparam TEST_BUF_DEPTH = 90;
localparam TEST_AVG_DELAY = 2;

// Module Signals
logic sclk_i = 1'b1;
logic rst_n_i = 1'b0;
logic ws_i;
logic sdata_i;
logic [3:0] freqSetting_i;
logic [3:0] scaleFactor_i;
logic sclk_o;
logic ws_o;
logic sdata_o;
logic errorLED;
logic rstI2S_n;

// I2S test cases
logic [WIDTH-1:0] testLeft1, testRight1, testLeft2, testRight2;

// Test bench signals
int test_num = 0;
int packets_sent = 0; 

// I2S period (44.1kHz)
localparam sclkTs = 709;

// Import dummy packets array
import packets_array_pkg::*;
packets_array_t packets_array;

// Generate I2S clock
always begin
    #sclkTs 
    sclk_i <= ~sclk_i;
end

// Instantiate modules	
top #(
	.PKT_WIDTH(WIDTH),			// Must be 16
	.BUF_DEPTH(TEST_BUF_DEPTH),
	.AVG_DELAY(TEST_AVG_DELAY)
) dut (
	.sclk_i         (sclk_i),
	.rst_n_i        (rst_n_i),
	.ws_i           (ws_i),
	.sdata_i        (sdata_i),
	.freqSetting_i  (freqSetting_i),
	.scaleFactor_i  (scaleFactor_i),
	.sclk_o         (sclk_o),
	.ws_o           (ws_o),
	.sdata_o        (sdata_o),
	.errorLED       (errorLED),
	.rstI2S_n       (rstI2S_n)
);

// I2S bitstream generating task
task send_i2s_frame(
        input [WIDTH-1:0] left_data,
        input [WIDTH-1:0] right_data
    );
    begin
		packets_sent++;
        // Send Left Channel (ws=0)
        @ (negedge sclk_i); // WS transition edge
        ws_i <= 0;
        

        // Now, send all bits for the left channel, MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata_i <= left_data[i];
			
			if (i == 0) begin // change Ws one cycle before the LSB
				ws_i <= 1;
			end
            @ (negedge sclk_i);
        end
        

        // Now, send all bits for the right channel, MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata_i <= right_data[i];
			if (i == 0) begin // change Ws one cycle before the LSB
				ws_i <= 0;
			end
            @ (negedge sclk_i);
        end
        
        // End of Frame 
        @ (negedge sclk_i); // WS transition edge
        ws_i <= 0;

    end
    endtask

	task automatic wait_cycles(input int num_cycles);
        repeat (num_cycles) @(posedge sclk_i);
    endtask

	task automatic reset_dut;
        $display("Resetting DUT...");
        rst_n_i <= 1'b0;
        ws_i <= '0;
		sdata_i <= '0;
		freqSetting_i <= '0;
		scaleFactor_i <= '0;

        packets_sent <= '0;

        wait_cycles(3);
        rst_n_i <= 1'b1;
        wait_cycles(2);
    endtask

// Test data transfer
initial begin
		// Dummy packets
		packets_array = CONST_DATA_ARRAY;

		// Test settings
		freqSetting_i = 4'b0001;
		scaleFactor_i = 4'b0001;  
        
		$display("Starting testbench...");
        reset_dut();
        $display("Reset complete. Starting test cases...");

        // Test Case 1
		begin
			$display("Beginning test 1: two left & right packets");	
			test_num = 1;

			send_i2s_frame(16'h0AAA, 16'h0BBB);
			wait_cycles(25); // Give a delay for signals to propagate

			send_i2s_frame(16'h0CCC, 16'h0DDD);
			wait_cycles(25);

			send_i2s_frame(16'h0EEE, 16'h0FFF);
			wait_cycles(25);
		end

		
		// Test Case 2
		begin
			automatic int num_packets = 10;
			$display("Beginning test 2: multiple packets");
			test_num = 2;
			
			reset_dut();

			// Send the right packets
			for (int i = 0; i < num_packets; i++) begin
					send_i2s_frame(16'hxxxx, packets_array[i]);

					wait_cycles(50);
				end
		end
        
		// Give a delay for signals to propagate before checking
		wait_cycles(50);
		$stop();
end

endmodule