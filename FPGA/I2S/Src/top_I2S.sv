module top_I2S(
    input  logic sclk_in,
    input  logic rst,
    input  logic ws_in,      // From MCU
    input  logic sdata_in,   // From MCU
    output logic sclk_out,   // To DAC
    output logic ws_out,     // To DAC
    output logic sdata_out,  // To DAC
    output logic pktI2SRxChanged_o
);

    parameter WIDTH = 16;
    logic [WIDTH-1:0] left_chan, right_chan;

    // 1. Pass-through Clocks (Crucial for synchronization)
    assign sclk_out = sclk_in;
    assign ws_out   = ws_in;

    // 2. Instantiate RX (Was missing in your file!)
    // This takes data FROM the MCU and puts it onto the internal wires.
    I2Srx #(WIDTH) I2Srx0 (
        .sclk_i(sclk_in), 
        .rst_i(rst), 
        .ws_i(ws_in), 
        .sdata_i(sdata_in), 
        .leftChan_o(left_chan), 
        .rightChan_o(right_chan), 
        .pktI2SRxChanged_o(pktI2SRxChanged_o)
    );

    // 3. Instantiate TX
    // This takes data FROM the internal wires and sends it TO the DAC.
    I2Stx #(WIDTH) I2Stx0 (
        .sclk_i(sclk_in), 
        .rst_i(rst), 
        .ws_i(ws_in),      // Correct: Listening to the input WS
        .sdata_o(sdata_out), 
        .leftChan_i(left_chan), 
        .rightChan_i(right_chan)
    );

endmodule