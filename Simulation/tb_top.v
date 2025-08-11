////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// Digital IC Design & ASIC Verififcation Engineer
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
        parameter fifo_depth = 4;                       //fifo entries
        parameter almost_full_thr = 3;                  //threshold point which the almost_full flag arise at
        parameter almost_empty_thr = 1;                 //threshold point which the almost_empty flag arise at

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

    // Needed Internal Signals 
        reg [data_wd-1 : 0] test_data;                  //register stores the data to test it
        integer i;                                      

    // State Encoding (One-Hot) to minimize glitches
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
                    @(negedge clk); // waits for a clk cycle to track reset signal
                    rst = 0;        // release rst
                end
            endtask

        // assign_data task
            task assign_data(input [data_wd-1 : 0] data); begin
                din = data;         // assign input data
                tx_wr_en = 1;       // enables write operation to fifo_tx
                tx_rd_en = 1;       // enables read operation from fifo_tx
                // rx_rd_en = 1;       // enables read operation from fifo_rx
                tx_start = 1;       // enables transmittion operation
                rx_start = 1;       // enables reception operation
                @(negedge clk);     // waits for a clk cycle to track changes 
                if(DUT.TX.c_state == START && DUT.RX.c_state == START)
                    $display("[PASS] IDLE => START transition | TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b", 
                                DUT.TX.c_state, START, DUT.RX.c_state, START);
                else
                    $display("[FAIL] IDLE => START transition | TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b", 
                                DUT.TX.c_state, START, DUT.RX.c_state, START);
            end
            endtask

        // start_bit task
            task start_bit(); begin
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to sample start-bit
                if(!DUT.tx_rx && !DUT.RX.rx && DUT.TX.c_state == START && DUT.RX.c_state == START && !framing_error_flag)
                    $display("[PASS] start-bit | tx_rx = %d, expected = %d, rx = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d", 
                                DUT.tx_rx, 1'b0, DUT.RX.rx, 1'b0, DUT.TX.c_state, START, DUT.RX.c_state, START, framing_error_flag);
                else
                    $display("[FAIL] start-bit | tx_rx = %d, expected = %d, rx = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d", 
                                DUT.tx_rx, 1'b0, DUT.RX.rx, 1'b0, DUT.TX.c_state, START, DUT.RX.c_state, START, framing_error_flag);
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to finish start-bit sampling
            end
            endtask

        // data_bits task
            task data_bits(input [data_wd-1 : 0] data); begin
                for(i=0; i<data_wd; i=i+1)begin
                    repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to sample data-bit[i]
                    if(DUT.TX.c_state == DATA && DUT.RX.c_state == DATA && DUT.RX.rx == data[i] && !framing_error_flag)
                        $display("[PASS] data-bit[%d] | sent data-bit = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d",   
                                    i, DUT.RX.rx, data[i], DUT.TX.c_state, DATA, DUT.RX.c_state, DATA, framing_error_flag);
                    else
                        $display("[FAIL] data-bit[%d] | sent data-bit = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d",   
                                    i, DUT.RX.rx, data[i], DUT.TX.c_state, DATA, DUT.RX.c_state, DATA, framing_error_flag);
                    repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to finish data-bit sampling
                end
            end
            endtask

        // parity_bit task
            task parity_bit(); begin
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to sample parity-bit
                if(DUT.RX.rx == DUT.TX.parity_res && DUT.RX.c_state == PARITY && DUT.TX.c_state == PARITY && !framing_error_flag && !parity_error_flag)
                    $display("[PASS] parity-bit | parity-bit sent = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d, parity_error_flag = %d", 
                                DUT.RX.rx, DUT.TX.parity_res, DUT.TX.c_state, PARITY, DUT.RX.c_state, PARITY, framing_error_flag, parity_error_flag);
                else    
                    $display("[FAIL] parity-bit | parity-bit sent = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d, parity_error_flag = %d", 
                                DUT.RX.rx, DUT.TX.parity_res, DUT.TX.c_state, PARITY, DUT.RX.c_state, PARITY, framing_error_flag, parity_error_flag);
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to finish parity-bit sampling
            end
            endtask

        // stop_bit task
            task stop_bit(); begin
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to sample stop-bit
                if(DUT.tx_rx && DUT.RX.rx && DUT.TX.c_state == STOP && DUT.RX.c_state == STOP && !framing_error_flag)
                    $display("[PASS] stop-bit | tx_rx = %d, expected = %d, rx = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d", 
                                DUT.tx_rx, 1'b1, DUT.RX.rx, 1'b1, DUT.TX.c_state, STOP, DUT.RX.c_state, STOP, framing_error_flag);
                else
                    $display("[FAIL] stop-bit | tx_rx = %d, expected = %d, rx = %d, expected = %d, TX.c_state = %b, expected = %b, RX.c_state = %b, expected = %b, framing_error_flag = %d", 
                                DUT.tx_rx, 1'b1, DUT.RX.rx, 1'b1, DUT.TX.c_state, STOP, DUT.RX.c_state, STOP, framing_error_flag);
                repeat(oversampling_rate/2) @(negedge DUT.tick);    // waits to finish start-bit sampling
                rx_wr_en = 1;           // enables write operation in fifo_rx to store dout
                @(negedge DUT.tick);    // waits for a tick pulse to store dout in fifo_rx
                rx_wr_en = 0;           // disables write operation in fifo_rx to avoid storing the same frame in all fifo entries
            end
            endtask

    // Real World Scenarois & Corner Case tests
        initial 
            begin
            // 1st scenario Functional Correctness (Reset Behavior)
                $display("\n ==================== 1st scenario Functional Correctness (Reset Behavior) ====================");
                reset();    
                if(tx_full || !tx_empty || tx_almost_full || !tx_almost_empty || rx_full || !rx_empty || rx_almost_full || !rx_almost_empty || 
                    tx_done || tx_busy || rx_done || rx_busy || framing_error_flag || parity_error_flag || DUT.TX.c_state != IDLE || DUT.RX.c_state != IDLE)
                    $display("[FAIL] | tx_full = %d, tx_empty = %d, tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \nrx_full = %d, rx_empty = %d, rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \nframing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);
                else
                    $display("[PASS] | tx_full = %d, tx_empty = %d, tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \nrx_full = %d, rx_empty = %d, rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \nframing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);

            // 2nd scenario Functional Correctness (Random TX & RX)
                $display("\n ==================== 2nd scenario Functional Correctness (Random TX & RX) ====================");
                reset(); 
                test_data = $random;
                assign_data(test_data);     // IDLE => START transition assertion
                start_bit();                // start-bit assertion
                data_bits(test_data);       // data-bits assertion
                parity_bit();               // parity-bit assertion
                stop_bit();                 // stop-bit assertion

            // 3rd scenario Functional Correctness (Reset during sending a random frame)
                $display("\n ==================== 3rd scenario Functional Correctness (Reset during sending a random frame) ====================");
                reset(); 
                reset(); 
                test_data = $random;
                assign_data(test_data);     // IDLE => START transition assertion
                start_bit();                // start-bit assertion
                $display("Now, apply rst");
                rst = 1;                    // apply rst
                @(negedge clk);             // waits to track rst signal
                rst = 0;                    // release rst
                $display("After rst, this is the behavior");
                if(tx_full || !tx_empty || tx_almost_full || !tx_almost_empty || rx_full || !rx_empty || rx_almost_full || !rx_almost_empty || 
                    tx_done || tx_busy || rx_done || rx_busy || framing_error_flag || parity_error_flag || DUT.TX.c_state != IDLE || DUT.RX.c_state != IDLE)
                    $display("[FAIL] | tx_full = %d, tx_empty = %d, tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \nrx_full = %d, rx_empty = %d, rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \nframing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);
                else
                    $display("[PASS] | tx_full = %d, tx_empty = %d, tx_almost_full = %d, tx_almost_empty = %d, tx_done = %d, tx_busy = %d, \nrx_full = %d, rx_empty = %d, rx_almost_full = %d, rx_almost_empty = %d, rx_done = %d, rx_busy = %d, \nframing_error_flag = %d, parity_error_flag = %d, TX.c_state = %b, RX.c_state = %b", 
                                tx_full, tx_empty, tx_almost_full, tx_almost_empty, tx_done, tx_busy, rx_full, rx_empty, rx_almost_full, rx_almost_empty, rx_done, rx_busy, 
                                framing_error_flag, parity_error_flag, DUT.TX.c_state, DUT.RX.c_state);

                
            // 4th scenario Corner Case (Multiple Random Frames Back-to-Back)
                $display("\n ==================== 4th scenario Corner Case (Multiple Random Frames Back-to-Back) ====================");
                reset(); 
                // repeat(5) begin     // send 5 random frames back-to-back
                //     test_data = $random;
                //     $display("Now, frame: 0x%h", test_data);
                //     assign_data(test_data);     // IDLE => START transition assertion
                //     start_bit();                // start-bit assertion
                //     data_bits(test_data);       // data-bits assertion
                //     parity_bit();               // parity-bit assertion
                //     stop_bit();                 // stop-bit assertion   
                //     $display("\n"); 
                // end

            // 5th scenario Corner Case (0x00 TX & RX)
                $display("\n ==================== 5th scenario Corner Case (0x00 TX & RX) ====================");
                reset(); 
                test_data = 8'h00;          // send data with zero bits only
                assign_data(test_data);     // IDLE => START transition assertion
                start_bit();                // start-bit assertion
                data_bits(test_data);       // data-bits assertion
                parity_bit();               // parity-bit assertion
                stop_bit();                 // stop-bit assertion

            // 6th scenario Corner Case (0xFF TX & RX)
                $display("\n ==================== 6th scenario Corner Case (0xFF TX & RX) ====================");
                reset(); 
                test_data = 8'hFF;          // send data with one bits only
                assign_data(test_data);     // IDLE => START transition assertion
                start_bit();                // start-bit assertion
                data_bits(test_data);       // data-bits assertion
                parity_bit();               // parity-bit assertion
                stop_bit();                 // stop-bit assertion

            // 7th scenario Corner Case (Trying to send a frame during another is being sent)
                $display("\n ==================== 7th scenario Corner Case (Trying to send a frame during another is being sent) ====================");
                reset(); 
                test_data = 8'hA5;          // send 1st frame 0xA5
                assign_data(test_data);     // IDLE => START transition assertion
                start_bit();                // start-bit assertion
                data_bits(test_data);       // data-bits assertion
                din = 8'h3C;                // send 2nd frame 0x3C
                tx_wr_en = 1;               // enables write to fifo_tx to store 2nd frame
                tx_rd_en = 1;               // enables read from fifo_tx to read the sotred frame (2nd frame)
                parity_bit();               // parity-bit assertion
                stop_bit();                 // stop-bit assertion


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
        initial begin 
            $monitor("RX.c_state = %b, dout_rx = %h, tx_done = %d, rx_done = %d, framing_error_flag = %d, parity_error_flag = %d, tx_fifo_count = %d, rx_fifo_count = %d",
                        DUT.RX.c_state, DUT.dout_rx, tx_done, rx_done, framing_error_flag, parity_error_flag, DUT.fifo_tx.fifo_count, DUT.fifo_rx.fifo_count);
        end
        initial begin
            $monitor("fifo_tx[0] = %h, fifo_rx[0] = %h | fifo_tx[1] = %h, fifo_rx[1] = %h | fifo_tx[2] = %h, fifo_rx[2] = %h | fifo_tx[3] = %h, fifo_rx[3] = %h", 
                        DUT.fifo_tx.fifo[0], DUT.fifo_rx.fifo[0], DUT.fifo_tx.fifo[1], DUT.fifo_rx.fifo[1], DUT.fifo_tx.fifo[2], DUT.fifo_rx.fifo[2], DUT.fifo_tx.fifo[3], DUT.fifo_rx.fifo[3]);
        end
    // Error Flags
        always@(*) begin
            if(DUT.RX.tick_count != DUT.TX.tick_count)  // ensures time matching between TX & RX
                $display("XXXXXXXXXXXXXXXX Error RX.tick_count = %d, TX.tick_count = %d", DUT.RX.tick_count, DUT.TX.tick_count);
            if(parity_error_flag || framing_error_flag) // ensures there are no error flags
                $display("XXXXXXXXXXXXXXXX Error framing_error_flag = %d, parity_error_flag = %d", framing_error_flag, parity_error_flag);
            if(DUT.TX.c_state != DUT.RX.c_state)        // ensures both TX & RX are in the same state
                $display("XXXXXXXXXXXXXXXX Error RX.c_state = %b, TX.c_state = %b", DUT.RX.c_state, DUT.TX.c_state);
        end
endmodule
