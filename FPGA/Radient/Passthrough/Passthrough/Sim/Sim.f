-L work
-reflib pmi_work
-reflib ovi_ice40up


"C:/Users/roman/Documents/GitHub/E155Project/FPGA/Src/LFOgen.sv" 
"C:/Users/roman/Documents/GitHub/E155Project/FPGA/Testbench/LFOgen_tb.sv" 
-sv
-optionset VOPTDEBUG
+noacc+pmi_work.*
+noacc+ovi_ice40up.*

-vopt.options
  -suppress vopt-7033
-end

-gui
-top LFOgen_tb
-vsim.options
  -suppress vsim-7033,vsim-8630,3009,3389
-end

-do "view wave"
-do "add wave /*"
-do "run -all"
