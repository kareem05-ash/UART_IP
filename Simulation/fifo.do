vlib work
vlog fifo.v tb_fifo.v
vsim -voptargs=+acc work.tb_fifo
add wave *
add wave -position insertpoint dut_fifo/fifo
run -all
#quit -sim