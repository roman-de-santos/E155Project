-L work
-reflib pmi_work
-reflib ovi_ice40up


"C:/Git/E155Project/FPGA/Src/I2Srx.sv" 
"C:/Git/E155Project/FPGA/Src/I2Stx.sv" 
"C:/Git/E155Project/FPGA/Src/top.sv" 
"C:/Git/E155Project/FPGA/Src/Data_Fast_to_Slow.sv" 
"C:/Git/E155Project/FPGA/Src/Fast_to_Slow_CDC.sv" 
"C:/Git/E155Project/FPGA/Src/Data_Slow_to_Fast.sv" 
"C:/Git/E155Project/FPGA/Testbench/Data_Slow_to_Fast_tb.sv" 
-sv
-optionset VOPTDEBUG
+noacc+pmi_work.*
+noacc+ovi_ice40up.*

-vopt.options
  -suppress vopt-7033
-end

-gui
-top Data_Slow_to_Fast_tb
-vsim.options
  -suppress vsim-7033,vsim-8630,3009,3389
-end

-do "view wave"
-do "add wave /*"
-do "run -all"
