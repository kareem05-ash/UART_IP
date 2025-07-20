vlib work
vlog fifo.v tb_fifo.v
vsim -voptargs=+acc work.tb_fifo
add wave *
run -all
#quit -sim