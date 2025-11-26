// Lucas Lemos - llemos@hmc.edu - 11/25/2025
// This module synchronizes an 1-bit asynchronous input (e.g. a button press) to the system clock.

module synchronizer (
				 input  logic clk, rst_n,
				 input  logic d_a,
				 output logic q
				 );

	logic d_b;
	
	always_ff @( posedge clk ) begin
		if ( ~rst_n ) 	d_b <= 0;
		else 			d_b <= d_a;
	end
	
	always_ff @( posedge clk ) begin
		if ( ~rst_n )	q <= 0;
		else			q <= d_b;
	end
endmodule