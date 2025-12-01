// -------------------------------------------------------------------------
// Testbench for CDC
// 
// Description:
// Validates the fast-to-slow clock domain crossing module.
// Generates asynchronous clocks (1.4112 MHz and 6.0 MHz).
// Provides tasks for resetting the DUT and injecting audio packets.
//
// -------------------------------------------------------------------------
`timescale 1 ns / 1 ps

module CDC_FTS_tb;

    // -------------------------------------------------------------------------
    // Parameters & Configuration
    // -------------------------------------------------------------------------
    localparam PKT_WIDTH = 16;
    
    // Clock Periods (in ns)
    // Slow: 1.4112 MHz => ~708.616 ns
    // Fast: 6.0000 MHz => ~166.666 ns
    real CLK_SLOW_PERIOD = 708.616;
    real CLK_FAST_PERIOD = 166.666;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    
    // Clock & Reset
    logic clkI2SBit_i;
    logic clkDSP_i;
    logic rstDSP_n_i;

    // Write Interface (Fast)
    logic [PKT_WIDTH-1:0] pktI2S_i;
    logic                 pktValidI2S_i;

    // Read Interface (Slow)
    logic [PKT_WIDTH-1:0] pktDSP_reg_o;
    logic                 pktChangedDSP_comb_o;

    // Testbench Variables
    int errors;
    int sent_cnt;
    int received_cnt;
	int test_num;
	

    // -------------------------------------------------------------------------
    // Clock Generation (Asynchronous)
    // -------------------------------------------------------------------------
    
    // Slow Clock (1.4112 MHz)
    initial begin
        clkI2SBit_i = 0;
        forever #(CLK_SLOW_PERIOD/2.0) clkI2SBit_i = ~clkI2SBit_i;
    end

    // Fast Clock (6 MHz)
    initial begin
        clkDSP_i = 0;
        // Offset start slightly to ensure edges aren't perfectly aligned
        #13; 
        forever #(CLK_FAST_PERIOD/2.0) clkDSP_i = ~clkDSP_i;
    end

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    CDC_STF #(
        .PKT_WIDTH(PKT_WIDTH)
    ) DUT (
        .clkI2SBit_i     (clkDSP_i),
        .clkDSP_i        (clkI2SBit_i),
        .rstDSP_n_i      (rstDSP_n_i),
        .pktI2S_i      	(pktI2S_i),
        .pktValidI2S_i (pktValidI2S_i),
        .pktDSP_reg_o    (pktDSP_reg_o),
        .pktChangedDSP_comb_o (pktChangedDSP_comb_o)
    );
	
	// Lattice iCE40 power up reset requirement for sim
	PUR PUR_INST (1'b1
		//.PUR(1'b1)
	);

    // -------------------------------------------------------------------------
    // Test Tasks
    // -------------------------------------------------------------------------

    // Resets both domains
    task automatic reset_dut;
        $display("[%0t] Resetting DUT...", $time);
        
        // Assert reset
        rstDSP_n_i   = 1'b0;
		
        pktI2S_i      = '0;
        pktValidI2S_i = 1'b0;
		sent_cnt = '0;
        
        // Hold reset for a few cycles of the SLOW clock (dominates time)
        repeat (5) @(posedge clkI2SBit_i);
        
        // Release resets
        @(posedge clkDSP_i)    rstDSP_n_i   = 1'b1;
        
        // Wait for internal IP lock/settle
        repeat (5) @(posedge clkDSP_i);
        $display("[%0t] Reset Complete.", $time);
    endtask

    // Writes a single packet to the FAST domain
    task automatic write_packet(input logic [PKT_WIDTH-1:0] data);
        // Align to fast clock
        @(posedge clkDSP_i);
        pktI2S_i      <= data;
        pktValidI2S_i <= 1'b1;
        
        // Pulse for 1 cycle
        @(posedge clkDSP_i);
        pktValidI2S_i <= 1'b0;
        pktI2S_i      <= 'x; // Optional: helps spot holding errors in waveform
        
        sent_cnt++;
    endtask

    // Wait N slow cycles
    task automatic wait_slow_cycles(input int cycles);
        repeat(cycles) @(posedge clkI2SBit_i);
    endtask

    // -------------------------------------------------------------------------
    // Main Test Procedure
    // -------------------------------------------------------------------------
    initial begin
        // Init
        errors = 0;
        sent_cnt = 0;
        received_cnt = 0;
        reset_dut();

        // -------------------------------------------------------------------------
		// Test 1: Single packet input -> output latency
		// -------------------------------------------------------------------------
		test_num = 1;
        $display("Starting Test 1: Single packet input -> output latency");
		write_packet(16'h0001);
				
		
        // Allow time for data to propagate through CDC
        wait_slow_cycles(20);
		
		// -------------------------------------------------------------------------
		// Test 2: Writing immediately after reset	
		// -------------------------------------------------------------------------	
		test_num = 2;	
		$display("Test 2: Writing immediately after reset");
		reset_dut();
		
		rstDSP_n_i   = 1'b0;
        repeat (5) @(posedge clkDSP_i);
        @(posedge clkI2SBit_i)    rstDSP_n_i   = 1'b1;
		
		write_packet(16'h0001);
		write_packet(16'h0010);
		write_packet(16'h0100);
		write_packet(16'h1000);
		
		wait_slow_cycles(20);
		
		
		// -------------------------------------------------------------------------
		// Test 3: Writing to FIFO back-to-back
		// -------------------------------------------------------------------------	
		test_num = 3;
		$display("Test 3: Writing to FIFO back-to-back");
		reset_dut();
		
		@(posedge clkDSP_i);
        pktI2S_i      <= 16'hAAAA;
        pktValidI2S_i <= 1'b1;
		@(posedge clkDSP_i)	pktI2S_i  <= 16'hBBBB;
		@(posedge clkDSP_i)	pktI2S_i  <= 16'hCCCC;
		@(posedge clkDSP_i)	pktI2S_i  <= 16'hDDDD;
		@(posedge clkDSP_i)	pktI2S_i  <= 16'hEEEE;
		@(posedge clkDSP_i)	pktI2S_i  <= 16'hFFFF;
		
		wait_slow_cycles(20);
		
		
		/*
        // 3. Final Report
        if (errors == 0) begin
            $display("\n==================================================");
            $display("SUCCESS: All tests passed!");
            $display("Sent: %0d | Received: %0d", sent_cnt, received_cnt);
            $display("==================================================\n");
        end else begin
            $display("\n==================================================");
            $display("FAILURE: %0d error(s) occurred during testing.", errors);
            $display("==================================================\n");
        end
		*/
        $stop;
    end

endmodule