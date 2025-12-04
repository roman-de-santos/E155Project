module Mixer#(
		parameter WIDTH = 16
	) (
		input  logic 				clk_i, rst_n_i,
		input  logic [WIDTH-1:0] 	pktWet_i,
		input  logic [WIDTH-1:0] 	pktDry_i,
		input  logic 				pktWetChanged_i,
		 
		output logic [WIDTH-1:0] 	pktMixed_o,
		output logic             	pktMixedChanged_o
	);

    // Internal Logic
    //logic [WIDTH-1:0] prevPktMixed;
	
	always_ff @( posedge clk_i) begin
		if ( ~rst_n_i ) begin	
            pktMixed_o 	 <= 0;
			//prevPktMixed <= 0;
        end else if (pktWetChanged_i) begin 			
            pktMixed_o <= (pktDry_i >>> 1) + (pktWet_i >>> 1); // Currently a 50% mix 0.5(wet+dry)
			pktMixedChanged_o <= 1;
		end else begin
			pktMixedChanged_o <= 0;
        end
	end
	//assign pktMixedChanged_o = (pktMixed_o != prevPktMixed);
endmodule