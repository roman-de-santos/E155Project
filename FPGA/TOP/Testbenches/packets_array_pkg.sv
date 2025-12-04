// Dummy packets for testing a buffer
package packets_array_pkg;
    parameter SIZE = 100;

    typedef logic [15:0] pkt_t;

    // Define the type for an array of SIZE data_t elements (unpacked array)
    // Indices will range from [SIZE-1:0], which is [99:0] for SIZE=100.
    typedef pkt_t packets_array_t [0:SIZE-1];

    // Define the constant array with 100 unique values.
    const packets_array_t CONST_DATA_ARRAY = '{
        // --- Explicitly Defined Unique Values (Indices 0 - 9) ---
        16'hAAAA,  // Index 0
        16'hBBBB,  // Index 1
        16'hCCCC,  // Index 2
        16'hDDDD,  // Index 3
        16'hEEEE,  // Index 4
        16'hFFFF,  // Index 5
        16'h1234,  // Index 6
        16'h5678,  // Index 7
        16'h9999,  // Index 8
        16'h2468,  // Index 9
        
        // --- Sequential Unique Values (Indices 10 - 99) ---
        // Using an easily verifiable pattern (h100A, h100B, h100C, ...)
        16'h100A, 16'h100B, 16'h100C, 16'h100D, 16'h100E, 16'h100F, 16'h1010, 16'h1011, 16'h1012, 16'h1013, 
        16'h1014, 16'h1015, 16'h1016, 16'h1017, 16'h1018, 16'h1019, 16'h101A, 16'h101B, 16'h101C, 16'h101D, 
        16'h101E, 16'h101F, 16'h1020, 16'h1021, 16'h1022, 16'h1023, 16'h1024, 16'h1025, 16'h1026, 16'h1027, 
        16'h1028, 16'h1029, 16'h102A, 16'h102B, 16'h102C, 16'h102D, 16'h102E, 16'h102F, 16'h1030, 16'h1031, 
        16'h1032, 16'h1033, 16'h1034, 16'h1035, 16'h1036, 16'h1037, 16'h1038, 16'h1039, 16'h103A, 16'h103B, 
        16'h103C, 16'h103D, 16'h103E, 16'h103F, 16'h1040, 16'h1041, 16'h1042, 16'h1043, 16'h1044, 16'h1045, 
        16'h1046, 16'h1047, 16'h1048, 16'h1049, 16'h104A, 16'h104B, 16'h104C, 16'h104D, 16'h104E, 16'h104F, 
        16'h1050, 16'h1051, 16'h1052, 16'h1053, 16'h1054, 16'h1055, 16'h1056, 16'h1057, 16'h1058, 16'h1059, 
        16'h105A, 16'h105B, 16'h105C, 16'h105D, 16'h105E, 16'h105F, 16'h1060, 16'h1061, 16'h1062, 16'h1063
    };
endpackage