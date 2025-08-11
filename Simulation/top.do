vlib work
vlog uart_top.v tb_top.v
vsim -voptargs=+acc work.tb_top
add wave *
# log file for transcript output
transcript file "trans_out.log"
run -all
#quit -sim