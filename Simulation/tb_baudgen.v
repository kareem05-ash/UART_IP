////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_baudgen(); 
    parameter BAUD = 9600;
    parameter clk_freq = 50_000_000;
    parameter oversampling_rate = 16;
    reg clk;            //system clock = 50 MHZ
    reg rst;           //system async reset (active-high)
    wire tick;        //high pulse for one cycle every (clk_freq/BAUD) clk cycles

    localparam clk_cycles = clk_freq/(BAUD * oversampling_rate);  //number of clk cycles needed to get tick pulse
    localparam no_bits = $clog2(clk_cycles);                     //number of bits needed to represent clk_cycles

    uart_baudgen #(
        .BAUD(BAUD), 
        .clk_freq(clk_freq)
    )
    dut_baudgen(
        .clk(clk), 
        .rst(rst), 
        .tick(tick)
    );

    initial         //clk generation with freq = 50 MHZ
        begin
            clk = 0;
            forever #10 clk = ~clk;
        end
    
    initial         //stimulus
        begin
            repeat(10) begin
                rst = 1; @(negedge clk);   //activate rst
                rst = 0;                   //release rst
                repeat(clk_cycles) @(negedge clk);        //waits for the needed clk cycles to get tick pusle
                if(tick)
                    $display("Pass : tick = %d after %d cycles , count = %d", tick, clk_cycles, dut_baudgen.count);
                else
                    $display("Error : tick = %d after %d cycles , count = %d", tick, clk_cycles, dut_baudgen.count);
                @(negedge clk);                          //waits for one more clk cycle to track tick if not low
                if(!tick)
                    $display("Pass : tick = %d after one more cycle , count = %d", tick, dut_baudgen.count);
                else
                    $display("Error : tick = %d after one more cycle , count = %d", tick, dut_baudgen.count);
            end
            #100; $stop;                             //stop simulation
        end
endmodule