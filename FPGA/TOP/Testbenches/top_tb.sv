module top_tb ();

parameter WIDTH = 16;
logic ws;
logic sdata;
logic [WIDTH-1:0] left_tx_chan;
logic [WIDTH-1:0] right_tx_chan;
logic [WIDTH-1:0] left_rx_chan;
logic [WIDTH-1:0] right_rx_chan;
logic sclk = 1'b1;
logic rst = 1'b1;
logic prescaler = 16;
logic pktI2SRxChanged_o;
logic [3:0] freqSetting_i;
logic [3:0] scaleFactor_i;
logic [WIDTH-1:0] i2sTxPkt_o;
logic i2sTxPktChanged_o;
logic errorLED_o;

// Clock Gen
always begin
    #5 
    sclk <= ~sclk;
end

// Reset
initial begin
    #95 rst = 0;
end


// Instantiate modules
I2Srx #(WIDTH) I2Srx0 (sclk, rst, ws, sdata, left_rx_chan, right_rx_chan, pktI2SRxChanged_o);
DSP   #(WIDTH) DSP0   (rst, sclk, rst, right_rx_chan, pktI2SRxChanged_o, freqSetting_i, scaleFactor_i,
						i2sTxPkt_o, i2sTxPktChanged_o, errorLED_o);
I2Stx #(WIDTH) I2Stx0 (sclk, rst, ws, sdata, left_tx_chan, i2sTxPkt_o);




// Test data transfer
initial begin
    // Load transmit channels
	left_tx_chan  = 16'hdead;
	right_tx_chan = 16'hbeef;
	freqSetting_i = 4'b0001;
	scaleFactor_i = 4'b0001;


    //Sync to reset stage
	@(negedge rst);

    // Transfer left data
	@(posedge ws);

    //Transfer right data
	@(negedge ws);

	left_tx_chan  = 16'hbeef;
	right_tx_chan = 16'hdead;
    
	@(posedge sclk);
	@(negedge sclk);
	#100 $stop();
end

endmodule