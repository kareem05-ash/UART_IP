`timescale 1ns/1ps
module tb_tx();
    parameter BAUD = 9600;              //baud rate per second
    parameter clk_freq = 50_000_000;    //system clk frequency
    parameter oversampling_rate = 16;   //to maintain valid data (avoiding noise)
    parameter data_wd = 8;              //data width
    parameter [1:0] parity = 0;         //1:odd-parity, 2:even-parity, default:no-parity

    reg clk;                            //system clk
    reg rst;                            //system async. active-high reset
    reg tx_start;                       //signal to initiate data (allow the transimition operation)
    reg [data_wd-1 : 0] din;            //parallel input data to be tarnsimitted
    wire tick;                          //pulse to transimit one bit (from baud generator)
    wire tx;                            //serial parallel output line
    wire tx_done;                       //flag indicates that the trans. operation is done
    wire tx_busy;                       //flag indicates that the trans. operation is excuting

    localparam IDLE   = 3'b000,         //waits for tx_start = 1
               START  = 3'b001,         //start-bit = 0
               DATA   = 3'b011,         //transimate 8-bit data : LSB (firts)
               PARITY = 3'b010,         //sending parity bit if enabled
               STOP   = 3'b110,         //stop-bit = 1
               DONE   = 3'b111;         //raise tx_done. go back to IDLE

    uart_tx #(                          //rart_tx instantiation : dut
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .oversampling_rate(oversampling_rate), 
        .data_wd(data_wd), 
        .parity(parity)
    )
    dut_tx(
        .clk(clk), 
        .rst(rst), 
        .tx_start(tx_start), 
        .tick(tick), 
        .din(din), 
        .tx(tx), 
        .tx_done(tx_done),
        .tx_busy(tx_busy)
    );

    uart_baudgen #(                     //uart_baudgen instantiation to maintain real tick signal
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .oversampling_rate(oversampling_rate)
    )
    baudgen(
        .clk(clk), 
        .rst(rst), 
        .tick(tick)
    );

    initial                             //clk generation
        begin
            clk = 0;
            forever # 10 clk = ~clk;    //forcing clk period = 20, to maintain 50 MHZ frequency
        end

    initial
        begin
            $dumpfile("wave.vcd");
            $dumpvars(0, tb_tx);
        end

    initial
        begin
            $display("\n==================== RESET ====================\n");
            rst = 1; tx_start = 0; din = 8'b0; 
            repeat(10) @(negedge clk)               //activate rst
            rst = 0;                 
            repeat(10) @(negedge clk)               //release rst

                        // scenario 1 : send a single byte (0xA5)
            $display("\n=>>> scenario 1 : send a single byte (0xA5).=============\n");
            din = 8'hA5;  tx_start = 1; @(negedge clk) ;       //IDLE => START transition    
            tx_start = 0;
            repeat(oversampling_rate) @(negedge tick);         //START => DATA transition
            repeat(oversampling_rate * data_wd)                //DATA => PARITY transition
                @(negedge tick);                
            //repeat(oversampling_rate) @(negedge tick);       //PARITY => STOP transition : uncomment this line if parity_en is high
            repeat(oversampling_rate) @(negedge tick);         //STOP => DONE transition
            if(tx_done && !tx_busy && tx)
                $display("Pass : scenario 1 (send a single byte (0xA5))");
            else 
                $display("Error : scenario 1 (send a single byte (0xA5)) | tx_done = %d, c_state = %b", tx_done, dut_tx.c_state);

                        //scenario 2 : send another byte (random)
            $display("\n=>>> scenario 2 : send another byte (random).==============\n");
            din = $random; tx_start = 1; @(negedge clk);         //IDLE => START transition  
            tx_start = 0;  
            repeat(oversampling_rate) @(negedge tick);           //START => DATA transition
            repeat(oversampling_rate * data_wd) @(negedge tick); //DATA => PARITY transition
            //repeat(oversampling_rate) @(negedge tick);         //PARITY => STOP transition : uncomment this line if parity_en is high
            repeat(oversampling_rate) @(negedge tick);           //STOP => DONE transition
            if(tx_done && !tx_busy && tx)
                $display("Pass : scenario 2 (send another byte (random))");
            else 
                $display("Error : scenario 2 (send another byte (random)) | tx_done = %d, c_state = %b", tx_done, dut_tx.c_state);

                        //scenario 3 : rst during sending a frame
            $display("\b=>>> scenario 3 : rst during sending a frame.===============\n");
            din = $random; tx_start = 1; @(negedge clk);             //IDLE => START transition    
            repeat(oversampling_rate) @(negedge tick);               //START => DATA transition
            repeat(oversampling_rate * (data_wd/2)) @(negedge tick); //DATA => PARITY transition
            rst = 1; @(negedge clk);                                 //applying rst after sending half of a single byte
            if(tx && !tx_done && !tx_busy && (dut_tx.bit_index == 0) && (dut_tx.tick_count == 0) && (dut_tx.c_state == IDLE))
                $display("Pass : scenario 3 (rst during sending a frame)");
            else
                $display("Error : scenario 3 (rst during sending a frame) | tx = %d, tx_done = %d, tx_busy = %d, bit_index = %d, tick_count = %d, c_state = %b", 
                        tx, tx_done, tx_busy, dut_tx.bit_index, dut_tx.tick_count, dut_tx.c_state);
            #100; $stop;
        end

    initial
        $monitor("@time (%t) : c_state = %b, tx_done = %d, tx_busy = %d, tx = %d", $time, dut_tx.c_state, tx_done, tx_busy, tx);
endmodule