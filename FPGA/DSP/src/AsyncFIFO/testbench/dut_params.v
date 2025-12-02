localparam WADDR_DEPTH = 4;
localparam WDATA_WIDTH = 16;
localparam RADDR_DEPTH = 4;
localparam RDATA_WIDTH = 16;
localparam FIFO_CONTROLLER = "FABRIC";
localparam FWFT = 0;
localparam FORCE_FAST_CONTROLLER = 0;
localparam IMPLEMENTATION = "EBR";
localparam WADDR_WIDTH = 2;
localparam RADDR_WIDTH = 2;
localparam REGMODE = "reg";
localparam OREG_IMPLEMENTATION = "LUT";
localparam RESETMODE = "async";
localparam ENABLE_ALMOST_FULL_FLAG = "FALSE";
localparam ALMOST_FULL_ASSERTION = "static-dual";
localparam ALMOST_FULL_ASSERT_LVL = 3;
localparam ALMOST_FULL_DEASSERT_LVL = 2;
localparam ENABLE_ALMOST_EMPTY_FLAG = "FALSE";
localparam ALMOST_EMPTY_ASSERTION = "static-dual";
localparam ALMOST_EMPTY_ASSERT_LVL = 1;
localparam ALMOST_EMPTY_DEASSERT_LVL = 2;
localparam ENABLE_DATA_COUNT_WR = "FALSE";
localparam ENABLE_DATA_COUNT_RD = "FALSE";
localparam FAMILY = "iCE40UP";
`define ice40tp
`define iCE40UP
`define iCE40UP5K
