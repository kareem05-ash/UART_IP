////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
module uart_rx#
(
    parameter BAUD = 9600,                          //baud rate per second
    parameter clk_freq = 50_000_000,                //system clk frequency in 'HZ'
    parameter clk_period = 1_000_000_000/clk_freq,  //system clk period in 'ns'
    parameter oversampling_rate = 16,               //to maintain valid data (avoiding noise)
    parameter data_wd = 8,                          //data width 
    parameter [1:0] parity = 1                      //1:odd, 2:even, default:no-parity
)
(
    input wire clk,                                 //system clk
    input wire rst,                                 //system async. active-high reset
    input wire rx,                                  //serial input data
    input wire tick,                                //pulse from baud generator
    input wire rx_start,                            //signal allows receiving operation
    output reg rx_done,                             //indicates that a single frame's been received successfully 
    output reg rx_busy,                             //indicates that a single frame is being received
    output reg parity_error_flag,                   //indicates parity errors. if parity received doesn't equal parity expected
    output reg framing_error_flag,                  //indicates start-bit, stop-bit, or data-bits error (noise)
    output reg [data_wd-1 : 0] dout                 //parallel output data
);

    //states encoding (One-Hot) to minimize glitches
    localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
               START  = 6'b000010,                  //start-bit = 0
               DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
               PARITY = 6'b001000,                  //sending parity bit if enabled
               STOP   = 6'b010000,                  //stop-bit = 1
               DONE   = 6'b100000;                  //raise tx_done. go back to IDLE

    reg test_bit;                                   //holds received bit @(tick = 0) ot campare it with received bit @(tick = oversampling_rate/2)
    reg [5:0] c_state, n_state;                     //state registers
    reg [data_wd-1 : 0] received_data;              //register stores the data bits until the frame stops correctly to assign it to 'dout'
    reg [$clog2(data_wd+1)-1 : 0] bit_index;        //counts data bits received
    reg [$clog2(oversampling_rate)-1 : 0] tick_count;   
    wire parity_en = (parity == 1 || parity == 2);   
    wire parity_expected = (parity == 2)? ^received_data : ~^received_data;

    //state transition logic (sequential)
    always@(posedge clk or posedge rst)
        if(rst || framing_error_flag || parity_error_flag)
            c_state <= IDLE;                        //default state
        else       
            c_state <= n_state;

    //n_state logic (combinational)
    always@(*)
        case(c_state)
            IDLE    : n_state = rx_start? START : IDLE;       
            START   : n_state = (tick_count == (oversampling_rate-1))? DATA : START;
            DATA    : n_state = ((tick_count == (oversampling_rate-1)) && (bit_index == data_wd))? (parity_en? PARITY : STOP) : DATA;
            PARITY  : n_state = (tick_count == (oversampling_rate-1))? STOP : PARITY;
            STOP    : n_state = (tick_count == (oversampling_rate-1))? DONE : STOP;
            DONE    : n_state = rx_done? IDLE : DONE;   //rx_done is raised means that the frame's received successfully.
            default : n_state = IDLE;
        endcase

    //outputs and counters logic (sequential)
    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    framing_error_flag <= 0;
                    parity_error_flag <= 0;
                    received_data <= 0;
                    tick_count <= 0;
                    bit_index <= 0;
                    test_bit <= 0;
                    rx_done <= 0;
                    rx_busy <= 0;
                end
            else
                begin
                    case(c_state)
                        IDLE    : 
                                begin
                                    framing_error_flag <= 0;
                                    parity_error_flag <= 0;
                                    received_data <= 0;
                                    bit_index <= 0;     //reset the counter after the previous frame (bit_count was 8)
                                    rx_done <= 0;
                                    rx_busy <= 0;       //waits for 'rx_start' signal to be raised
                                    if(rx_start)
                                        begin
                                            tick_count <= 0;    //reset the counter to sample start-bit
                                            rx_busy <= 1;       //start receiving the frame
                                        end
                                end
                        START   : 
                                begin
                                    bit_index <= 0;             //reset the counter to maintain the expected behavior (receiving all data bits)
                                    if(tick)
                                        begin
                                            if(tick_count == 1)
                                                test_bit <= rx;             //storing the start-bit
                                            if((tick_count == oversampling_rate/2) && ((test_bit != rx) || rx))
                                                framing_error_flag <= 1;    //noise on start-bit
                                        end
                                end
                        DATA    : 
                                begin
                                    if(tick)
                                        begin
                                            if(tick_count == 1)
                                                test_bit <= rx;     //storing data bit to sample it 
                                            if(tick_count == oversampling_rate/2)
                                                if(test_bit != rx)
                                                    framing_error_flag <= 1;    //noise on data bits
                                                else    
                                                    begin
                                                        received_data [bit_index] <= rx;
                                                        bit_index <= bit_index + 1;     //increment the counter to receive the next bit
                                                    end
                                        end
                                end
                        PARITY  : 
                                begin
                                    if(tick)
                                        begin
                                            if(tick_count == 1)
                                                test_bit <= rx;     //storing the parity bit to sample it 
                                            if(tick_count == oversampling_rate/2)
                                                if(test_bit != rx)
                                                    framing_error_flag <= 1;    //noise on parity bit
                                                else if(rx != parity_expected)
                                                    parity_error_flag <= 1;     //parity error 
                                        end
                                end
                        STOP    : 
                                begin
                                    if(tick)
                                        begin
                                            if(tick_count == 1)
                                                test_bit <= rx;     //storing the stop-bit
                                            if((tick_count == oversampling_rate/2) && ((test_bit != rx) || !rx))
                                                framing_error_flag <= 1;    //noise on stop-bit                                            
                                        end
                                end
                        DONE    : 
                                begin
                                    dout <= received_data;  //assigning the received data to the output data port
                                    rx_done <= 1;           //indicates valid reciption process
                                end
                        default :
                                begin       //reset operation
                                    framing_error_flag <= 0;
                                    parity_error_flag <= 0;
                                    received_data <= 0;
                                    tick_count <= 0;
                                    bit_index <= 0;
                                    test_bit <= 0;
                                    rx_done <= 0;
                                    rx_busy <= 0;
                                    dout <= 0;
                                end
                    endcase
                end
            // tick counter logic
            if(tick)    
                if(tick_count == oversampling_rate-1)
                    tick_count <= 0;                //reset the counter
                else        
                    tick_count <= tick_count + 1;   //increment the counter if not full
            // framing, parity errors handling
            if(framing_error_flag || parity_error_flag)
                begin
                    n_state <= IDLE;
                    dout <= 0;
                end
        end 
endmodule