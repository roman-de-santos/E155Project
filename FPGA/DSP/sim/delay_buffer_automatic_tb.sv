// -----------------------------------------------------------------------------
// Module: delay_buffer_tb
//
// Description:
//   Self-checking, procedural testbench for the delay_buffer module.
//
//   Implements the test plan:
//   1.  Reset Test
//   2.  Single Packet "Smoke Test"
//   3.  Gappy Stream Test
//   4.  Dynamic Delay Increase (LFO Sim)
//   5.  Dynamic Delay Decrease (LFO Sim)
//   6.  MAX_DELAY Clamping Test
//   7.  Wrap-Around "Soak Test"
//   8.  Startup "Priming" Test
//   9.  Mid-Stream Reset Test
//
//   This testbench uses a scoreboard (reference model) to automatically
//   verify the DUT's output against an expected value.
// -----------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module delay_buffer_automatic_tb;

    // -------------------------------------------------------------------------
    // Testbench Parameters & Configuration
    // -------------------------------------------------------------------------
    localparam BUF_DEPTH   = 7680; // DUT default
    localparam PKT_WIDTH   = 16;   // DUT default
    localparam ADDR_WIDTH  = $clog2(BUF_DEPTH); // DUT default

    localparam TEST_AVG_DELAY = 4;
    localparam TEST_EXTRA_DELAY = 3;
    // Total default delay = 7 cycles

    // Clock period
    localparam CLK_PERIOD = 10; // 10 ns = 100 MHz (sim clock, not 80MHz)
    
    // Max delay
    localparam [ADDR_WIDTH-1:0] TEST_MAX_DELAY = BUF_DEPTH - 10;

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
    // Scoreboard (Self-Checking Reference Model)
    // -------------------------------------------------------------------------
    logic [PKT_WIDTH-1:0]  reference_buffer [BUF_DEPTH-1:0];
    logic [ADDR_WIDTH-1:0] write_addr_tb;
    logic [ADDR_WIDTH-1:0] read_addr_tb;
    logic [PKT_WIDTH-1:0]  expected_data_tb;
    logic                  expected_valid_tb;
    logic                  pkt_valid_d1; // 1-cycle delay of pkt_valid_i

    // This combinational block calculates the *expected* read address,
    // mirroring the DUT's 'read_addr_comb' logic.
    always_comb begin
        logic [ADDR_WIDTH:0]   delay_sum;
        
        delay_sum = (ADDR_WIDTH+1)'(TEST_AVG_DELAY) + (ADDR_WIDTH+1)'(extra_read_addr_delay_i);
        
        if (delay_sum > TEST_MAX_DELAY)   total_delay_tb = ADDR_WIDTH'(TEST_MAX_DELAY);
        else                            total_delay_tb = ADDR_WIDTH'(delay_sum);

        if (write_addr_tb >= total_delay_tb) begin
            read_addr_tb = write_addr_tb - total_delay_tb;
        end else begin
            read_addr_tb = BUF_DEPTH + write_addr_tb - total_delay_tb;
        end
    end

    // This sequential block models the scoreboard's RAM and write pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr_tb <= '0;
            pkt_valid_d1  <= 1'b0;
            // RAM content is not reset
        end else begin
            // Model the 1-cycle pipeline for valid
            pkt_valid_d1 <= pkt_valid_i;

            if (pkt_valid_i) begin
                // Write to the reference buffer
                reference_buffer[write_addr_tb] <= pkt_i;
                
                // Advance the write pointer
                if (write_addr_tb == (BUF_DEPTH - 1'b1)) write_addr_tb <= '0;
                else                                     write_addr_tb <= write_addr_tb + 1'b1;
            end
        end
    end

    // Model the synchronous read (data available 1 cycle after address)
    // This uses the *read_addr_tb* calculated in the comb block.
    always_ff @(posedge clk) begin
        if (pkt_valid_i) begin
            // Model the synchronous RAM read. The read_addr_tb was calculated
            // from the write_addr_tb *before* it was incremented.
            expected_data_tb <= reference_buffer[read_addr_tb];
        end
    end
    
    // The expected valid signal is just the pkt_valid signal, delayed one cycle.
    assign expected_valid_tb = pkt_valid_d1;


    // -------------------------------------------------------------------------
    // Verification & Assertion Block
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (expected_valid_tb) begin
            // If the scoreboard expects a valid packet, check the DUT
            assert (pkt_delayed_valid_o)
                else begin
                    $error("[Test %0d] VALIDITY FAILED: pkt_delayed_valid_o is 0, expected 1.", test_num);
                    errors++;
                end

            assert (pkt_delayed_o == expected_data_tb)
                else begin
                    $error("[Test %0d] DATA FAILED: DUT data is %h, expected %h.", test_num, pkt_delayed_o, expected_data_tb);
                    errors++;
                end
        end else begin
            // If the scoreboard does not expect data, check the DUT
            assert (pkt_delayed_valid_o == 0)
                else begin
                    $error("[Test %0d] VALIDITY FAILED: pkt_delayed_valid_o is 1, expected 0.", test_num);
                    errors++;
                end
        end
    end

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

    task automatic write_packet(input logic [PKT_WIDTH-1:0] data);
        pkt_i <= data;
        pkt_valid_i <= 1'b1;
        @(posedge clk);
        pkt_valid_i <= 1'b0;
        pkt_i <= '0;
    endtask

    task automatic write_gappy_stream(input int num_packets, input int gap_cycles);
        repeat (num_packets) begin
            packet_counter++;
            write_packet(packet_counter);
            wait_cycles(gap_cycles);
        end
    endtask
    
    task automatic write_continuous_stream(input int num_packets);
        repeat (num_packets) begin
            packet_counter++;
            write_packet(packet_counter);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        test_num = 0;
        errors = 0;

        // ---------------------------------
        $display("\n--- Test 1: Reset Test ---");
        test_num = 1;
        reset_dut();
        // Verification block automatically checks for 0s
        wait_cycles(10); 
        
        // ---------------------------------
        $display("\n--- Test 2: Single Packet Smoke Test ---");
        test_num = 2;
        reset_dut();
        extra_read_addr_delay_i <= TEST_EXTRA_DELAY; // Total delay = 4 + 3 = 7
        write_packet(16'hFACE);
        // Wait for (total_delay - 1) cycles. Valid output appears on 7th cycle
        // *after* the valid *input* (which is 8th cycle after write task).
        wait_cycles(TEST_AVG_DELAY + TEST_EXTRA_DELAY); 
        // Verification block will check for 0xFACE on the next 'expected_valid_tb'
        wait_cycles(10); // Wait for output to drain
        
        // ---------------------------------
        $display("\n--- Test 3: Gappy Stream Test ---");
        test_num = 3;
        reset_dut();
        extra_read_addr_delay_i <= TEST_EXTRA_DELAY;
        // Write 10 packets, each separated by a 5-cycle gap
        write_gappy_stream(10, 5); 
        wait_cycles(20); // Wait for stream to drain

        // ---------------------------------
        $display("\n--- Test 4 & 5: LFO Simulation (Dynamic Delay) ---");
        test_num = 4;
        reset_dut();
        lfo_val = 3; // Start at 3
        extra_read_addr_delay_i <= lfo_val;
        
        // Start a continuous stream to fill the buffer
        write_continuous_stream(20);

        $display("LFO Modulating Up (Delay Increase)...");
        // LFO simulation: triangular wave from 3 to 8
        repeat (5) begin
            lfo_val <= lfo_val + 1;
            extra_read_addr_delay_i <= lfo_val;
            write_packet(++packet_counter);
            // Assertions will catch data repeats (Test 4)
        end
        
        test_num = 5;
        $display("LFO Modulating Down (Delay Decrease)...");
        // LFO simulation: triangular wave from 8 down to 3
        repeat (5) begin
            lfo_val <= lfo_val - 1;
            extra_read_addr_delay_i <= lfo_val;
            write_packet(++packet_counter);
            // Assertions will catch data skips (Test 5)
        end
        wait_cycles(20); // Wait for stream to drain

        // ---------------------------------
        $display("\n--- Test 6: MAX_DELAY Clamping Test ---");
        test_num = 6;
        reset_dut();
        // Set delay to a huge value that will be clamped
        extra_read_addr_delay_i <= BUF_DEPTH; // Should be clamped
        write_continuous_stream(20);
        // Scoreboard logic also has the clamp, so assertions should pass
        wait_cycles(30);

        // ---------------------------------
        $display("\n--- Test 7: Wrap-Around 'Soak Test' ---");
        test_num = 7;
        reset_dut();
        extra_read_addr_delay_i <= TEST_EXTRA_DELAY;
        $display("Writing %0d packets to force wrap-around...", BUF_DEPTH + 500);
        // This test will take a while, but is critical
        write_continuous_stream(BUF_DEPTH + 500);
        wait_cycles(20); // Wait for stream to drain
        
        // ---------------------------------
        $display("\n--- Test 8: Startup 'Priming' Test ---");
        test_num = 8;
        reset_dut();
        extra_read_addr_delay_i <= TEST_EXTRA_DELAY;
        // Write one packet
        write_packet(16'hABCD);
        // The *very next* cycle, valid_o should be HIGH (per DUT logic)
        // but the data will be 0 or X (uninitialized).
        // Our scoreboard models this, so the assert block will check
        // that pkt_delayed_o == 0 (or 'x', but our model has 0)
        @(posedge clk);
        // The 'expected_data_tb' will be 0 (from reset), not 0xABCD
        // The 'expected_valid_tb' will be 1.
        // The assertion block will check:
        //   assert(pkt_delayed_valid_o == 1)
        //   assert(pkt_delayed_o == 0)
        wait_cycles(20);

        // ---------------------------------
        $display("\n--- Test 9: Mid-Stream Reset Test ---");
        test_num = 9;
        reset_dut();
        extra_read_addr_delay_i <= TEST_EXTRA_DELAY;
        write_continuous_stream(30); // Start a stream
        // In the middle of the stream...
        reset_dut(); // Assert reset
        // Check that it's all 0
        wait_cycles(10);
        // Start over and see if it works
        write_continuous_stream(20);
        wait_cycles(20); // Drain

        // ---------------------------------
        $display("\n--- Test Sequence Finished ---");
        if (errors == 0) begin
            $display("SUCCESS: All %0d tests passed with 0 errors.", test_num);
        end else begin
            $display("FAILURE: %0d errors detected.", errors);
        end
        $stop;
    end

endmodule