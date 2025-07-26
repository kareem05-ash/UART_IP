////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_tx();
    parameter BAUD = 9600;                          //baud rate per second
    parameter clk_freq = 50_000_000;                //system clk frequency
    parameter clk_period = 1_000_000_000/clk_freq;  //system clk period in 'ns'
    parameter oversampling_rate = 16;               //to maintain valid data (avoiding noise)
    parameter data_wd = 8;                          //data width
    parameter [1:0] parity = 1; //odd-parity        //1:odd-parity, 2:even-parity, default:no-parity

    reg clk;                                        //system clk
    reg rst;                                        //system async. active-high reset
    reg tx_start;                                   //signal to initiate data (allow the transimition operation)
    reg [data_wd-1 : 0] din;                        //parallel input data to be tarnsimitted
    wire tick;                                      //pulse to transimit one bit (from baud generator)
    wire tx;                                        //serial parallel output line
    wire tx_done;                                   //flag indicates that the trans. operation is done
    wire tx_busy;                                   //flag indicates that the trans. operation is excuting

    //states encoding (One-Hot) to minimize glitches
    localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
               START  = 6'b000010,                  //start-bit = 0
               DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
               PARITY = 6'b001000,                  //sending parity bit if enabled
               STOP   = 6'b010000,                  //stop-bit = 1
               DONE   = 6'b100000;                  //raise tx_done. go back to IDLE

    uart_tx #(                                      //dut_tx instantiation
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .clk_period(clk_period),
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

    uart_baudgen #(                                 //baudgen instantiation to maintain real tick signal
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .oversampling_rate(oversampling_rate)
    )
    baudgen(
        .clk(clk), 
        .rst(rst), 
        .tick(tick)
    );

    initial                                         //clk generation
        begin
            clk = 0;
            forever #(clk_period/2) clk = ~clk;     //forcing clk period = 20, to maintain 50 MHZ frequency
        end

    initial
        begin                                       //waveform file
            $dumpfile("wave.vcd");
            $dumpvars(0, tb_tx);
        end

    // TASKs
    // reset task
    task reset();
        begin
            rst = 1;        //apply rst
            tx_start = 0;   //disables transmittion operation
            din = 0;        //default value
            repeat(10)      //waits for 10 clk cycles to track rst signal
                @(negedge clk);
            rst = 0;        //release rst
        end    
    endtask

    // send_data task
    task send_data(
        input [data_wd-1 : 0] data
    );
        begin
            din = data;     
            tx_start = 1;           //allow transmittion operation [IDLE => START] transition
            repeat(oversampling_rate)
                @(negedge tick);    //sending start-bit [START => DATA] transition 
            repeat(data_wd)
                repeat(oversampling_rate)
                    @(negedge tick);//sending all data bits [DATA => PARITY] transition
        end
    endtask

    // waits for parity_bit task
    task parity_bit();
        begin
            repeat(oversampling_rate * (3/4))
                @(negedge tick);
            if(tx)
                $display("xxxx Error : parity-error | din = %b, odd-parity bit = %d")
        end
    endtask

    initial
        begin
                                // 1st scenario Functional Correctness : (Reset Behavior)
            $display("\n==================== 1st scenario Functional Correctness : (Reset Behavior) ====================");
            reset();            
            if(!tx || tx_done || tx_busy || dut_tx.tick_count != 0 || dut_tx.bit_index != 0 || dut_tx.c_state != IDLE)
                $display("[FAIL] 1st scenario (Reset Behavior) : tx = %d, tx_done = %d, tx_busy = %d, tick_count = %d, bit_index = %d, c_state = %b", 
                        tx, tx_done, tx_busy, dut_tx.tick_count, dut_tx.bit_index, dut_tx.c_state);
            else 
                $display("[PASS] 1st scenario (Reset Behavior)");

                                // 2nd scenario Functional Correctness : (Transmit Frame with odd-parity)
            $display("\n==================== 2nd scenario Functional Correctness : (Transmit Frame with odd-parity) ====================");
            reset();  

                                // 3rd scenario Functional Correctness : (Transmit Multiple Back-to-Back Frames[10 frames])
            $display("\n==================== 3rd scenario Functional Correctness : (Transmit Multiple Back-to-Back Frames[10 frames]) ====================");
            reset();  

                                // 4th scenario Corner Case : (tx_start is high during Transmitting a frame)
            $display("\n==================== 4th scenario Corner Case : (tx_start is high during Transmitting a frame) ====================");
            reset();  

                                // 5th scenario Corner Case : (Reset during transmittion operation)
            $display("\n==================== 5th scenario Corner Case : (Reset during transmittion operation) ====================");
            reset();  

                                // 6th scenario Corner Case : (Transmit a frame [0xFF])
            $display("\n==================== 6th scenario Corner Case : (Transmit a frame [0xFF]) ====================");
            reset();  

                                // 7th scenario Corner Case : (Transmit a frame [0x00])
            $display("\n==================== 7th scenario Corner Case : (Transmit a frame [0x00]) ====================");
            reset(); 

                                // 8th scenario Corner Case : ('din' changes during transmittion operation)
            $display("\n==================== 3rd scenario (Transmit Multiple Back-to-Back Frames[10 frames]) ====================");
            reset();  

                                // STOP Simulatoin
            $display("\n==================== STOP Simulatoin ====================");
            reset();  
            #100; 
            $stop;
        end

    // initial
    //     $monitor("@time (%t) : c_state = %b, tx_done = %d, tx_busy = %d, tx = %d", $time, dut_tx.c_state, tx_done, tx_busy, tx);
endmodule