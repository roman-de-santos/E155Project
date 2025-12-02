onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /CDC_STF_tb/clkI2SBit_i
add wave -noupdate /CDC_STF_tb/clkDSP_i
add wave -noupdate /CDC_STF_tb/rstDSP_n_i
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/rst_i
add wave -noupdate -radix decimal /CDC_STF_tb/test_num
add wave -noupdate /CDC_STF_tb/pktI2S_i
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/wr_data_i
add wave -noupdate /CDC_STF_tb/pktValidI2S_i
add wave -noupdate /CDC_STF_tb/DUT/wrEN_comb
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/wr_en_i
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/rd_en_i
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/rd_data_o
add wave -noupdate /CDC_STF_tb/DUT/fifoPktOut_reg
add wave -noupdate /CDC_STF_tb/DUT/fifoPktOut_old_reg
add wave -noupdate /CDC_STF_tb/DUT/pktChangedDSP_comb_o
add wave -noupdate /CDC_STF_tb/pktDSP_reg_o
add wave -noupdate /CDC_STF_tb/DUT/fifoEmpty_comb
add wave -noupdate /CDC_STF_tb/DUT/fifoFull_comb
add wave -noupdate /CDC_STF_tb/errors
add wave -noupdate -radix decimal /CDC_STF_tb/sent_cnt
add wave -noupdate /CDC_STF_tb/received_cnt
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/CKW}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/WE}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/DI}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/CKR}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/RE}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/DO}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/CEW}
add wave -noupdate {/CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/EBR/EBR_OTHER/u_fifo_mem0/mem_main/NON_MIX/ADDR_ROUTE[0]/DATA_ROUTE[0]/no_init/u_mem0/ICE_MEM/u_mem0/CER}
add wave -noupdate /CDC_STF_tb/PUR_INST/PUR_N
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/wr_data_i
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/rd_data_o
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/rd_grey_w
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/rd_grey_sync_r
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/wp_sync_w
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/wr_grey_w
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/wr_grey_sync_r
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/rp_sync1_r
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/rp_sync2_r
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/empty_nxt_c
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/wrst_empty_sync_w
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/empty_cmp_w
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/empty_r
add wave -noupdate /CDC_STF_tb/DUT/CDC_AFIFO_STF/lscc_fifo_dc_inst/fifo_dc0/_FABRIC/u_fifo/empty_ext_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {14480373 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {12884392 ps} {18592404 ps}
