`timescale 1ns/1ps

module I2Stx_tb();

    localparam WIDTH = 16;
    localparam CLK_PERIOD = 20;   // 50 MHz SCLK for example

    // DUT signals
    logic sclk = 0;
    logic rst  = 1;
    logic ws;
    logic sdata;
    logic [WIDTH-1:0] left_chan;
    logic [WIDTH-1:0] right_chan;

    // Instantiate DUT
    I2Stx #(.WIDTH(WIDTH)) dut (
        .sclk(sclk),
        .rst(rst),
        .ws(ws),
        .sdata(sdata),
        .left_chan(left_chan),
        .right_chan(right_chan)
    );

    // Generate SCLK
    always #(CLK_PERIOD/2) sclk = ~sclk;

    // Internal test variables
    logic [2*WIDTH-1:0] expected_frame;
    integer bit_index;

    // Task: check next frame
    task check_frame(input [WIDTH-1:0] L, input [WIDTH-1:0] R);
        begin
            expected_frame = {L, R};   // MSB first
            bit_index = 2*WIDTH - 1;

            // Wait for WS to go low at start of LEFT word
            @(negedge sclk);
            wait (ws == 0);

            // MSB should appear *one clock later* (I2S spec)
            @(negedge sclk);

            repeat (2*WIDTH) begin
                @(negedge sclk);

                if (sdata !== expected_frame[bit_index]) begin
                    $display("ERROR: Bit mismatch at index %0d. Expected %b, got %b",
                             bit_index, expected_frame[bit_index], sdata);
                    $stop;
                end

                bit_index -= 1;

                // Check WS correctness:
                if (bit_index == WIDTH - 1 && ws !== 1) begin
                    $display("ERROR: WS should switch to RIGHT at bit boundary!");
                    $stop;
                end
                if (bit_index < WIDTH - 1 && ws !== 1'b1) begin
                    /* Right-channel region */
                end
            end
        end
    endtask


    initial begin
        $display("=== Starting I2S TX Testbench ===");

        // Initialize inputs
        left_chan  = 16'hA55A;
        right_chan = 16'h3C12;

        // Hold reset for several cycles
        repeat (5) @(negedge sclk);
        rst = 0;

        // Check first frame
        check_frame(left_chan, right_chan);

        // Change samples for next frame
        left_chan  = 16'h1234;
        right_chan = 16'hF00D;

        // Check second frame
        check_frame(left_chan, right_chan);

        $display("=== All test cases passed ===");
        $finish;
    end

endmodule
