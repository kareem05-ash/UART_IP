vlib work
vlog uart_top.v tb_top.v
vsim -voptargs=+acc work.tb_top
add wave *
# add internal signals to the waveform
add wave -position insertpoint sim:/tb_top/DUT/fifo_tx/fifo
add wave -position insertpoint sim:/tb_top/DUT/fifo_rx/fifo
add wave -position insertpoint sim:/tb_top/DUT/tick
# store transcript output
transcript file "trans_out.log"
run -all
#quit -sim