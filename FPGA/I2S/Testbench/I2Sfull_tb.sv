module i2s_tb ();

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
I2Stx #(WIDTH) I2Stx0 (sclk, rst, ws, sdata, left_tx_chan, right_tx_chan);
I2Srx #(WIDTH) I2Srx0 (sclk, rst, ws, sdata, left_rx_chan, right_rx_chan, pktI2SRxChanged_o);

// Test data transfer
initial begin
    // Load transmit channels
	left_tx_chan  = 16'hdead;
	right_tx_chan = 16'hbeef;

    //Sync to reset stage
	@(negedge rst);

    // Transfer left data
	@(posedge ws);

    //Transfer right data
	@(negedge ws);

    
	@(posedge sclk);
	@(negedge sclk);
	if (left_rx_chan == left_tx_chan && right_rx_chan == right_tx_chan)
		$display("Test passed!");
	else
		$display("Test failed! Recieved (L):%h, (R):%h; Sent (L):%h, (R):%h", left_rx_chan, right_rx_chan, left_tx_chan, right_tx_chan);
	#100 $stop();
end

endmodule