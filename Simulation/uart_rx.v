module uart_rx#
(
    parameter BAUD = 9600,                      //baud rate per second
    parameter clk_freq = 50_000_000,            //system clk frequency
    parameter oversampling_rate = 16,           //to maintain valid data (avoiding noise) : transimits data @ tick-7 pulse
    parameter data_wd = 8,                      //data width
    parameter [1:0] parity = 0                  //1:odd-parity, 2:even-parity, default:no-parity
)
(
    input clk,                                  //system clk
    input rst,                                  //system async. active-high reset
    input rx,                                   //serial data-in
    input tick,                                 //pulse from BAUD Generator
    input rx_start,                             //allows recieving operation
    output reg rx_done,                         //indicates a single frame's been recieved successfully
    output reg rx_busy,                         //indicates that a frame is being recieved
    output reg framing_error_flag,              //indicates errors (noise, incorrect start or stop bits)
    output reg parity_error_flag,               //indicates parity errors. if parity-bit recieved doesn't equall parity_expected
    output reg [data_wd-1 : 0] dout             //parallel output data
);
    localparam IDLE   = 3'b000,                 //waits for tx_start = 1
               START  = 3'b001,                 //start-bit = 0
               DATA   = 3'b011,                 //transmit 8-bit data (LSB -> MSB)
               PARITY = 3'b010,                 //sending parity bit if enabled
               STOP   = 3'b110,                 //stop-bit = 1
               DONE   = 3'b111;                 //raise tx_done. go back to IDLE

    reg bit_test;   //to hold the value of rx @(tick_count = 0) to compare it with rx @(tick_count == 7)
    reg[2:0] c_state, n_state;
    reg[$clog2(oversampling_rate)-1 : 0] tick_count;
    reg[$clog2(data_wd)-1 : 0] bit_index;
    reg[data_wd-1 : 0] recieved_data;
    wire parity_en = (parity == 1 || parity == 2)? 1 : 0;
    wire parity_expected = (parity == 1)? ^recieved_data : ((parity == 2)? ~^recieved_data : 0);

    //state transitions (sequential)
    always@(posedge clk or posedge rst)
        if(rst)
            c_state <= IDLE;
        else
            c_state <= n_state;

    //n_state handeling (combinational)
    always@(*)
        begin
            case(c_state)
                IDLE    : n_state = rx_start? START : IDLE;
                START   : n_state = (tick_count == (oversampling_rate-1))? DATA : START;
                DATA    : n_state = ((tick_count == (oversampling_rate-1)) && (bit_index == data_wd-1))? (parity_en? PARITY : STOP) : DATA;
                PARITY  : n_state = (tick_count == (oversampling_rate-1))? STOP : PARITY;
                STOP    : n_state = (tick_count == (oversampling_rate-1))? DONE : STOP;
                DONE    : n_state = rx_done? IDLE : DONE;
                default : n_state = IDLE;
            endcase
        end 

    //output assigning and counters
    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    dout <= 0;
                    rx_done <= 0;
                    rx_busy <= 0;
                    bit_index <= 0;
                    tick_count <= 0;
                    // recieved_data <= 0;
                    parity_error_flag <= 0;
                    framing_error_flag <= 0;
                end
            else
                case(c_state)   
                    IDLE    : 
                            begin
                                rx_busy <= rx_start;
                                rx_done <= 0;
                                bit_index <= 0;
                                tick_count <= 0;
                                // recieved_data <= 0;
                                parity_error_flag <= 0;
                                framing_error_flag <= 0;
                            end
                    START   : 
                            if(tick_count == 7)
                                if(rx)
                                    framing_error_flag <= 1;        //start-bit error
                                else    
                                    framing_error_flag <= 0;
                    DATA    : 
                            begin
                                if(tick_count == 0)
                                    bit_test <= rx;
                                if(tick_count == 7)
                                    if(bit_test == rx)
                                        begin
                                            recieved_data[bit_index] <= rx;
                                            bit_index <= bit_index + 1;
                                            framing_error_flag <= 0;
                                        end 
                                    else    
                                        framing_error_flag <= 1;    //noise at recieved bit
                            end
                    PARITY  : 
                            if(tick_count == 7)
                                if(rx == parity_expected)
                                    parity_error_flag <= 0;
                                else
                                    parity_error_flag <= 1;
                    STOP    : 
                            if(tick_count == 7)
                                if(rx)      //valid stop-bit
                                    framing_error_flag <= 0;
                                else 
                                    framing_error_flag <= 1;
                    DONE    : 
                            begin
                                dout <= recieved_data;
                                rx_busy <= 0;
                                rx_done <= 1;
                            end
                    default : 
                            begin
                                dout <= 0;
                                rx_done <= 0;
                                rx_busy <= 0;
                                bit_index <= 0;
                                tick_count <= 0;
                                recieved_data <= 0;
                                parity_error_flag <= 0;
                                framing_error_flag <= 0;
                            end
                endcase

            if(tick)        //tick_count logic
                if(tick_count == oversampling_rate-1)
                    tick_count <= 0;
                else
                    tick_count <= tick_count + 1;
            
            if(framing_error_flag || parity_error_flag)
                begin
                    n_state = IDLE;
                    dout = 0;
                    $display("Error : framing_error_flag = %d, parity_error_flag = %d, dout = %h, c_state = %b, bit_index = %d",
                             framing_error_flag, parity_error_flag, dout, c_state, bit_index);
                end
        end
endmodule