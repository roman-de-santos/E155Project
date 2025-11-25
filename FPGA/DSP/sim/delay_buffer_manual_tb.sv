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
module delay_buffer_manual_tb;

    // -------------------------------------------------------------------------
    // Testbench Parameters & Configuration
    // -------------------------------------------------------------------------
    localparam BUF_DEPTH    = 4410; // DUT default
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
    logic                   pktDelayedChanged_reg_o;

    // Testbench state
	logic [31:0] clk_cnt;
    logic [31:0] test_num;
    logic [31:0] errors;
    logic [PKT_WIDTH-1:0] packet_counter;
    logic [ADDR_WIDTH:0]   total_delay_tb; // For scoreboard calc

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
        .BUF_DEPTH(BUF_DEPTH),
        .AVG_DELAY(TEST_AVG_DELAY)
    ) DUT (
        .rst_n(rst_n),
        .clk(clk),
        .pkt_reg_i(pkt_reg_i),
        .pktChanged_reg_i(pktChanged_reg_i),
        .extraDelay_reg_i(extraDelay_reg_i),
        .pktDelayed_reg_o(pktDelayed_reg_o),
        .pktDelayedChanged_reg_o(pktDelayedChanged_reg_o)
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

        // Procedure: Drive pkt_reg_i = 16'hFACE and strobe pktChanged_reg_i = 1
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
        wait_cycles(5);

        // Check that outputs and internal regs are 0 during reset
        // Note: Accessing internal DUT signals via hierarchical paths
        assert (pktDelayed_reg_o == 0) 
            else begin $error("Test 1 Fail: pktDelayed_reg_o is not 0 during reset."); errors++; end
        
        assert (pktDelayedChanged_reg_o == 0) 
            else begin $error("Test 1 Fail: pktDelayedChanged_reg_o is not 0 during reset."); errors++; end
        
        assert (DUT.writeAddr_reg == 0) 
            else begin $error("Test 1 Fail: writeAddr_reg is not 0 during reset."); errors++; end
        
        assert (DUT.writeAddrOld_reg == 0) 
            else begin $error("Test 1 Fail: writeAddrOld_reg is not 0 during reset."); errors++; end
        
        assert (DUT.spramDOValid_reg == 0) 
            else begin $error("Test 1 Fail: spramDOValid_reg is not 0 during reset."); errors++; end

        // Procedure: De-assert rst_n and check outputs remain 0
        rst_n = 1;
        wait_cycles(2); // Wait a couple cycles

        assert (pktDelayed_reg_o == 0 && pktDelayedChanged_reg_o == 0)
            else begin $error("Test 1 Fail: Outputs became active without input after reset de-assertion."); errors++; end
        
        $display("Test 1 Complete.");


        // ---------------------------------------------------------------------
        // Test 2: Single Packet "Smoke Test"
        // ---------------------------------------------------------------------
        test_num = 2;
        $display("Starting Test 2: Single Packet Smoke Test");
		reset_dut;

        // Procedure: Send nine dummy packets, each with a delay of TEST_AVG_DELAY - 4
		for (int i = 0; i<9; i++) begin
			send_data(1, packets_array[i]);
			wait_cycles(3);
		end
		

        // Procedure: Count exactly (TEST_AVG_DELAY + 3) cycles after assertion
        // We already waited 1 cycle above for the pulse.
        // Remaining wait = (TEST_AVG_DELAY + 3) - 1?
        // Assuming "after you asserted" implies waiting that duration *after* the strobe event started.
        // Let's wait the full count to be safe as per instructions "Count... cycles".
        
        repeat (TEST_AVG_DELAY + 3) @(posedge clk);

        // Procedure: On the next clock cycle, verify outputs
        @(posedge clk);
        
        // Check valid flag
        assert (pktDelayedChanged_reg_o == 1'b1)
            else begin 
                $error("Test 2 Fail: pktDelayedChanged_reg_o expected 1, got %b", pktDelayedChanged_reg_o); 
                errors++; 
            end

        // Check data value
        assert (pktDelayed_reg_o == 16'hFACE)
            else begin 
                $error("Test 2 Fail: pktDelayed_reg_o expected 16'hFACE, got 16'h%h", pktDelayed_reg_o); 
                errors++; 
            end

        $display("Test 2 Complete.");


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