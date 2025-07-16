vlib work
vlog uart_tx.v tb_tx.v
vsim -voptargs=+acc work.tb_tx
add wave *
run -all
#quit -sim