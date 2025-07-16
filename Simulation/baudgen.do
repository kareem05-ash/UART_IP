vlib work
vlog uart_baudgen.v tb_baudgen.v
vsim -voptargs=+acc work.tb_baudgen
add wave *
run -all
#quit -sim