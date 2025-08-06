////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_top();
    // Design Paramters
        parameter BAUD = 9600;                          //baud rate per second
        parameter clk_freq = 50_000_000;                //system clk frequency in 'HZ'
        parameter clk_period = 1_000_000_000/clk_freq;  //system clk period in 'ns'
        parameter oversampling_rate = 16;               //to maintain valid data (avoiding noise)
        parameter data_wd = 8;                          //data width 
        parameter parity = 1;  //odd-parity             //1:odd, 2:even, default:no-parity
        parameter fifo_depth = 256;                     //fifo entries
        parameter almost_full_thr = 240;                //threshold point which the almost_full flag arise at
        parameter almost_empty_thr = 16;                //threshold point which the almost_empty flag arise at

    // DUT Inputs
        reg clk;                                        //system clk signal
        reg rst;                                        //system async. active-high reset
        reg tx_wr_en;                                   //fifo_tx write enable
        reg tx_rd_en;                                   //fifo_tx read enable
        reg rx_wr_en;                                   //fifo_rx write enable
        reg rx_rd_en;                                   //fifo_rx read enable
        reg tx_start;                                   //start transmitting operation signal
        reg rx_start;                                   //start reciption operation signal
        reg [data_wd-1 : 0] din;                        //system parallel input data
    // DUT Outputs
        wire tx_full;                                   //tx_fifo full flag
        wire tx_empty;                                  //tx_fifo empty flag
        wire tx_almost_full;                            //tx_fifo almost_full flag
        wire tx_almost_empty;                           //tx_fifo almost_empty flag
        wire rx_full;                                   //rx_fifo full flag
        wire rx_empty;                                  //rx_fifo empty flag
        wire rx_almost_full;                            //rx_fifo almost_full flag
        wire rx_almost_empty;                           //rx_fifo almost_empty flag
        wire tx_done;                                   //indicates a valid frame's been transmitted 
        wire tx_busy;                                   //inidcates that a frame is being transmitted
        wire rx_done;                                   //indicates a valid frame's been received
        wire rx_busy;                                   //indicates that a frame is being received
        wire framing_error_flag;                        //indicates invalid start-bit, or stop-bit or noise on start-bit, stop-bit, even or data bits
        wire parity_error_flag;                         //indicates invalid parity-bit's been received
        wire [data_wd-1 : 0] dout;                      //system parallel output data     

    // Need Internal Signals 
        reg start_bit_successful = 0;                   //asserts that the start-bit's been transmitted successfully 
        reg stop_bit_successful = 0;                    //asserts that the stop-bit's been transmitted successfully 
        reg data_bits_successful = 0;                   //asserts that all data bits have been transmitted successfully
        reg [data_wd-1 : 0] test_data = 8'hFA;                  //register stores the data to test it
        integer i;                                      

    // States Encoding (One-Hot) to minimize glitches
        localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
                   START  = 6'b000010,                  //start-bit = 0
                   DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
                   PARITY = 6'b001000,                  //sending parity bit if enabled
                   STOP   = 6'b010000,                  //stop-bit = 1
                   DONE   = 6'b100000;                  //raise tx_done. go back to IDLE

    // DUT Instantiation
        uart_top#(
        // Parameters
            .BAUD(BAUD), 
            .clk_freq(clk_freq), 
            .clk_period(clk_period), 
            .oversampling_rate(oversampling_rate), 
            .data_wd(data_wd), 
            .parity(parity), 
            .fifo_depth(fifo_depth), 
            .almost_full_thr(almost_full_thr), 
            .almost_empty_thr(almost_empty_thr)
        )
        DUT(
        // Inputs
            .clk(clk), 
            .rst(rst), 
            .tx_wr_en(tx_wr_en), 
            .tx_rd_en(tx_rd_en), 
            .rx_wr_en(rx_wr_en), 
            .rx_rd_en(rx_rd_en), 
            .tx_start(tx_start), 
            .rx_start(rx_start), 
            .din(din),      //system parallel input data
        // Outputs
            .tx_full(tx_full), 
            .tx_empty(tx_empty), 
            .tx_almost_full(tx_almost_full), 
            .tx_almost_empty(tx_almost_empty), 
            .rx_full(rx_full), 
            .rx_empty(rx_empty), 
            .rx_almost_full(rx_almost_full), 
            .rx_almost_empty(rx_almost_empty), 
            .tx_done(tx_done), 
            .tx_busy(tx_busy), 
            .rx_done(rx_done), 
            .rx_busy(rx_busy), 
            .framing_error_flag(framing_error_flag), 
            .parity_error_flag(parity_error_flag), 
            .dout(dout)     //system parallel output data
        );

    // clk Generation
        initial begin
            clk = 0; 
            forever #(clk_period/2) clk = ~clk;
        end

    // TASKs
        // reset task
            task reset();
                begin
                    rst = 1;        // activate rst
                    tx_wr_en = 0;   
                    tx_rd_en = 0;
                    rx_wr_en = 0;   
                    rx_rd_en = 0;
                    tx_start = 0;
                    rx_start = 0;
                    din = 0;        // default data
                    repeat(3)       // waits for 3 clk cycles to track rst signal
                        @(negedge clk);
                    rst = 0;        // release rst
                end
            endtask

        // 

    // Real World Scenarois & Corner Case tests
        initial 
            begin
            // 1st scenario Functional Correctness (Reset Behavior)
                $display("\n ==================== 1st scenario Functional Correctness (Reset Behavior) ====================");
                reset();    
                if(tx_full || !tx_empty || tx_almost_full || !tx_almost_empty || rx_full || !rx_empty || rx_almost_full || !rx_almost_empty || 
                    tx_done || tx_busy || rx_done || rx_busy || framing_error_flag || parity_error_flag || DUT.TX.c_state != IDLE || DUT.RX.c_state != IDLE)
                    $display("[FAIL] | tx_full = %d, tx_empty = tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \n rx_full = %d, rx_empty = rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \n framing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);
                else
                    $display("[PASS] | tx_full = %d, tx_empty = tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \n rx_full = %d, rx_empty = rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \n framing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);

            // 2nd scenario Functional Correctness (Basic TX Transmittion)
                $display("\n ==================== 2nd scenario Functional Correctness (Basic TX Transmittion) ====================");
                reset(); 

            // 3rd scenario Functional Correctness (Basic RX Reception)
                $display("\n ==================== 3rd scenario Functional Correctness (Basic RX Reception) ====================");
                reset(); 
                
            // 4th scenario Corner Case (Multiple Frames Back-to-Back)
                $display("\n ==================== 4th scenario Corner Case (Multiple Frames Back-to-Back) ====================");
                reset(); 

            // 5th scenario Corner Case (Back-to-Back TX & RX)
                $display("\n ==================== 5th scenario Corner Case (Back-to-Back TX & RX) ====================");
                reset(); 

            // 6th scenario Corner Case (Glitches on tx_rx line [start-bit])
                $display("\n ==================== 6th scenario Corner Case (Glitches on tx_rx line [start-bit]) ====================");
                reset(); 

            // 7th scenario Corner Case (Glitches on tx_rx line [stop-bit])
                $display("\n ==================== 7th scenario Corner Case (Glitches on tx_rx line [stop-bit]) ====================");
                reset(); 

            // 8th scenario Corner Case (TX & RX [0xFF])
                $display("\n ==================== 8th scenario Corner Case (TX & RX [0xFF]) ====================");
                reset(); 

            // 9th scenario Corner Case (TX & RX [0x00])
                $display("\n ==================== 9th scenario Corner Case (TX & RX [0x00]) ====================");
                reset(); 

            // 10th scenario Corner Case (Sending a frame during tx_busy is high)
                $display("\n ==================== 10th scenario Corner Case (Sending a frame during tx_busy is high) ====================");
                reset(); 

            // 11th scenario Corner Case (Trying to send a frame where fifo_tx is full)
                $display("\n ==================== 11th scenario Corner Case (Trying to send a frame where fifo_tx is full) ====================");
                reset(); 

            // 12th scenario Corner Case (Trying to read a frame where fifo_rx is empty)
                $display("\n ==================== 12th scenario Corner Case (Trying to read a frame where fifo_rx is empty) ====================");
                reset(); 

            // STOP Simulation
                $display("\n==================== STOP Simulation ====================");
                #100; 
                $stop;
            end
    // monitor
        // initial
        //     $monitor("fifo [0] = %h, tx_rx = %d, test_data = %h, TX.c_state = %b", DUT.fifo_tx.fifo[0], DUT.tx_rx, test_data, DUT.TX.c_state);
endmodule