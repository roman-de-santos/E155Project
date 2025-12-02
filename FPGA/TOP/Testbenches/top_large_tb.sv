module top_tb ();

// Module Signals
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

// Width
localparam WIDTH = 16;

// Clock gen (44.1kHz)
localparam sclkTs = 709;

always begin
    #sclkTs 
    sclk_i <= ~sclk_i;
end

// Instantiate modules
top dut (
	.sclk_i         (sclk_i),
	.rst_n_i        (rst_n_i),
	.ws_i           (ws_i),
	.sdata_i        (sdata_i),
	.freqSetting_i  (freqSetting_i),
	.scaleFactor_i  (scaleFactor_i),
	.sclk_o         (sclk_o),
	.ws_o           (ws_o),
	.sdata_o        (sdata_o),
	.errorLED       (errorLED),
	.rstI2S_n       (rstI2S_n)
);

task send_i2s_frame(
        input [WIDTH-1:0] left_data,
        input [WIDTH-1:0] right_data
    );
    begin
        // --- Left Channel (WS=0) ---
        @ (negedge sclk_i);
        ws_i <= 0;
        @ (negedge sclk_i);

        // Send bits MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata_i <= left_data[i];
            
            // Standard I2S: WS transitions 1 cycle before the MSB of the NEXT channel
            // So we toggle it during the LSB of the CURRENT channel
            if (i == 0) begin 
                ws_i <= 1;
            end
            @ (negedge sclk_i);
        end
        
        // --- Right Channel (WS=1) ---
        // Note: WS was already set to 1 in the previous loop's LSB
        
        // Send bits MSB first
        for (int i = WIDTH - 1; i >= 0; i--) begin
            sdata_i <= right_data[i];
            
            if (i == 0) begin 
                ws_i <= 0; // Prepare WS for the next Left channel
            end
            @ (negedge sclk_i);
        end
        
        // End of Frame cleanup
        sdata_i <= 0;
    end
    endtask

    initial begin
        $display("Starting I2S Generation Test...");

        rst_n_i = 0;    // Assert reset
        ws_i = 0;     // Initialize signals
        sdata_i = 0;
        #100;       
        rst_n_i = 1;  

		// Test different settings
		freqSetting_i = 4'b0001;
		scaleFactor_i = 4'b0100;  

        @ (posedge sclk_i); // Wait for one clock edge
        
        $display("Reset complete. Starting test cases...");
        
        // Initialize Signals
        ws_i = 0;
        sdata_i = 0;

        // Loop from 0 to 2000
        for (int k = 0; k <= 2000; k++) begin
            
            // Send the I2S Frame (Left = k, Right = k)
            send_i2s_frame(k[15:0], k[15:0]);
            
            // Wait the requested delay between frames
            // Note: This creates a "gap" in the audio stream
            #(sclkTs * 100); 
        end

        $display("Test Complete.");
        $finish;
    end

endmodule