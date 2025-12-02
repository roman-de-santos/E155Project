module top(
    input  logic sclk_i,
    input  logic rst_n_i,
    input  logic ws_i,
    input  logic sdata_i,
    input  logic [3:0] freqSetting_i,
    input  logic [3:0] scaleFactor_i,
    output logic sclk_o,
    output logic ws_o,
    output logic sdata_o
           );

// Internal Logic
localparam WIDTH = 16;
logic [WIDTH-1:0] leftChan_o, rightChan_o, leftChan, rightChanIn;
logic i2sTxPktChanged;
logic rstI2S_n;
logic errorLED;

// Instantiate modules

I2Srx #(WIDTH) I2Srx0 (
    .sclk_i          (sclk_i), 
    .rst_i           (rst_n_i), 
    .ws_i            (ws_i), 
    .sdata_i         (sdata_i), 
    .leftChan_o      (leftChanIn), 
    .rightChan_o     (rightChanIn), 
    .pktI2SRxChanged (pktI2SRxChanged)
);

DSP #(PKT_WIDTH = WIDTH) u_DSP (
    .rst_n              (rst_n_i),
    .clkI2s            (sclk_i),
    .i2sRxPkt_i        (rightChanIn),
    .pktI2SRxChanged_i (pktI2SRxChanged),
    .freqSetting_i     (freqSetting_i),
    .scaleFactor_i     (scaleFactor_i),
    .i2sTxPkt_o        (rightChanOut),
    .i2sTxPktChanged_o (i2sTxPktChanged),
    .rstI2S_n_o        (rstI2S_n),
    .errorLED_o        (errorLED)
);

I2Stx #(WIDTH) u_I2Stx (
    .sclk_i      (sclk_i), 
    .rst_i       (rst_n_i), 
    .ws_o        (ws_o), 
    .sdata_o     (sdata_o), 
    .leftChan_i  (rightChanIn), 
    .rightChan_i (rightChanOut)
);

assign sclk_o = sclk_i;

endmodule