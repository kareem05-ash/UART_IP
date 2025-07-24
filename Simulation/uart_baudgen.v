////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
`timescale 1ns/1ps
module uart_baudgen#
(
    parameter BAUD = 9600, 
    parameter clk_freq = 50_000_000, 
    parameter oversampling_rate = 16
)
(
    input clk,            //system clock = 50 MHZ
    input rst,           //system async reset (active-high)
    output reg tick     //high pulse for one cycle every (clk_freq/BAUD) clk cycles
);
    localparam clk_cycles = clk_freq/(BAUD * oversampling_rate);  //number of clk cycles needed to get tick pulse
    localparam no_bits = $clog2(clk_cycles);                     //number of bits needed to represent clk_cycles
    reg [no_bits-1 : 0] count;                                  //counts clk cycles 

    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    tick <= 0;
                    count <= 0;
                end
            else if(count == clk_cycles-1)
                begin
                    count <= 0;
                    tick <= 1;
                end
            else
                begin
                    count <= count + 1;
                    tick <= 0;
                end
        end 
endmodule