module top #(
		parameter PKT_WIDTH = 16,	  // Required for DelayBufferFSM
		parameter BUF_DEPTH = 4410,	// Default (100 ms)
		parameter AVG_DELAY = 882	  // Default (20 ms)
) (
    input  logic sclk_i,
    input  logic rst_n_i,
    input  logic ws_i,
    input  logic sdata_i,
    input  logic [3:0] freqSetting_i,
    input  logic [3:0] scaleFactor_i,
    output logic sclk_o,
    output logic ws_o,
    output logic sdata_o,
    output logic errorLED,
    output logic rstI2S_n
);

// Internal Logic
localparam WIDTH = 16;
logic [WIDTH-1:0] rightChanIn, leftChanIn, rightChanOut;
logic i2sTxPktChanged;

// Instantiate modules

I2Srx #(WIDTH) u_I2Srx (
    .sclk_i          (sclk_i), 
    .rst_i           (rst_n_i), 
    .ws_i            (ws_i), 
    .sdata_i         (sdata_i), 
    .leftChan_o      (leftChanIn),  // unused
    .rightChan_o     (rightChanIn), 
    .pktI2SRxChanged_o (pktI2SRxChanged)
);

DSP #(
    .PKT_WIDTH(WIDTH),
    .BUF_DEPTH(BUF_DEPTH),
    .AVG_DELAY(AVG_DELAY)
  ) u_DSP (
    .rst_n             (rst_n_i),
    .clkI2S            (sclk_i),
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