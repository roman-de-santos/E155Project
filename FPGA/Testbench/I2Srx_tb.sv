module i2s_rx_tb;

    // Use the same parameter as the DUT
    parameter AUDIO_DW = 16;

    // Testbench signals
    logic sclk = 0; // Initialize clock to 0
    logic rst;
    logic ws;
    logic sdata;

    // Wires to capture the DUT's output
    logic [AUDIO_DW-1:0] left_chan;
    logic [AUDIO_DW-1:0] right_chan;

    // Instantiate the Device Under Test (DUT)
    i2s_rx #(
        .AUDIO_DW(AUDIO_DW)
    ) dut (
        .sclk(sclk),
        .rst(rst),
        .ws(ws),
        .sdata(sdata),
        .left_chan(left_chan),
        .right_chan(right_chan)
    );

    // Create a 10ns period clock (100MHz)
    always #5 sclk = ~sclk;

    // Task to send a complete I2S frame (Left + Right)

    task send_i2s_frame(
        input [AUDIO_DW-1:0] left_data,
        input [AUDIO_DW-1:0] right_data
    );
    begin
        // Send Left Channel (ws=0)
        ws <= 0;
        @ (posedge sclk); // WS transition edge

        // I2S standard: data is valid 1 clock *after* WS change
        @ (posedge sclk); 

        // Send all bits for the left channel, MSB first
        for (int i = AUDIO_DW - 1; i >= 0; i--) begin
            sdata <= left_data[i];
            @ (posedge sclk);
        end

        // Send Right Channel (ws=1)
        ws <= 1;
        @ (posedge sclk); // WS transition edge
        // ** On this clock edge, the DUT should latch the left_chan data **

        // 1-clock delay for I2S standard
        @ (posedge sclk); 

        // Send all bits for the right channel, MSB first
        for (int i = AUDIO_DW - 1; i >= 0; i--) begin
            sdata <= right_data[i];
            @ (posedge sclk);
        end
        
        // End of Frame 
        // Transition WS back to 0 to start the next frame.
        // This is necessary to latch the right_chan data.
        ws <= 0;
        @ (posedge sclk); // WS transition edge
        // ** On this clock edge, the DUT should latch the right_chan data **

        // Keep sdata idle
        sdata <= 0;
    end
    endtask


    // Test Sequence
    initial begin
        // Reset Phase 
        $display("Starting testbench...");
        rst = 1;   // Assert reset
        ws = 0;    // Initialize signals
        sdata = 0;
        #100;     
        rst = 0;   
        @ (posedge sclk); // Wait for one clock edge
        
        $display("Reset complete. Starting test cases...");

        // Test Case 1 
        logic [AUDIO_DW-1:0] test_left_1  = 16'hDEAD;
        logic [AUDIO_DW-1:0] test_right_1 = 16'hBEEF;

        // Send the first frame
        send_i2s_frame(test_left_1, test_right_1);
        
        // Give a small delay for signals to propagate before checking
        #10;

        // Verification 1 
        if (left_chan == test_left_1 && right_chan == test_right_1) begin
            $display("Test 1 PASSED: L=0x%h, R=0x%h", left_chan, right_chan);
        end else begin
            $display("Test 1 FAILED: Expected L=0x%h, R=0x%h. Got L=0x%h, R=0x%h",
                     test_left_1, test_right_1, left_chan, right_chan);
        end

        // Test Case 2 
        logic [AUDIO_DW-1:0] test_left_2  = 16'h1234;
        logic [AUDIO_DW-1:0] test_right_2 = 16'h5678;

        // Send the second frame
        send_i2s_frame(test_left_2, test_right_2);
        
        #10;

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
        $finish;
    end

endmodule