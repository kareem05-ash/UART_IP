vlib work
vlog uart_rx.v tb_rx.v
vsim -voptargs=+acc work.tb_rx
add wave *
run -all
#quit -sim