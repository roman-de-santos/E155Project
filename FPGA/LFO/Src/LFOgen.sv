module LFOgen (
    input  logic       clk_i,
    input  logic       rst_n_i,
    input  logic [3:0] freqSetting_i,      // Stepsize, Determines Frequency
    input  logic [3:0] scaleFactor_i,      // 0000=0.0, 1111=1.0
    input  logic       FIFOupdate_i,
    
    output logic signed [13:0] wave_o,
    output logic newValFlag_o
);

    // Phase Accumulator
    logic [31:0] phaseAcc;

    // Stepsize
    logic [31:0] tuningVal;

    // Wave scaling
    logic signed [15:0] preWave;
    logic signed [18:0] multResult;
    

    reg signed [15:0] LUT [0:4095];
    
    // Load the LUT
	// Synthesis path: ./LFO-LUTs/sineFixed(256).mem
	// Sim Path:       ../../../../Src/LFO-LUTs/sineFixed(256).mem
    initial $readmemh("sineFixed(256).mem", LUT); // top_tb.sv sim path

    // Frequency Tuning Values (Calculated for 44.1kHz sample rate)
    // These remain the same regardless of LUT size because the PhaseAcc is still 32-bit
    always_comb begin
        case (freqSetting_i)
            4'b0000: tuningVal = 32'd9739;    // 0.1 Hz
            4'b0001: tuningVal = 32'd38957;   // 0.4 Hz
            4'b0010: tuningVal = 32'd68174;   // 0.7 Hz
            4'b0011: tuningVal = 32'd97392;   // 1.0 Hz
            4'b0100: tuningVal = 32'd126609;  // 1.3 Hz
            4'b0101: tuningVal = 32'd155826;  // 1.6 Hz
            4'b0110: tuningVal = 32'd185044;  // 1.9 Hz
            4'b0111: tuningVal = 32'd214261;  // 2.2 Hz
            4'b1000: tuningVal = 32'd243479;  // 2.5 Hz
            4'b1001: tuningVal = 32'd272696;  // 2.8 Hz
            4'b1010: tuningVal = 32'd301914;  // 3.1 Hz
            4'b1011: tuningVal = 32'd331131;  // 3.4 Hz
            4'b1100: tuningVal = 32'd360349;  // 3.7 Hz
            4'b1101: tuningVal = 32'd389566;  // 4.0 Hz
            4'b1110: tuningVal = 32'd418784;  // 4.3 Hz
            4'b1111: tuningVal = 32'd448001;  // 4.6 Hz
            default: tuningVal = 32'd486958;  // 5.0 Hz
        endcase
    end

    always @(posedge clk_i) begin
        if (~rst_n_i) begin
            phaseAcc   	 <= '0;
            wave_o     	 <= '0;
			preWave    	 <= '0;
			multResult 	 <= '0;	
			newValFlag_o <= 1'b0;

        end else if (FIFOupdate_i) begin
            // 1. Increment Phase
            phaseAcc <= phaseAcc + tuningVal; 
            
            // --- CHANGE 3: Indexing Logic ---
            // Use [31:20] (Top 12 bits) to access 4096 entries
            // LUT[idx][13] is the sign bit (assuming 14-bit data in LUT)
            preWave <= {{2{LUT[phaseAcc[31:20]][13]}}, LUT[phaseAcc[31:20]][13:0]};
            
            // 2. Scale
            // preWave is 16-bit signed. scaleFactor is unsigned 4-bit treated as fraction
            multResult <= preWave * $signed({1'b0, scaleFactor_i});
            
            // 3. Normalize output
            wave_o <= multResult[18:5];
            newValFlag_o <= 1;
            
        end else begin
            // Hold values
            phaseAcc     <= phaseAcc;
            wave_o       <= wave_o;
            preWave      <= preWave;
            multResult   <= multResult;  
            newValFlag_o <= 1'b0;
        end
    end

endmodule