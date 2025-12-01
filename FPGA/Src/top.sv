module top(
    input  logic sys_clk,     // 6 MHz Fast Clock
    input  logic sclk_in,     // I2S Bit Clock (Slow ~1.41 MHz)
    input  logic rst,         // Active Low Button
    input  logic ws_in,
    input  logic sdata_in,
    output logic sclk_out,
    output logic ws_out,
    output logic sdata_out
);
    
    parameter WIDTH = 16;

    // --- Signal Declarations ---
    
    // 1. Slow Inputs (From I2S Rx)
    logic [WIDTH-1:0] rx_left_slow, rx_right_slow;
    
    // 2. Fast Inputs (From Slow-to-Fast CDC)
    logic [WIDTH-1:0] rx_left_fast, rx_right_fast; // <--- NEW SIGNALS
    
    // 3. DSP Outputs (Fast Domain)
    logic [WIDTH-1:0] dsp_left, dsp_right; 
    
    // 4. Slow Outputs (To I2S Tx)
    logic [WIDTH-1:0] tx_left, tx_right;
    
    // Control Flags
    logic ws_r;
    logic rx_valid_left_slow, rx_valid_right_slow;
    logic dsp_trigger; // <--- Renamed for clarity
    logic tx_load_en;

    // -------------------------------------------------------------------------
    // 1. I2S Receiver (Slow Domain)
    // -------------------------------------------------------------------------
    I2Srx #(WIDTH) I2Srx0 (
        .sclk(sclk_in), .rst(~rst), 
        .ws(ws_in), .sdata(sdata_in), 
        .left_chan(rx_left_slow), .right_chan(rx_right_slow)
    );

    // -------------------------------------------------------------------------
    // 2. Generate Valid Flags (Slow Domain)
    // -------------------------------------------------------------------------
    always_ff @(posedge sclk_in) begin
        if (~rst) begin
            ws_r <= 0;
            rx_valid_left_slow  <= 0;
            rx_valid_right_slow <= 0;
        end else begin
            ws_r <= ws_in;
            // Rising Edge = Left Done
            rx_valid_left_slow  <= (ws_in && !ws_r); 
            // Falling Edge = Right Done
            rx_valid_right_slow <= (!ws_in && ws_r);
        end
    end

    // -------------------------------------------------------------------------
    // 3. CDC: Slow to Fast (Rx -> DSP)
    // -------------------------------------------------------------------------
    Data_Slow_to_Fast #(WIDTH) CDC_Rx_Left (
        .Clk_Fast(sys_clk),
        .Rst(~rst),
        .Data_In_Slow(rx_left_slow),
        .Valid_In_Slow(rx_valid_left_slow),
        .Data_Out_Fast(rx_left_fast), // <--- Output to intermediate Fast signal
        .Valid_Out_Fast()             // Don't trigger DSP yet, wait for Right chan
    );

    Data_Slow_to_Fast #(WIDTH) CDC_Rx_Right (
        .Clk_Fast(sys_clk),
        .Rst(~rst),
        .Data_In_Slow(rx_right_slow),
        .Valid_In_Slow(rx_valid_right_slow),
        .Data_Out_Fast(rx_right_fast), // <--- Output to intermediate Fast signal
        .Valid_Out_Fast(dsp_trigger)   // <--- Trigger DSP when RIGHT is ready (Frame Complete)
    );

    // -------------------------------------------------------------------------
    // 4. DSP (Fast Domain)
    // -------------------------------------------------------------------------
    // Now we are safely in the Fast Domain.
    // We read 'rx_..._fast' and write to 'dsp_...'
    always_ff @(posedge sys_clk) begin
        if (~rst) begin
             dsp_left  <= 0;
             dsp_right <= 0;
        end else if (dsp_trigger) begin
            // Loopback Logic: Pass Fast Input to Fast Output
            dsp_left  <= rx_left_fast;  
            dsp_right <= rx_right_fast;
        end
    end

    // -------------------------------------------------------------------------
    // 5. CDC: Fast to Slow (DSP -> Tx)
    // -------------------------------------------------------------------------
    Data_Fast_to_Slow #(
        .WIDTH(WIDTH),
        .FAST_FREQ(6000),   // 6 MHz 
        .SLOW_FREQ(1411)    // 1.41 MHz
    ) CDC_Tx_Left (
        .Clk_Fast(sys_clk),
        .Clk_Slow(sclk_in),
        .Rst(~rst),
        .Data_In_Fast(dsp_left),      // Read from DSP output
        .Valid_In_Fast(dsp_trigger),  // Using the same trigger for simplicity
        .Data_Out_Slow(tx_left),
        .Valid_Out_Slow(tx_load_en)
    );

    Data_Fast_to_Slow #(
        .WIDTH(WIDTH),
        .FAST_FREQ(6000), 
        .SLOW_FREQ(1411)
    ) CDC_Tx_Right (
        .Clk_Fast(sys_clk),
        .Clk_Slow(sclk_in),
        .Rst(~rst),
        .Data_In_Fast(dsp_right),     // Read from DSP output
        .Valid_In_Fast(dsp_trigger),
        .Data_Out_Slow(tx_right),
        .Valid_Out_Slow()
    );

    // -------------------------------------------------------------------------
    // 6. I2S Transmitter (Slow Domain)
    // -------------------------------------------------------------------------
    I2Stx #(WIDTH) I2Stx0 (
        .sclk(sclk_in), .rst(~rst), 
        .ws(ws_out), .sdata(sdata_out), 
        .left_chan(tx_left), .right_chan(tx_right)
    );

    assign sclk_out = sclk_in;

endmodule