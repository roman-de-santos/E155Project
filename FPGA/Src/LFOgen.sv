module LFOgen (
    input  logic clk,
    input  logic reset,
    input  logic [3:0] freqSetting,      // Stepsize, Determines Frequency
    input  logic [3:0] scaleFactor,      // 0000=0.0, 1111=1.0
    output logic signed [15:0] waveOut
);

    // Phase Accumulator
    logic [31:0] phaseAcc;

    // Stepsize
    logic [31:0] tuningVal;

    // Wave scaling
    logic signed [15:0] preWave;
    logic signed [20:0] multResult;
    
    // Memory Array (256 Resolution, 16 bit width)
    reg signed [15:0] LUT [0:255];
    
    // Load the LUT
    initial $readmemh("./LFO-LUTs/sineFixed(256).mem", LUT);

    // Generate a 48kHz signal to read LUT
    logic [6:0] counter; // 6MHz to 48kHz (pulse every 125 cycles on the 6MHz clock)
    logic       tick48k;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 7'd0;
            tick48k <= 1'b0;
        end else begin
            if (counter == 7'd124) begin
                counter <= 7'd0;
                tick48k <= 1'b1; // Pulse high for one cycle
            end else begin
                counter <= counter + 1'b1;
                tick48k <= 1'b0;
            end
        end
    end

    // For initial testing we are using a dip switch
    // These values are precomputed tuningVal = (f_target) *(2^32) / (48*10^3)
    always_comb begin
        case (freqSetting)
            4'b0000: tuningVal = 32'd8948;   // 0.1 Hz
            4'b0001: tuningVal = 32'd35791;  // 0.4 Hz
            4'b0010: tuningVal = 32'd62635;  // 0.7 Hz
            4'b0011: tuningVal = 32'd89478;  // 1.0 Hz
            4'b0100: tuningVal = 32'd116322; // 1.3 Hz
            4'b0101: tuningVal = 32'd143166; // 1.6 Hz
            4'b0110: tuningVal = 32'd170009; // 1.9 Hz
            4'b0111: tuningVal = 32'd196853; // 2.2 Hz
            4'b1000: tuningVal = 32'd223696; // 2.5 Hz
            4'b1001: tuningVal = 32'd250540; // 2.8 Hz
            4'b1010: tuningVal = 32'd277383; // 3.1 Hz
            4'b1011: tuningVal = 32'd304227; // 3.4 Hz
            4'b1100: tuningVal = 32'd331070; // 3.7 Hz
            4'b1101: tuningVal = 32'd357914; // 4.0 Hz
            4'b1110: tuningVal = 32'd384757; // 4.3 Hz
            4'b1111: tuningVal = 32'd411601; // 4.6 Hz
            default: tuningVal = 32'd447392; // 5.0 Hz
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            phaseAcc <= 0;
            waveOut <= 0;

        end else if (tick48k) begin
            phaseAcc <= phaseAcc + tuningVal; // add stepsize
            preWave <= LUT[phaseAcc[31:24]];

            multResult <= preWave * $signed({1'b0, scaleFactor});

            // Normalize (scaleFactor = 0b1111 becomes 0d1)
            // dividing by 16 is a good approximation that saves on hardware and improves speed
            // Actual: (scaleFactor = 0b1111 becomes decimal 0.9375)
            waveOut <= multResult[20:4];
        end
    end

endmodule