vlib work
vlog uart_top.v tb_top.v
vsim -voptargs=+acc work.tb_top
add wave *
run -all
#quit -sim