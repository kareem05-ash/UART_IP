`timescale 1ns/1ps
module tb_rx();

    // design parameters
    parameter BAUD = 9600;                          //baud rate per second
    parameter clk_freq = 50_000_000;                //system clk frequency in 'HZ'
    parameter clk_period = 1_000_000_000/clk_freq;  //system clk period in 'ns'
    parameter oversampling_rate = 16;               //to maintain valid data (avoiding noise)
    parameter data_wd = 8;                          //data width 
    parameter parity = 0;                           //1:odd, 2:even, default:no-parity

    //desgin signals
    reg clk;                                        //system clk
    reg rst;                                        //system async. active-high reset
    reg rx;                                         //serial input data
    reg rx_start;                                   //signal allows receiving operation
    reg [data_wd-1 : 0] byte;                       //holds the sending byte
    wire tick;                                      //pulse from baud generator
    wire rx_done;                                   //indicates that a single frame's been received successfully 
    wire rx_busy;                                   //indicates that a single frame is being received
    wire parity_error_flag;                         //indicates parity errors. if parity received doesn't equal parity expected
    wire framing_error_flag;                        //indicates start-bit, stop-bit, or data-bits error (noise)
    wire [data_wd-1 : 0] dout;                      //parallel output data

    //states encoding (One-Hot) to minimize glitches
    localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
               START  = 6'b000010,                  //start-bit = 0
               DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
               PARITY = 6'b001000,                  //sending parity bit if enabled
               STOP   = 6'b010000,                  //stop-bit = 1
               DONE   = 6'b100000;                  //raise tx_done. go back to IDLE

    //DUT instantiation
    uart_rx#(
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .clk_period(clk_period), 
        .oversampling_rate(oversampling_rate),      
        .data_wd(data_wd), 
        .parity(parity)
    )
    dut_rx(
        .clk(clk), 
        .rst(rst), 
        .rx(rx), 
        .tick(tick), 
        .rx_start(rx_start), 
        .rx_done(rx_done), 
        .rx_busy(rx_busy), 
        .parity_error_flag(parity_error_flag), 
        .framing_error_flag(framing_error_flag), 
        .dout(dout)
    );

    //Baud Generator Instantiation
    uart_baudgen#(    
        .BAUD(BAUD), 
        .clk_freq(clk_freq), 
        .oversampling_rate(oversampling_rate)
    )
    baudgen(
        .clk(clk), 
        .rst(rst), 
        .tick(tick)
    );

    //clk generaion
    initial 
        begin
            clk = 0;
            forever #(clk_period/2) clk = ~clk;
        end

    //RESET Task
    task reset();
        begin
            rst = 1;        //activate reset
            rx = 1;         //waits for start-bit
            rx_start = 0;   
            repeat(10) 
                @(negedge clk);
            rst = 0;        //release rst
        end
    endtask

    //Sending a Frame task
    integer i;
    task send_frame( input [data_wd-1 : 0] data );
        begin
            rx_start = 1;   //enable reciption operation (IDLE => START) transition
            rx = 0;         //start-bit (active-low)
            repeat(oversampling_rate)   //waits oversampling_rate ticks to sample the start-bit
                @(negedge tick);        //(START => DATA) transition
            rx_start = 0;
            for(i=0; i<data_wd; i=i+1)          //waits for receiving all data bits (DATA => STOP) transition
                begin
                    rx = data [i];
                    repeat(oversampling_rate)   //waits oversampling_rate ticks to sample the bit received
                        @(negedge tick);
                end
            rx = 1;         //stop-bit (active-high)
            repeat(oversampling_rate)   //waits oversampling_rate ticks to sample the stop-bit
                @(negedge tick);        //(STOP => DONE) transition
        end
    endtask

    initial
        begin 
                                //first scenario (reset bahavior)
            $display("\n ======================== first scenario (reset bahavior) ========================");
            reset();            //reset the system
            if(rx_done || rx_busy || framing_error_flag || parity_error_flag || 
                (dut_rx.tick_count != 0) || (dut_rx.bit_index != 0) || (dut_rx.c_state != IDLE))
                $display("[FAIL] first scenario (reset bahavior) : rx_done = %d, rx_busy = %d, framing_error_flag = %d, parity_error_flag = %d, tick_count = 0x%h, bit_index = 0x%h, c_state = %b", 
                        rx_done, rx_busy, framing_error_flag, parity_error_flag, dut_rx.tick_count, dut_rx.bit_index, dut_rx.c_state);
            else    
                $display("[PASS] first scenario (reset bahavior)");

                                //second scenario (sendign a frame [0xA5])
            $display("\n ======================== second scenario (sendign a frame [0xA5]) ========================");
            reset();            //reset the system
            send_frame(8'hA5);  //sending a complete frame
            if((dout != 8'hA5))// || !rx_done || (dut_rx.c_state != DONE)
                $display("[FAIL] second scenario (sendign a frame [0xA5]) : dout = 0x%h, expected = a5, c_state = %b, rx_done = %d", 
                        dout, dut_rx.c_state, rx_done);
            else
                $display("[PASS] second scenario (sendign a frame [0xA5]) : dout = 0x%h, expeted = a5", dout);

                                //third scenario (Multiple Back-to-Back Frames)
            $display("\n ======================== third scenario (Multiple Back-to-Back Frames) ========================");
            reset();            //reset the system
            repeat(10)           //sending 10 frames back to back (without delays)
                begin
                    byte = $random;     //generating a random frame
                    send_frame(byte);   //sendign the random frame
                    if((dout != byte)) // || !rx_done || (dut_rx.c_state != DONE
                        $display("[FAIL] third scenario (Multiple Back-to-Back Frames) : dout = 0x%h, expected = 0x%h, c_state = %b, rx_done = %d", 
                                dout, byte, dut_rx.c_state, rx_done);
                    else
                        $display("[PASS] third scenario (Multiple Back-to-Back Frames) : dout = 0x%h, expected = 0x%h", 
                                dout, byte);
                end

                                //fourth scenario (noise on line during IDLE [Glitch Rejection Test])
            $display("\n ======================== fourth scenario (noise on line during IDLE [Glitch Rejection Test]) ========================");
            reset();            //reset the system
            rx_start = 1;       //enable reciption operation (IDLE => START) transition
            rx = 0;             //start-bit (active-low)
            // $display("tick_count = %d, framing_error_flag = %d, c_state = %b, dout = %h", dut_rx.tick_count, framing_error_flag, dut_rx.c_state, dout);
            repeat(oversampling_rate/4)
                @(negedge tick);//waits for small time (noise) to track, how DUT handles this issue?
            rx_start = 0;       //to ensure staying at 'IDLE'
            rx = 1;             //aplly noise
            repeat((3 * oversampling_rate) / 4)
                @(negedge tick);//waits to complete the sampling cycle
            if((dut_rx.c_state != IDLE) || (dout != 0))
                $display("[FAIL] fourth scenario (noise on line during IDLE [Glitch Rejection Test]) : c_state = %b, dout = 0x%h, framing_error_flag = %d, tick_count = %d, test_bit = %d, rx = %d", 
                        dut_rx.c_state, dout, framing_error_flag, dut_rx.tick_count, dut_rx.test_bit, rx);
            else    
                $display("[PASS] fourth scenario (noise on line during IDLE [Glitch Rejection Test]) : c_state = %b, dout = 0x%h, tick_count = %d", 
                        dut_rx.c_state, dout, dut_rx.tick_count);

                                //fifth scenario (idle line for so long, then valid frame [0x3C])
            $display("\n ======================== fifth scenario (idle line for so long, then valid frame) ========================");
            reset();            //reset the system
            repeat(100 * oversampling_rate)     
                @(negedge tick);
            $display("waits for 100 oversampling cycles");
            byte = 8'h3C;
            send_frame(byte);   //send a valid frame [0x3C]
            if(dout != byte)
                $display("[FAIL] fifth scenario (idle line for so long, then valid frame) : dout = 0x%h, expected = 0x%h, c_state = %b, rx_done = %d", 
                        dout, byte, dut_rx.c_state, rx_done);
            else    
                $display("[PASS] fifth scenario (idle line for so long, then valid frame) : dout = 0x%h, expected = 0x%h", 
                        dout, byte);

                                //sixth scenario (Corner Case : receiveing frame [0xFF])
            $display("\n ======================== sixth scenario (Corner Case : receiveing frame [0xFF]) ========================");
            reset();            //reset the system
            byte = 8'hFF;
            send_frame(byte);   //send a valid frame [0xFF]
            if(dout != byte)
                $display("[FAIL] sixth scenario (Corner Case : receiveing frame [0xFF]) : dout = 0x%h, expected = 0x%h, c_state = %b, rx_done = %d", 
                        dout, byte, dut_rx.c_state, rx_done);
            else    
                $display("[PASS] sixth scenario (Corner Case : receiveing frame [0xFF]) : dout = 0x%h, expected = 0x%h", 
                        dout, byte);


                                //seventh scenario (Corner Case : receiveing frame [0x00])        
            $display("\n ======================== seventh scenario (Corner Case : receiveing frame [0x00]) ========================");
            reset();            //reset the system
            byte = 8'h00;
            send_frame(byte);   //send a valid frame [0x00]
            if(dout != byte)
                $display("[FAIL] seventh scenario (Corner Case : receiveing frame [0x00]) : dout = 0x%h, expected = 0x%h, c_state = %b, rx_done = %d", 
                        dout, byte, dut_rx.c_state, rx_done);
            else    
                $display("[PASS] seventh scenario (Corner Case : receiveing frame [0x00]) : dout = 0x%h, expected = 0x%h", 
                        dout, byte);




                                //STOP Simulation
            #100; 
            $stop;
        end
    initial
        $monitor("framing error = %d, parity_error_flag = %d", framing_error_flag, parity_error_flag);
    monitor
    initial
        $monitor("framing_error_flag = %d, parity_error_flag = %d, rx_done = %d, dout = 0x%h, c_state = %b", 
                framing_error_flag, parity_error_flag, rx_done, dout, dut_rx.c_state);
endmodule