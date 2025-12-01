module i2s_rx_tb;
    parameter WIDTH = 16; 

    // Testbench signals
    logic sclk = 0; 
	logic sclk_out = 0;
    logic rst;
    logic ws_in;
	logic ws_out;
    logic sdata_in;
	logic sdata_out;
	

    // Wires to capture the DUT's output
    logic [WIDTH-1:0] left_chan;
    logic [WIDTH-1:0] right_chan;

    // Instantiate the Device Under Test (DUT)
I2Stx #(WIDTH) I2Stx0 (sclk, rst, ws_out, sdata_out, left_chan, right_chan);
I2Srx #(WIDTH) I2Srx0 (sclk, rst, ws_in, sdata_in, left_chan, right_chan);

    // Create a 10ns period clock
    always #5 sclk = ~sclk;

// Task that converts data to I2S format to test the rx module
task send_i2s_frame(
        input [WIDTH-1:0] left_data,
        input [WIDTH-1:0] right_data
    );
    begin
        // Send Left Channel (ws=0)
        @ (negedge sclk); // WS transition edge
        ws <= 0;
        

        // Now, send all bits for the left channel, MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata <= left_data[i];
			
			if (i == 0) begin // change Ws one cycle before the LSB
				ws <= 1;
			end
            @ (negedge sclk);
        end
        

        // Now, send all bits for the right channel, MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata <= right_data[i];
			if (i == 0) begin // change Ws one cycle before the LSB
				ws <= 0;
			end
            @ (negedge sclk);
        end
        
        // End of Frame 
        @ (negedge sclk); // WS transition edge
        ws <= 0;

    end
    endtask


    initial begin
        // Declarations for test vectors
        logic [WIDTH-1:0] test_left_1;
        logic [WIDTH-1:0] test_right_1;
        logic [WIDTH-1:0] test_left_2;
        logic [WIDTH-1:0] test_right_2;

        // Reset Phase 
        $display("Starting testbench...");
        rst = 1;    // Assert reset
        ws = 0;     // Initialize signals
        sdata = 0;
        #100;       
        rst = 0;    
        @ (posedge sclk); // Wait for one clock edge
        
        $display("Reset complete. Starting test cases...");

        // Test Case 1
        test_left_1  = 16'hDEAD;
        test_right_1 = 16'hBEEF;

        // Send the first frame
        send_i2s_frame(test_left_1, test_right_1);
        
        // Give a small delay for signals to propagate before checking
        #100;
		
        // Send the second frame
        send_i2s_frame(test_left_2, test_right_2);
        
        #100;

        // Verification 2
        if (left_chan == test_left_2 && right_chan == test_right_2) begin
            $display("Test 2 PASSED: L=0x%h, R=0x%h", left_chan, right_chan);
        end else begin
            $display("Test 2 FAILED: Expected L=0x%h, R=0x%h. Got L=0x%h, R=0x%h",
                       test_left_2, test_right_2, left_chan, right_chan);
        end

        // Finish Simulation
        #100;
        $display("All test cases complete. Finishing simulation.");
        $stop;

    end // end initial block

endmodule