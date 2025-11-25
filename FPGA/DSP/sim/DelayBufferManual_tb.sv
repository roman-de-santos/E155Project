// Lucas Lemos - llemos@hmc.edu - 11/12/2025
// Instantiates delay_buffer module for simple manual assertion simulating
`timescale 1 ps / 1 ps

// Dummy packets for testing the buffer
package packets_array_pkg;
    parameter SIZE = 100;

    typedef logic [15:0] pkt_t;

    // Define the type for an array of SIZE data_t elements (unpacked array)
    // Indices will range from [SIZE-1:0], which is [99:0] for SIZE=100.
    typedef pkt_t packets_array_t [0:SIZE-1];

    // Define the constant array with 100 unique values.
    const packets_array_t CONST_DATA_ARRAY = '{
        // --- Explicitly Defined Unique Values (Indices 0 - 9) ---
        16'hAAAA,  // Index 0
        16'hBBBB,  // Index 1
        16'hCCCC,  // Index 2
        16'hDDDD,  // Index 3
        16'hEEEE,  // Index 4
        16'hFFFF,  // Index 5
        16'h1234,  // Index 6
        16'h5678,  // Index 7
        16'h9999,  // Index 8
        16'h2468,  // Index 9
        
        // --- Sequential Unique Values (Indices 10 - 99) ---
        // Using an easily verifiable pattern (h100A, h100B, h100C, ...)
        16'h100A, 16'h100B, 16'h100C, 16'h100D, 16'h100E, 16'h100F, 16'h1010, 16'h1011, 16'h1012, 16'h1013, 
        16'h1014, 16'h1015, 16'h1016, 16'h1017, 16'h1018, 16'h1019, 16'h101A, 16'h101B, 16'h101C, 16'h101D, 
        16'h101E, 16'h101F, 16'h1020, 16'h1021, 16'h1022, 16'h1023, 16'h1024, 16'h1025, 16'h1026, 16'h1027, 
        16'h1028, 16'h1029, 16'h102A, 16'h102B, 16'h102C, 16'h102D, 16'h102E, 16'h102F, 16'h1030, 16'h1031, 
        16'h1032, 16'h1033, 16'h1034, 16'h1035, 16'h1036, 16'h1037, 16'h1038, 16'h1039, 16'h103A, 16'h103B, 
        16'h103C, 16'h103D, 16'h103E, 16'h103F, 16'h1040, 16'h1041, 16'h1042, 16'h1043, 16'h1044, 16'h1045, 
        16'h1046, 16'h1047, 16'h1048, 16'h1049, 16'h104A, 16'h104B, 16'h104C, 16'h104D, 16'h104E, 16'h104F, 
        16'h1050, 16'h1051, 16'h1052, 16'h1053, 16'h1054, 16'h1055, 16'h1056, 16'h1057, 16'h1058, 16'h1059, 
        16'h105A, 16'h105B, 16'h105C, 16'h105D, 16'h105E, 16'h105F, 16'h1060, 16'h1061, 16'h1062, 16'h1063
    };
endpackage



// -------------------------------------------------------------------------
// TESTBENCH BEGINS
// -------------------------------------------------------------------------
module DelayBufferManual_tb;

    // -------------------------------------------------------------------------
    // Testbench Parameters & Configuration
    // -------------------------------------------------------------------------
    localparam TEST_BUF_DEPTH    = 90;
    localparam TEST_AVG_DELAY = 4;

    //localparam TEST_EXTRA_DELAY = 3;
    // Total default delay = 7 cycles

    localparam PKT_WIDTH = 16;
    localparam ADDR_WIDTH = 14;

    // Clock period
    localparam CLK_PERIOD = 10; // 10 ns = 100 MHz (sim clock, not 80MHz)

    // -------------------------------------------------------------------------
    // Testbench Variables & DUT I/O
    // -------------------------------------------------------------------------

    // DUT I/O

    logic                   rst_n;
    logic                   clk;
    logic [PKT_WIDTH-1:0]   pkt_reg_i;
    logic                   pktChanged_reg_i;
    logic [ADDR_WIDTH-1:0]  extraDelay_reg_i;
    logic [PKT_WIDTH-1:0]   pktDelayed_reg_o;
    logic                   pktDelayedChanged_comb_o;
    logic                   errorLED_reg_o;           

    // Testbench state
	int clk_cnt;
    int test_num;
    int errors;
    int packet_counter;
    int total_delay_tb; // For scoreboard calc
	int extra_delay_tb;

    // -------------------------------------------------------------------------
    // Clock Generator
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
	
	always @(posedge clk) begin
		clk_cnt++;
	end

    // -------------------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    // -------------------------------------------------------------------------
    DelayBufferFSM #(
        .BUF_DEPTH(TEST_BUF_DEPTH),
        .AVG_DELAY(TEST_AVG_DELAY)
    ) DUT (
        .rst_n(rst_n),
        .clk(clk),
        .pkt_reg_i(pkt_reg_i),
        .pktChanged_reg_i(pktChanged_reg_i),
        .extraDelay_reg_i(extraDelay_reg_i),
        .pktDelayed_reg_o(pktDelayed_reg_o),
        .pktDelayedChanged_comb_o(pktDelayedChanged_comb_o),
        .errorLED_reg_o(errorLED_reg_o)                      
    );
	
	// Dummy packets array
	import packets_array_pkg::*;
	packets_array_t packets_array;

    // -------------------------------------------------------------------------
    // Test Tasks
    // -------------------------------------------------------------------------
    task automatic reset_dut;
        $display("Resetting DUT and Scoreboard...");
        rst_n <= 1'b0;
        pkt_reg_i <= '0;
        pktChanged_reg_i <= 1'b0;
        extraDelay_reg_i <= '0;
        packet_counter <= '0;
		clk_cnt <= 0;
        wait_cycles(3);
        rst_n <= 1'b1;
        wait_cycles(2);
    endtask

    task automatic wait_cycles(input int num_cycles);
        repeat (num_cycles) @(posedge clk);
    endtask
	
	task automatic send_data(input int extraDelay, input int pkt);
		extraDelay_reg_i = extraDelay;

        // Procedure: Drive pkt_reg_i = pkt and strobe pktChanged_reg_i = 1
        pkt_reg_i = pkt;
        pktChanged_reg_i = 1;
        
        // Advance one clock cycle (strobe)
        @(posedge clk);
        
        // Clear strobe and data (data clear optional but good for clarity)
        pktChanged_reg_i = 0;
	endtask
    
    // -------------------------------------------------------------------------
    // Main Test Procedure
    // -------------------------------------------------------------------------
    initial begin
        errors = 0;
        reset_dut;
        packets_array = CONST_DATA_ARRAY;

        // ---------------------------------------------------------------------
        // Test 1: Reset Test
        // ---------------------------------------------------------------------
        test_num = 1;
        $display("Starting Test 1: Reset Test");

        // Procedure: Hold rst_n = 0 for several clock cycles.
        rst_n = 0;
        wait_cycles(3);

        // Check that outputs and internal regs are 0/Idle during reset
        assert (pktDelayed_reg_o == 0) 
            else begin $error("Test 1 Fail: pktDelayed_reg_o is not 0 during reset."); errors++; end
        
        // UPDATED: Changed_comb_o is combinational, should be 0 in RESET state
        assert (pktDelayedChanged_comb_o == 0) 
            else begin $error("Test 1 Fail: pktDelayedChanged_comb_o is not 0 during reset."); errors++; end
        
        // UPDATED: Internal signal checks adapted for new FSM
        assert (DUT.writeAddr_reg == 0) 
            else begin $error("Test 1 Fail: writeAddr_reg is not 0 during reset."); errors++; end
        
        // UPDATED: Check State instead of spramDOValid_reg
        assert (DUT.state == DUT.RESET) 
            else begin $error("Test 1 Fail: State is not RESET."); errors++; end

        assert (errorLED_reg_o == 0)
             else begin $error("Test 1 Fail: errorLED is active during reset."); errors++; end

        // Procedure: De-assert rst_n and check outputs remain 0
        rst_n = 1;
        wait_cycles(2); 

        assert (pktDelayed_reg_o == 0 && pktDelayedChanged_comb_o == 0)
            else begin $error("Test 1 Fail: Outputs became active without input after reset de-assertion."); errors++; end
        
        $display("Test 1 Complete.");


        // ---------------------------------------------------------------------
        // Test 2: Single Packet "Smoke Test" (0 Delay)
        // ---------------------------------------------------------------------
        test_num = 2;
        $display("Starting Test 2: Single Packet Smoke Test");
        reset_dut;

        // Procedure: 
        // We set extraDelay to -4. Since TEST_AVG_DELAY is 4, Total Delay = 0.
        // With Delay=0, the FSM reads the address it is currently writing to.
        // We expect the data to appear at the output in the same transaction window.
        
        // Send the target packet
        $display("Sending Target Packet 16'hFACE with 0 effective delay...");
        send_data(-4, 16'hFACE);

        // Wait for the Valid pulse. 
        // In the new FSM, valid is high only during the READ state.
        // We poll for it with a timeout.
        fork 
            begin
                // Thread A: Wait for success
                wait(pktDelayedChanged_comb_o == 1'b1);
                
                // Check data value on the exact cycle valid is high
                if (pktDelayed_reg_o !== 16'hFACE) begin 
                    $error("Test 2 Fail: pktDelayed_reg_o expected 16'hFACE, got 16'h%h", pktDelayed_reg_o); 
                    errors++; 
                end else begin
                    $display("Test 2 Pass: Captured 16'hFACE correctly.");
                end
            end
            begin
                // Thread B: Timeout if FSM is stuck
                repeat(10) @(posedge clk);
                if (pktDelayedChanged_comb_o !== 1'b1) begin
                    $error("Test 2 Fail: Timed out waiting for pktDelayedChanged_comb_o");
                    errors++;
                end
            end
        join_any
        disable fork; // Kill the remaining thread

        // Wait a few cycles to ensure we return to IDLE cleanly
        wait_cycles(2);

        $display("Test 2 Complete.");
		
		
		// ---------------------------------------------------------------------
        // Test 3: Sample-based Latency Verification
        // ---------------------------------------------------------------------
        // Verify that the first packet sent shows up after 
        // (TEST_AVG_DELAY + extra_delay_tb) samples later.
        // ---------------------------------------------------------------------
        test_num = 3;
        $display("Starting Test 3: Latency Verification (Sample Count)");
        reset_dut;
		extra_delay_tb = 3;

        begin 
            // The logic: If delay is D samples.
            // Packet 0 is written at Addr 0.
            // Packet D is written at Addr D.
            // At the moment we write Packet D, the read pointer is (D - D) = 0.
            // So Packet 0 should emerge during the transaction for Packet D.
            // Total iterations = 1 (Initial) + D (Subsequent).
            automatic int total_delay_samples = TEST_AVG_DELAY + extra_delay_tb; 

            $display("Configuring Extra Delay: %0d, Total Delay: %0d samples", extra_delay_tb, total_delay_samples);

            // 1. Send the TARGET packet (Packet 0)
            send_data(extra_delay_tb, packets_array[0]);
            wait_cycles(3);

            // 2. Loop to push the first packet out
            // We need to send exactly 'total_delay_samples' MORE packets.
            for (int i = 1; i <= total_delay_samples; i++) begin
                packet_counter++;
				send_data(extra_delay_tb, packets_array[i]);

                // Wait 1 cycle to reach READ state (where valid signal is high)
                @(posedge clk);

                // On the final iteration, the delay pipeline should be full
                // and pointing back to address 0.
                if ((i == total_delay_samples) && (DUT.state == DUT.OUTPUT)) begin
                    if (pktDelayedChanged_comb_o !== 1'b1) begin
                        $error("Test 3 Fail: Valid signal not high on sample %0d", i);
                        errors++;
                    end
                    
                    if (pktDelayed_reg_o !== packets_array[0]) begin
                         $error("Test 3 Fail: Expected %h (Packet 0), Got %h", packets_array[0], pktDelayed_reg_o);
                         errors++;
                    end else begin
                        $display("Test 3 Pass: Retrieved Packet 0 after %0d samples.", total_delay_samples);
                    end
                end

                // Finish the FSM operation for this packet
                wait_cycles(4);
            end
        end
        $display("Test 3 Complete.");
		
		// ---------------------------------------------------------------------
        // Test 4: Gappy Stream & Re-assert Data Test
        // ---------------------------------------------------------------------
        // 1. Write packet[0]
        // 2. Wait 20 cycles (gap)
        // 3. Write packet[1]
        // 4. Assert pktChanged without changing data (simulates repeated data or just a trigger)
        //    With extra_delay = -2 (Total = 2), this 3rd write (index 2) should read index 0.
        // ---------------------------------------------------------------------
        test_num = 4;
		
        $display("Starting Test 4: Gappy Stream & Static Data Re-assertion");
        reset_dut;

        begin
            extra_delay_tb = -2; // Total delay = 4 - 2 = 2 samples
            extraDelay_reg_i = extra_delay_tb;

            // 1. Send Packet 0 (Write Index 0)
            send_data(extra_delay_tb, packets_array[0]);
            
            // 2. Gap
            $display("Waiting 20 cycles (Gap)...");
            wait_cycles(20);

            // 3. Send Packet 1 (Write Index 1)
            send_data(extra_delay_tb, packets_array[1]);
            wait_cycles(3); // Wait for FSM to return to IDLE

            // 4. Assert pktChanged without changing data (Write Index 2)
            // Current pkt_reg_i is still packets_array[1]
            $display("Asserting pktChanged with static data (Packet 1)...");
            pktChanged_reg_i = 1;
            
            // Advance clock to trigger FSM
            @(posedge clk);
            pktChanged_reg_i = 0; // Clear strobe
			@(posedge clk);
            
			if (DUT.state == DUT.OUTPUT) begin
				// Check for valid pulse
				if (pktDelayedChanged_comb_o !== 1'b1) begin
					$error("Test 4 Fail: Valid signal not high on 3rd transaction");
					errors++;
				end
				
				// Logic: Write Index is 2. Total Delay is 2. Read Index should be 0.
				// Expected Output: packets_array[0]
				if (pktDelayed_reg_o !== packets_array[0]) begin
					$error("Test 4 Fail: Expected %h (Packet 0), Got %h", packets_array[0], pktDelayed_reg_o);
					errors++;
				end else begin
					$display("Test 4 Pass: Correctly retrieved Packet 0 during 3rd transaction.");
				end
			end
            
            wait_cycles(5);
        end
        $display("Test 4 Complete.");
		
		
		// ---------------------------------------------------------------------
        // Test 5: Dynamic Delay Increase (LFO Up / Slow down / Time Travel)
        // ---------------------------------------------------------------------
        test_num = 5;
        $display("Starting Test 5: Dynamic Delay Increase");
        reset_dut;
        
        // Phase 1: Load 4 dummy packets (Indices 0-3) at extra_delay = -4
        begin 
            extra_delay_tb = -4;
            for (int i = 0; i < 4; i++) begin
                send_data(extra_delay_tb, packets_array[i]);
                wait(pktDelayedChanged_comb_o);
                packet_counter++;
                @(posedge clk);
            end

            // Phase 2: Switch to increasing extra_delay by 2 and writing
            // We expect the output to walk backwards: Pkt 2 -> Pkt 1 -> Pkt 0
            // Loop for Indices 4, 5, 6
            for (int i = 4; i <= 6; i++) begin
                extra_delay_tb = extra_delay_tb + 2;
                
                send_data(extra_delay_tb, packets_array[i]);
                wait(DUT.state == DUT.OUTPUT);
                packet_counter++;

                // Verification logic
                if (packet_counter == 7) begin
                    // Verify correct state as requested
                    assert(DUT.state == DUT.OUTPUT) else $error("Test 5 Fail: DUT state is not OUTPUT");
                    
                    if (pktDelayed_reg_o == packets_array[0]) begin
                        $display("Test 5 Pass: Output is Packet 0 at packet_counter == 7");
                    end else begin
                        $error("Test 5 Fail: Expected Packet 0, Got %h", pktDelayed_reg_o);
                        errors++;
                    end
                end else if (packet_counter == 6) begin
                    // Optional: Verify Packet 1 appeared here
                    if (pktDelayed_reg_o == packets_array[1]) 
                         $display("Test 5 Info: Packet 1 detected at counter 6 (Expected)");
                end
                
                @(posedge clk);
            end
        end
        $display("Test 5 Complete.");
		
		
		// ---------------------------------------------------------------------
        // Test 6: Dynamic Delay Decrease (LFO down / Skip Ahead / Speed Up)
        // ---------------------------------------------------------------------
        // This is the mirror image of Test 5. 
        // We start with HIGH delay and DECREASE it. 
        // The output should skip samples (e.g. 0 -> 3 -> 6).
        // ---------------------------------------------------------------------
        test_num = 6;
        $display("Starting Test 6: Dynamic Delay Decrease");
        reset_dut;

        // Phase 1: Load 7 dummy packets (Indices 0-6) at extra_delay = +2
        // Total Delay = 4 + 2 = 6.
        // Packet 6 (Addr 6) will read Address (6-6) = 0.
        begin
            extra_delay_tb = 2;
            for (int i = 0; i < 7; i++) begin
                send_data(extra_delay_tb, packets_array[i]);
                wait(pktDelayedChanged_comb_o);
                packet_counter++;
                @(posedge clk);
            end
            
            // Check baseline: Last packet written was #6. Delay 6. Output should be #0.
            if (pktDelayed_reg_o !== packets_array[0]) begin
                 $display("Test 6 Warning: Phase 1 baseline incorrect. Expected %h, Got %h", packets_array[0], pktDelayed_reg_o);
            end

            // Phase 2: Switch to decreasing extra_delay by 2 and writing.
            // Logic:
            // Write Pkt 7. Delay = 0. Total = 4. Read Addr = 7 - 4 = 3. (Expected Packet 3).
            // Write Pkt 8. Delay = -2. Total = 2. Read Addr = 8 - 2 = 6. (Expected Packet 6).
            // Write Pkt 9. Delay = -4. Total = 0. Read Addr = 9 - 0 = 9. (Expected Packet 9).
            
            for (int i = 7; i <= 9; i++) begin
                extra_delay_tb = extra_delay_tb - 2;

                send_data(extra_delay_tb, packets_array[i]);
                wait(DUT.state == DUT.OUTPUT);	
                packet_counter++;

                if (packet_counter == 8) begin // i = 7
                    if (pktDelayed_reg_o == packets_array[3])
                        $display("Test 6 Pass: Skipped to Packet 3 at counter 8");
                    else begin
                        $error("Test 6 Fail: Expected Packet 3, Got %h", pktDelayed_reg_o);
                        errors++;
                    end
                end 
                else if (packet_counter == 9) begin // i = 8
                    if (pktDelayed_reg_o == packets_array[6])
                        $display("Test 6 Pass: Skipped to Packet 6 at counter 9");
                    else begin
                        $error("Test 6 Fail: Expected Packet 6, Got %h", pktDelayed_reg_o);
                        errors++;
                    end
                end
                
                @(posedge clk);
            end
        end
        $display("Test 6 Complete.");
		
		
		// ---------------------------------------------------------------------
        // Test 7: Soak Buffer & Write Address Wrap-around
        // ---------------------------------------------------------------------
        test_num = 7;
        $display("Starting Test 7: Soak Buffer & Write Address Wrap-around");
        reset_dut;
		
		
		extra_delay_tb = -4;
        // Phase 1: Load 90 dummy packets at extra_delay_tb = -4 (totalDelay = 0)
        // 1. Write 100 packets
        // Buffer Depth is 90. 
        // Indices 0-89 fill addresses 0-89.
        // Indices 90-99 wrap to addresses 0-9.
        // Specifically, Index 92 writes to Address 2.
        begin
            $display("Writing 100 packets to trigger wrap-around...");
            for (int i = 0; i < 100; i++) begin
                send_data(extra_delay_tb, packets_array[i]);
                // Wait for the write to finish and return to OUTPUT
                wait(DUT.state == DUT.OUTPUT);
                @(posedge clk); 
				packet_counter++;
            end
        end

        // 2. White-box manipulation
        // Force the FSM to READ state and force the write address to 2.
        // Since extra_delay = -4 (Total Delay = 0), Read Address = Write Address - 0 = 2.
        $display("Forcing DUT state to READ and writeAddr_reg to 2...");
        
        // Using 'force' to override internal FSM logic
        // Note: We use DUT.READ assuming the tool can resolve the enum label hierarchically.
        // If not, use the integer value (likely 3'd4).
        force DUT.state = DUT.READ; 
        force DUT.writeAddr_reg = 14'd2;
		@(posedge clk);
		@(posedge clk);
		release DUT.state;
        release DUT.writeAddr_reg;
		@(posedge clk);

        // 3. Wait for Memory Access
        // Cycle 1: Address 2 applied to SPRAM.
        // Cycle 2: Data available at SPRAM DO, Latched into pktDelayed_reg_o.
        wait(DUT.state == DUT.OUTPUT);

        // 4. Check the result
        // We expect the data from the SECOND pass (Packet 92), not the first pass (Packet 2).
        if (pktDelayed_reg_o === packets_array[92]) begin
            $display("Test 7 Pass: Read %h (Packet 92) at Address 2.", pktDelayed_reg_o);
        end else if (pktDelayed_reg_o === packets_array[2]) begin
            $error("Test 7 Fail: Read %h (Packet 2). Wrap-around overwrite failed.", pktDelayed_reg_o);
            errors++;
        end else begin
            $error("Test 7 Fail: Read %h. Expected %h (Packet 92).", pktDelayed_reg_o, packets_array[92]);
            errors++;
        end
        

        $display("Test 7 Complete.");
		
		
		// ---------------------------------------------------------------------
        // Test 8: Read Address Clamping and Wrap-around (High Delay)
        // ---------------------------------------------------------------------
        // 1. Write 100 packets to establish the circular buffer state (Pkt 0-89, then Pkt 90-99 overwriting Pkt 0-9).
        // 2. Set an excessive extra_delay (200) to force the DUT's delay clamping logic to MAX_DELAY (87).
        // 3. The current Write Address (10) minus the clamped delay (87) must cause a wrap-around calculation (10 - 87 = -77).
        // 4. Wrap-around calculation (90 + 10 - 87) should result in Read Address 13.
        // 5. Address 13 should contain Packet 13.
        // ---------------------------------------------------------------------
        test_num = 8;
        $display("Starting Test 8: Clamping and Read Address Wrap-around Test");
        reset_dut;

        // Set excessive delay to force clamping
        extra_delay_tb = 200;  // Will be clamped to MAX_DELAY (87)

        // 1. Write 100 packets
        begin
			automatic int expected_read_index = 13;
			
            $display("Writing 100 packets to trigger wrap-around...");
            for (int i = 0; i < 100; i++) begin
                send_data(extra_delay_tb, packets_array[i]);
                // Wait for the write to finish and return to OUTPUT
                wait(DUT.state == DUT.OUTPUT);
                @(posedge clk); 
				packet_counter++;
            end
        
			
			wait(DUT.state == DUT.IDLE);
			// 2. Check the final write address (Should be 10)
			assert (DUT.writeAddr_reg == 14'd10) begin
				$display("Test 8 Info: Final writeAddr_reg is %0d (Expected 10)", DUT.writeAddr_reg);
			end else begin
				$error("Test 8 Fail: Final writeAddr_reg expected 10, got %0d. Calculation error.", DUT.writeAddr_reg);
				errors++;
			end

			// 3. Trigger one read cycle with the clamped delay
			// We use a dummy write to trigger the FSM sequence (IDLE -> WRITE -> WAIT1 -> READ -> OUTPUT)
			$display("Triggering read cycle with clamped delay (87 samples).");
			send_data(extra_delay_tb, 16'hFFFF); // Dummy write (Packet 100)
			
			// Wait for the final output state (READ -> OUTPUT transition)
			wait(DUT.state == DUT.OUTPUT); 
			@(posedge clk); 

			// 4. Check the result
			// Expected Read Address: (10 (writeAddr) - 87 (clamped delay)) -> 13 (wrapped).
			// Expected Output: Packet at index 13.
			
			
			if (pktDelayed_reg_o === packets_array[expected_read_index]) begin
				$display("Test 8 Pass: Correctly read %h (Packet %0d) at wrapped address 13.", 
						 pktDelayed_reg_o, expected_read_index);
			end else begin
				$error("Test 8 Fail: Expected %h (Packet %0d), Got %h. Clamping or wrap-around failed.", 
					   packets_array[expected_read_index], expected_read_index, pktDelayed_reg_o);
				errors++;
			end
		end
        
        $display("Test 8 Complete.");
		
		// ---------------------------------------------------------------------
        // Test 9: Mid-Transaction Reset Verification
        // ---------------------------------------------------------------------
        // Description: 
        // 1. Set up a simple write transaction (IDLE -> WRITE).
        // 2. Wait for the FSM to reach the DUT.READ state.
        // 3. De-assert rst_n (pull it low) while in the middle of operation.
        // 4. Assert that the FSM immediately transitions to DUT.RESET on the next clock edge.
        // ---------------------------------------------------------------------
        test_num = 9;
        $display("Starting Test 9: Asynchronous Reset (rst_n) Verification");
        reset_dut;

        // Set delay to 0 (Total Delay = 4, since extra_delay_tb = 0)
        extra_delay_tb = 0; 

        // 1. Begin a write cycle
        $display("Triggering a single write cycle (Packet 0)...");
        send_data(extra_delay_tb, packets_array[0]);

        // 2. Wait until the FSM reaches the DUT.READ state
        // FSM path: IDLE -> WRITE -> WAIT1 -> READ
        wait(DUT.state == DUT.READ);
        $display("FSM is now in the READ state.");

        // 3. De-assert rst_n while in the READ state
        rst_n = 1'b0;
        $display("Asserting asynchronous reset (rst_n = 0).");

        // 4. Wait for the next positive clock edge
        @(posedge clk);
		@(posedge clk);
        
        // 5. Check the result: The state MUST be DUT.RESET immediately
        if (DUT.state == DUT.RESET) begin	
            $display("Test 9 Pass: State transitioned immediately to RESET on the clock edge.");
        end else begin
            $error("Test 9 Fail: Expected state RESET (0), but got %0d. Reset failed.", DUT.state);
            errors++;
        end

        // 6. Release the reset and wait for IDLE
        rst_n = 1'b1;
        $display("De-asserting reset (rst_n = 1) and waiting for FSM to stabilize in IDLE.");
        // The FSM should transition RESET -> IDLE on the next clock cycle
        wait(DUT.state == DUT.IDLE); 
        @(posedge clk); 
        
        $display("Test 9 Complete.");
		

        // ---------------------------------------------------------------------
        // Final Report
        // ---------------------------------------------------------------------
        if (errors == 0) begin
            $display("\n==================================================");
            $display("SUCCESS: All tests passed!");
            $display("==================================================\n");
        end else begin
            $display("\n==================================================");
            $display("FAILURE: %0d error(s) occurred during testing.", errors);
            $display("==================================================\n");
        end

        $stop;
    end
endmodule