vlib work
vlog uart_top.v tb_top.v
vsim -voptargs=+acc work.tb_top
add wave *
add wave -position insertpoint sim:/tb_top/DUT/fifo_tx/fifo
add wave -position insertpoint sim:/tb_top/DUT/fifo_rx/fifo
add wave -position insertpoint sim:/tb_top/DUT/tick
run -all
#quit -sim