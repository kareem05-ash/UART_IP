////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
`timescale 1ns/1ps
module tb_tx();
// parameters
    parameter BAUD = 9600;                          //baud rate per second
    parameter clk_freq = 50_000_000;                //system clk frequency
    parameter clk_period = 1_000_000_000/clk_freq;  //system clk period in 'ns'
    parameter oversampling_rate = 16;               //to maintain valid data (avoiding noise)
    parameter data_wd = 8;                          //data width
    parameter [1:0] parity = 1; //odd-parity        //1:odd-parity, 2:even-parity, default:no-parity
// DUT Inputs
    reg clk;                                        //system clk
    reg rst;                                        //system async. active-high reset
    reg tx_start;                                   //signal to initiate data (allow the transimition operation)
    reg [data_wd-1 : 0] din;                        //parallel input data to be tarnsimitted
// DUT Outputs
    wire tick;                                      //pulse to transimit one bit (from baud generator)
    wire tx;                                        //serial output line
    wire tx_done;                                   //flag indicates that the trans. operation is done
    wire tx_busy;                                   //flag indicates that the trans. operation is excuting

// Neede internal signals
    reg [data_wd-1 : 0] data = 0;                   // stores data to assert correctness
    integer i;
// states encoding (One-Hot) to minimize glitches
    localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
               START  = 6'b000010,                  //start-bit = 0
               DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
               PARITY = 6'b001000,                  //sending parity bit if enabled
               STOP   = 6'b010000,                  //stop-bit = 1
               DONE   = 6'b100000;                  //raise tx_done. get back to IDLE
// DUT Instantiation
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
// baudgen instantiation
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
// clk generation
    initial
        begin
            clk = 0;
            forever #(clk_period/2) clk = ~clk;     //forcing clk period = 20, to maintain 50 MHZ frequency
        end

// Waveform
    initial
        begin
            $dumpfile("wave.vcd");
            $dumpvars(0, tb_tx);
        end

// TASKs
    // reset task
        task reset();
            begin
                rst = 1;        //activate rst
                tx_start = 0;   //disables transmittion operation
                din = 0;        //default value
                repeat(1)       //waits for 3 clk cycles to track rst signal
                    @(negedge clk);
                rst = 0;        //release rst
            end    
        endtask
    // assign_data task
        task assign_data (input [data_wd-1 : 0] data); begin
            din = data;     
            tx_start = 1;           // IDLE => START transition
            @(negedge clk);         
            @(negedge clk);
            tx_start = 0;           // disables sending another frame
            if(dut_tx.c_state != START) 
                $display("[FAIL] | First transition done | c_state = %b, expected = %b", dut_tx.c_state, START);
            else
                $display("[PASS] | First transition done | c_state = %b, expected = %b", dut_tx.c_state, START);
        end
        endtask

    // start_bit task
        task start_bit();begin
            repeat(12) @(negedge tick);
            if(tx)
                $display("[FAIL] | start-bit : sent start-bit = %d, expected = %d, c_state = %b", tx, 1'd0, dut_tx.c_state);
            else 
                $display("[PASS] | start-bit : sent start-bit = %d, expected = %d, c_state = %b", tx, 1'd0, dut_tx.c_state);
            repeat(4) @(negedge tick);
        end
        endtask

    // data_bits task
        task data_bits();begin
            if(dut_tx.c_state == DATA)
                for(i=0; i<data_wd; i=i+1) begin
                    repeat(12) @(negedge tick);
                    if(tx == din[i])
                        $display("[PASS] | data bit[%d] : c_state = %b, tx = %d, expected = %d", i, dut_tx.c_state, tx, din[i]);
                    else
                        $display("[FAIL] | data bit[%d] : c_state = %b, tx = %d, expected = %d", i, dut_tx.c_state, tx, din[i]);
                    repeat(4) @(negedge tick);
                end
            else
                $display("[FAIL] | START => DATA transition : c_state = %b, expected = %b",    
                        dut_tx.c_state, DATA);
        end
        endtask

    // parity_bit task
        task parity_bit();begin
            if(dut_tx.c_state == PARITY) begin
                repeat(12) @(negedge tick);
                if(tx == dut_tx.parity_res)
                    $display("[PASS] | parity-bit : sent parity-bit = %d, expected = %d, c_state = %b", 
                            tx, dut_tx.parity_res, dut_tx.c_state);
                else
                    $display("[FAIL] | parity-bit : sent parity-bit = %d, expected = %d, c_state = %b", 
                            tx, dut_tx.parity_res, dut_tx.c_state);
                repeat(4) @(negedge tick);
            end else begin
                $display("[FAIL] | DATA => PARITY transition : c_state = %b, expected = %b",    
                        dut_tx.c_state, PARITY);
            end
        end
        endtask

    // stop_bit task
        task stop_bit();begin
            if(dut_tx.c_state == STOP) begin
                repeat(12) @(negedge tick);
                if(!tx)
                    $display("[FAIL] | stop-bit : sent stop-bit = %d, expected = %d, c_state = %b", tx, 1'd1, dut_tx.c_state);
                else 
                    $display("[PASS] | stop-bit : sent stop-bit = %d, expected = %d, c_state = %b", tx, 1'd1, dut_tx.c_state);
                repeat(4) @(negedge tick);
            end else begin
                $display("[FAIL] | PARITY => STOP transition : c_state = %b, expected = %b",    
                        dut_tx.c_state, STOP);
            end
        end
        endtask
// Test Scenarios
    initial 
        begin
            // 1st scenario Functional Correctness : (Reset Behavior)
                $display("\n==================== 1st scenario Functional Correctness : (Reset Behavior) ====================");
                reset();            
                if(!tx || tx_done || tx_busy || dut_tx.tick_count != 0 || dut_tx.bit_index != 0 || dut_tx.c_state != IDLE)
                    $display("[FAIL] : tx = %d, tx_done = %d, tx_busy = %d, tick_count = %d, bit_index = %d, c_state = %b", 
                            tx, tx_done, tx_busy, dut_tx.tick_count, dut_tx.bit_index, dut_tx.c_state);
                else 
                    $display("[PASS] : tx = %d, tx_done = %d, tx_busy = %d, tick_count = %d, bit_index = %d, c_state = %b", 
                            tx, tx_done, tx_busy, dut_tx.tick_count, dut_tx.bit_index, dut_tx.c_state);

            // 2nd scenario Functional Correctness : (Transmit Frame [8'b1101_0011] with odd-parity)
                $display("\n==================== 2nd scenario Functional Correctness : (Transmit Frame [8'b1101_0011] with odd-parity) ====================");
                reset(); 
                assign_data(8'b1101_0011);
                start_bit();
                data_bits();
                parity_bit();
                stop_bit();

            // 3rd scenario Functional Correctness : (Transmit Multiple Back-to-Back Random Frames[5 frames])
                $display("\n==================== 3rd scenario Functional Correctness : (Transmit Multiple Back-to-Back Frames[5 frames]) ====================");
                reset();  
                repeat(5)begin
                    data = $random;     // assign random data
                    assign_data(data);
                    start_bit();
                    data_bits();
                    parity_bit();
                    stop_bit();
                    $display("\n");
                end
            // 4th scenario Corner Case : (tx_start is high during Transmitting a frame)
                $display("\n==================== 4th scenario Corner Case : (tx_start is high during Transmitting a frame) ====================");
                reset();  
                din = $random;     
                tx_start = 1;           // IDLE => START transition
                @(negedge clk);         
                @(negedge clk);
                if(dut_tx.c_state != START) 
                        $display("[FAIL] | First transition done | c_state = %b, expected = %b", dut_tx.c_state, START);
                    else
                        $display("[PASS] | First transition done | c_state = %b, expected = %b", dut_tx.c_state, START);
            // 5th scenario Corner Case : (Reset during transmittion operation)
                $display("\n==================== 5th scenario Corner Case : (Reset during transmittion operation) ====================");
                reset();  
                assign_data(8'b1101_0011);
                start_bit();
                // half of data bits
                    if(dut_tx.c_state == DATA)
                        for(i=0; i<data_wd/2; i=i+1) begin  // send half of the frame
                            repeat(12) @(negedge tick);
                            if(tx == din[i])
                                $display("[PASS] | data bit[%d] : c_state = %b, tx = %d, expected = %d", i, dut_tx.c_state, tx, din[i]);
                            else
                                $display("[FAIL] | data bit[%d] : c_state = %b, tx = %d, expected = %d", i, dut_tx.c_state, tx, din[i]);
                            repeat(4) @(negedge tick);
                        end
                    else
                        $display("[FAIL] | START => DATA transition : c_state = %b, expected = %b",    
                                dut_tx.c_state, DATA);
                // apply reset
                    $display("   Apply Reset During Sendin a Frame");
                    reset();
                    if(!tx || tx_done || tx_busy || dut_tx.tick_count != 0 || dut_tx.bit_index != 0 || dut_tx.c_state != IDLE)
                        $display("[FAIL] After Applying Reset | : tx = %d, tx_done = %d, tx_busy = %d, tick_count = %d, bit_index = %d, c_state = %b", 
                                tx, tx_done, tx_busy, dut_tx.tick_count, dut_tx.bit_index, dut_tx.c_state);
                    else 
                        $display("[PASS] After Applying Reset | : tx = %d, tx_done = %d, tx_busy = %d, tick_count = %d, bit_index = %d, c_state = %b", 
                                tx, tx_done, tx_busy, dut_tx.tick_count, dut_tx.bit_index, dut_tx.c_state);
            // 6th scenario Corner Case : (Transmit a frame [0xFF])
                $display("\n==================== 6th scenario Corner Case : (Transmit a frame [0xFF]) ====================");
                reset();  
                assign_data(8'hFF);     // send frame (0xFF)
                start_bit();
                data_bits();
                parity_bit();
                stop_bit();

            // 7th scenario Corner Case : (Transmit a frame [0x00])
                $display("\n==================== 7th scenario Corner Case : (Transmit a frame [0x00]) ====================");
                reset(); 
                assign_data(8'h00);     // send frame (0x00)
                start_bit();
                data_bits();
                parity_bit();
                stop_bit();            

            // STOP Simulatoin
                $display("\n==================== STOP Simulatoin ====================");  
                #100; 
                $stop;
        end

// monitor
    initial
        $monitor("tx_done = %d", tx_done);
endmodule