-L work
-reflib pmi_work
-reflib ovi_ice40up


"C:/Users/roman/Documents/GitHub/E155Project/FPGA/Src/I2Srx.sv" 
"C:/Users/roman/Documents/GitHub/E155Project/FPGA/Testbench/I2Srx_tb.sv" 
-sv
-optionset VOPTDEBUG
+noacc+pmi_work.*
+noacc+ovi_ice40up.*

-vopt.options
  -suppress vopt-7033
-end

-gui
-top i2s_rx_tb
-vsim.options
  -suppress vsim-7033,vsim-8630,3009,3389
-end

-do "view wave"
-do "add wave /*"
-do "run -all"
