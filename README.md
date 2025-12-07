# E155Project
Micro P's Final Project, Chorus Effect Guitar Pedal 

Website: https://roman-de-santos.github.io/E155Project/


* `FPGA/`:
    * `DSP/` Contains the chorus effect DSP algorithm with testbenches
    * `I2S/` Contains I2S tx and rx module along with all testbench files
    * `LFO/` Folder with the code to generate low frequency oscilations with a look up table
    * `TOP/` A folder with all of the top module files and testbenches for the top module.
* `LTspice/`:
    * Analog simulation files to verify circuit
* `MCU/STMcubeMX/`:
    * `core/` contains the src files and header files for the HAL library
    * `STMcubeMX.ioc` configuration file for HAL library
* `Quarto/`:
    * All of the website files for the project
* `kiCAD/tremolo_guitar_pedal`:
    * All of the kiCAD files for this project, including source and rendered schematics
