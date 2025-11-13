// Lucas Lemos - llemos@hmc.edu - 11/12/2025
// Instantiates delay_buffer module for simple manual assertion simulating
`timescale 1 ps / 1 ps

module delay_buffer_manual_tb;

    // -------------------------------------------------------------------------
    // Testbench Parameters & Configuration
    // -------------------------------------------------------------------------
    localparam BUF_DEPTH   = 7680; // DUT default
    localparam PKT_WIDTH   = 16;   // DUT default
    localparam ADDR_WIDTH  = $clog2(BUF_DEPTH); // DUT default

    localparam TEST_AVG_DELAY = 4;
    //localparam TEST_EXTRA_DELAY = 3;
    // Total default delay = 7 cycles

    // Clock period
    localparam CLK_PERIOD = 10; // 10 ns = 100 MHz (sim clock, not 80MHz)

    // -------------------------------------------------------------------------
    // Testbench Variables & DUT I/O
    // -------------------------------------------------------------------------

    // DUT I/O
    logic                   rst_n;
    logic                   clk;
    logic [PKT_WIDTH-1:0]   pkt_i;
    logic                   pkt_valid_i;
    logic [ADDR_WIDTH-1:0]  extra_read_addr_delay_i;
    logic [PKT_WIDTH-1:0]   pkt_delayed_o;
    logic                   pkt_delayed_valid_o;

    // Testbench state
    logic [31:0] test_num;
    logic [31:0] errors;
    logic [PKT_WIDTH-1:0] packet_counter;
    logic [ADDR_WIDTH-1:0] lfo_val;
    logic [ADDR_WIDTH:0]   total_delay_tb; // For scoreboard calc

    // -------------------------------------------------------------------------
    // Clock Generator
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    // -------------------------------------------------------------------------
    delay_buffer #(
        .BUF_DEPTH(BUF_DEPTH),
        .PKT_WIDTH(PKT_WIDTH),
        .AVG_DELAY(TEST_AVG_DELAY) // Using test-specific AVG_DELAY
    ) DUT (
        .rst_n(rst_n),
        .clk(clk),
        .pkt_i(pkt_i),
        .pkt_valid_i(pkt_valid_i),
        .extra_read_addr_delay_i(extra_read_addr_delay_i),
        .pkt_delayed_o(pkt_delayed_o),
        .pkt_delayed_valid_o(pkt_delayed_valid_o)
    );

	// -------------------------------------------------------------------------
    // Test Tasks
    // -------------------------------------------------------------------------
    task automatic reset_dut;
        $display("Resetting DUT and Scoreboard...");
        rst_n <= 1'b0;
        pkt_i <= '0;
        pkt_valid_i <= 1'b0;
        extra_read_addr_delay_i <= '0;
        packet_counter <= '0;
        wait_cycles(5);
        rst_n <= 1'b1;
        wait_cycles(2);
    endtask

	task automatic wait_cycles(input int num_cycles);
        repeat (num_cycles) @(posedge clk);
    endtask
	
	// Begin test by pulsing reset and enabling DUT
	initial
		begin
		rst_n = 0; #12; rst_n = 1; #12;
		end
	
endmodule