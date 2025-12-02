module Mixer#(
		parameter WIDTH = 16
	) (
		 input  logic clk_i, rst_n_i,
		 input  logic [WIDTH-1:0] pktWet_i,
         input  logic [WIDTH-1:0] pktDry_i,
		 output logic [WIDTH-1:0] pktMixed_o,
         output logic             pktChange_o
		);

    // Internal Logic
    logic [WIDTH-1:0] prevPktMixed;
	
	always_ff @( posedge clk ) begin
		if ( ~rst_n ) begin	
            pktMixed_o <= 0;
            pktChange_o <= 0;
        end else begin 			
            pktMixed <= (pktDry >>> 1) + (pktWet >>> 1); // Currently a 50% mix 0.5(wet+dry)

            prevPktMixed <= pktMixed;

            pktChange_o <= (pktMixed != prevPktMixed);
        end
	end
endmodule