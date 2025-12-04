onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi_integration_tb/clk
add wave -noupdate /axi_integration_tb/rst_n
add wave -noupdate /axi_integration_tb/start_write
add wave -noupdate /axi_integration_tb/start_read
add wave -noupdate /axi_integration_tb/addr_in
add wave -noupdate /axi_integration_tb/data_in
add wave -noupdate /axi_integration_tb/data_out
add wave -noupdate /axi_integration_tb/done
add wave -noupdate /axi_integration_tb/error
add wave -noupdate /axi_integration_tb/awaddr
add wave -noupdate /axi_integration_tb/awvalid
add wave -noupdate /axi_integration_tb/awready
add wave -noupdate /axi_integration_tb/wdata
add wave -noupdate /axi_integration_tb/wstrb
add wave -noupdate /axi_integration_tb/wvalid
add wave -noupdate /axi_integration_tb/wready
add wave -noupdate /axi_integration_tb/bresp
add wave -noupdate /axi_integration_tb/bvalid
add wave -noupdate /axi_integration_tb/bready
add wave -noupdate /axi_integration_tb/araddr
add wave -noupdate /axi_integration_tb/arvalid
add wave -noupdate /axi_integration_tb/arready
add wave -noupdate /axi_integration_tb/rdata
add wave -noupdate /axi_integration_tb/rresp
add wave -noupdate /axi_integration_tb/rvalid
add wave -noupdate /axi_integration_tb/rready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 198
configure wave -valuecolwidth 202
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
WaveRestoreZoom {0 ps} {971250 ps}
