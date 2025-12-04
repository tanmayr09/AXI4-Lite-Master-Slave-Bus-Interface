onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {System Signals}
add wave -noupdate /axi_master_simple_tb/clk
add wave -noupdate /axi_master_simple_tb/rst_n
add wave -noupdate -divider {Control Signals}
add wave -noupdate /axi_master_simple_tb/start_write
add wave -noupdate /axi_master_simple_tb/start_read
add wave -noupdate /axi_master_simple_tb/done
add wave -noupdate /axi_master_simple_tb/error
add wave -noupdate /axi_master_simple_tb/addr_in
add wave -noupdate /axi_master_simple_tb/data_in
add wave -noupdate /axi_master_simple_tb/data_out
add wave -noupdate -divider {Write Address Channel (AW)}
add wave -noupdate -radix binary /axi_master_simple_tb/awaddr
add wave -noupdate /axi_master_simple_tb/awvalid
add wave -noupdate /axi_master_simple_tb/awready
add wave -noupdate -divider {Write Data Channel (W)}
add wave -noupdate /axi_master_simple_tb/wdata
add wave -noupdate /axi_master_simple_tb/wstrb
add wave -noupdate /axi_master_simple_tb/wvalid
add wave -noupdate /axi_master_simple_tb/wready
add wave -noupdate -divider {Write Respone Channel (B)}
add wave -noupdate /axi_master_simple_tb/bresp
add wave -noupdate /axi_master_simple_tb/bvalid
add wave -noupdate /axi_master_simple_tb/bready
add wave -noupdate -divider {Read Address Channel (AR)}
add wave -noupdate /axi_master_simple_tb/araddr
add wave -noupdate /axi_master_simple_tb/arvalid
add wave -noupdate /axi_master_simple_tb/arready
add wave -noupdate -divider {Read Data Channel (R)}
add wave -noupdate /axi_master_simple_tb/rdata
add wave -noupdate /axi_master_simple_tb/rresp
add wave -noupdate /axi_master_simple_tb/rvalid
add wave -noupdate /axi_master_simple_tb/rready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Start of Write Address Phase } {74701 ps} 0} {{Start of Write Data Phase} {95275 ps} 0} {{Start of Write Response Phase } {110152 ps} 0} {{Start of Read Address Phase } {200362 ps} 0} {{Start of Read Data Phase } {230000 ps} 0}
quietly wave cursor active 5
configure wave -namecolwidth 231
configure wave -valuecolwidth 199
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {304500 ps}
