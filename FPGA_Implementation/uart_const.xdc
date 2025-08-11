# Kareem Ashraf Mostafa
# kareem.ash05@gmail.com
# github.com/kareem05-ash
# +201002321067

# FPGA Implementation

# Clock signals
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

# Switches
## Inputs
set_property -dict { PACKAGE_PIN V17 	IOSTANDARD LVCMOS33 } [get_ports {din[0]}]
set_property -dict { PACKAGE_PIN V16 	IOSTANDARD LVCMOS33 } [get_ports {din[1]}]
set_property -dict { PACKAGE_PIN W16 	IOSTANDARD LVCMOS33 } [get_ports {din[2]}]
set_property -dict { PACKAGE_PIN W17 	IOSTANDARD LVCMOS33 } [get_ports {din[3]}]
set_property -dict { PACKAGE_PIN W15 	IOSTANDARD LVCMOS33 } [get_ports {din[4]}]
set_property -dict { PACKAGE_PIN V15 	IOSTANDARD LVCMOS33 } [get_ports {din[5]}]
set_property -dict { PACKAGE_PIN W14 	IOSTANDARD LVCMOS33 } [get_ports {din[6]}]
set_property -dict { PACKAGE_PIN W13  	IOSTANDARD LVCMOS33 } [get_ports {din[7]}]
set_property -dict { PACKAGE_PIN V17 	IOSTANDARD LVCMOS33 } [get_ports {tx_wr_en}]
set_property -dict { PACKAGE_PIN V16 	IOSTANDARD LVCMOS33 } [get_ports {tx_rd_en}]
set_property -dict { PACKAGE_PIN W16 	IOSTANDARD LVCMOS33 } [get_ports {rx_wr_en}]
set_property -dict { PACKAGE_PIN W17 	IOSTANDARD LVCMOS33 } [get_ports {rx_rd_en}]
set_property -dict { PACKAGE_PIN W15 	IOSTANDARD LVCMOS33 } [get_ports {tx_start}]
set_property -dict { PACKAGE_PIN V15 	IOSTANDARD LVCMOS33 } [get_ports {rx_start}]

# LEDs
## Ouputs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {dout[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {dout[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {dout[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {dout[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {dout[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {dout[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {dout[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {dout[7]}]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports {tx_full}]
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports {tx_empty}]
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports {tx_almost_full}]
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports {tx_almost_empty}]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports {rx_full}]
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports {rx_empty}]
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports {rx_almost_full}]
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports {rx_almost_empty}]

# 7-Segment Display
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {framing_error_flag}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {parity_error_flag}]
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {rx_done}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {rx_busy}]
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {tx_done}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {tx_busy}]

# Buttons
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports rst]

# Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# SPI configuration mode options for QSPI boot, can be used for all designs
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]