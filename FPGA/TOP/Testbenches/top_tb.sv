`timescale 1ns / 1ps

module top_tb ();

logic sclk_i = 1'b1;
logic rst_n_i = 1'b0;
logic ws_i;
logic sdata_i;
logic [3:0] freqSetting_i;
logic [3:0] scaleFactor_i;
logic sclk_o;
logic ws_o;
logic sdata_o;
logic errorLED;
logic rstI2S_n;

// Clock Gen
always begin
    #5 
    sclk <= ~sclk;
end

// Reset
initial begin
    #45 rst = 0;
end




// Instantiate modules
top dut (
	. (sclk_i),
	. (rst_n_i),
	. (ws_i),
	. (sdata_i),
	. (freqSetting_i),
	. (scaleFactor_i),
	. (sclk_o),
	. (ws_o),
	. (sdata_o),
	. (errorLED),
	. (rstI2S_n)
);




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