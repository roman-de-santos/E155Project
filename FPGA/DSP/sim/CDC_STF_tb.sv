// -------------------------------------------------------------------------
// Testbench for CDC_STF
// 
// Description:
// Validates the slow-to-fast clock domain crossing module.
// Generates asynchronous clocks (1.4112 MHz and 6.0 MHz).
// Provides tasks for resetting the DUT and injecting audio packets.
//
// -------------------------------------------------------------------------
`timescale 1 ns / 1 ps

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

module CDC_STF_tb;

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

    // Write Interface (Slow)
    logic [PKT_WIDTH-1:0] pktI2S_i;
    logic                 pktValidI2S_i;

    // Read Interface (Fast)
    logic [PKT_WIDTH-1:0] pktDSP_reg_o;
    logic                 pktChangedDSP_comb_o;

    // Testbench Variables
    int errors;
    int sent_cnt;
    int received_cnt;
	int test_num;
	
	// Dummy packets array
	import packets_array_pkg::*;
	packets_array_t packets_array;

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
        .clkI2SBit_i     (clkI2SBit_i),
        .clkDSP_i        (clkDSP_i),
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
        
        // Hold reset for a few cycles of the SLOW clock (dominates time)
        repeat (10) @(posedge clkI2SBit_i);
        
        // Release resets (Asynchronous release is okay if DUT has sync logic, 
        // but releasing on edges is cleaner for sim)
        @(posedge clkDSP_i)    rstDSP_n_i   = 1'b1;
        
        // Wait for internal IP lock/settle
        repeat (10) @(posedge clkDSP_i);
        $display("[%0t] Reset Complete.", $time);
    endtask

    // Writes a single packet to the slow domain
    task automatic write_packet(input logic [PKT_WIDTH-1:0] data);
        // Align to slow clock
        @(posedge clkI2SBit_i);
        pktI2S_i      <= data;
        pktValidI2S_i <= 1'b1;
        
        // Pulse for 1 cycle
        @(posedge clkI2SBit_i);
        pktValidI2S_i <= 1'b0;
        pktI2S_i      <= 'x; // Optional: helps spot holding errors in waveform
        
        sent_cnt++;
    endtask

    // Wait N fast cycles
    task automatic wait_fast_cycles(input int cycles);
        repeat(cycles) @(posedge clkDSP_i);
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
		packets_array = CONST_DATA_ARRAY;

        // -------------------------------------------------------------------------
		// Test 1: Single packet input -> output latency
		// -------------------------------------------------------------------------
		test_num = 1;
        $display("Starting Test 1: Single packet input -> output latency");
		wait_fast_cycles(30);
		write_packet(16'h0001);
		write_packet(16'h0010);
		write_packet(16'h0100);
		write_packet(16'h1000);
		
		
        // Allow time for data to propagate through CDC
        wait_fast_cycles(30);
		
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