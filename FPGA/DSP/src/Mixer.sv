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
    logic [WIDTH-1:0] pktMixed, prevPktMixed;
	
	always_ff @( posedge clk_i) begin
		if ( ~rst_n_i ) begin	
            pktMixed_o <= 0;
            pktChange_o <= 0;
        end else begin 			
            pktMixed <= (pktDry_i >>> 1) + (pktWet_i >>> 1); // Currently a 50% mix 0.5(wet+dry)

            prevPktMixed <= pktMixed_o;

            pktChange_o <= (pktMixed_o != prevPktMixed);
        end
	end
endmodule