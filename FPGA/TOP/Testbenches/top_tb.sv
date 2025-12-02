`timescale 1ns / 1ps

module top_tb ();

localparam WIDTH = 16;

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
logic test_num = 0;

// Clock gen (44.1kHz)
localparam sclkTs = 709;

always begin
    #sclkTs 
    sclk_i <= ~sclk_i;
end

// Reset
initial begin
    #100 rst_n_i = 0;
end

// Instantiate modules
top dut (
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

// Test data transfer
initial begin
	// Reset Phase 
        $display("Starting testbench...");
        rst_n_i = 0;    // Assert reset
        ws_i = 0;     // Initialize signals
        sdata_i = 0;
        #100;       
        rst_n_i = 1;  

		// Test different settings
		freqSetting_i = 4'b0001;
		scaleFactor_i = 4'b0001;  

        @ (posedge sclk_i); // Wait for one clock edge
        
        $display("Reset complete. Starting test cases...");

        // Test Case 1
		test_num = 1;
        testLeft1  = 16'h0DAD;
        testRight1 = 16'h0BEF;

        // Send the first frame
        send_i2s_frame(testLeft1, testRight1);
        
        // Give a delay for signals to propagate before checking
        #(sclkTs*100);

		// Test Case 2
		test_num = 2;
        testLeft2  = 16'h0AAA;
        testRight2 = 16'h0BBB;
		
        // Send the second frame
        send_i2s_frame(testLeft2, testRight2);
        
		// Give a delay for signals to propagate before checking
		#(sclkTs*100)
		$stop();
end

endmodule