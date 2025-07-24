module uart_tx#
(
    parameter BAUD = 9600,                          //baud rate per second
    parameter clk_freq = 50_000_000,                //system clk frequency in 'HZ'
    parameter clk_period = 1_000_000_000/clk_freq,  //system clk period in 'ns'
    parameter oversampling_rate = 16,               //to maintain valid data (avoiding noise)
    parameter data_wd = 8,                          //data width 
    parameter parity = 0                            //1:odd, 2:even, default:no-parity
)
(
    input clk,                                      //system clk
    input rst,                                      //system async. active-high reset
    input tx_start,                                 //signal to initiate data (allow the transimition operation)
    input tick,                                     //pulse to transimit one bit (from baud generator)
    input [data_wd-1 : 0] din,                      //parallel input data to be tarnsimitted
    output reg tx,                                  //serial parallel output line
    output reg tx_done,                             //flag indicates that the trans. operation's done
    output reg tx_busy                              //flag indicates that the trans. operation is being excuted
);
    //states encoding (One-Hot) to minimize glitches
    localparam IDLE   = 6'b000001,                  //waits for tx_start = 1
               START  = 6'b000010,                  //start-bit = 0
               DATA   = 6'b000100,                  //transmit 8-bit data (LSB -> MSB)
               PARITY = 6'b001000,                  //sending parity bit if enabled
               STOP   = 6'b010000,                  //stop-bit = 1
               DONE   = 6'b100000;                  //raise tx_done. go back to IDLE

    wire parity_en = (parity == 1 || parity == 2)? 1 : 0;
    wire parity_res = (parity == 1)? ^din : ((parity == 2)? ~^din : 0);
    reg[5:0] c_state, n_state;
    reg[$clog2(oversampling_rate)-1 : 0] tick_count;
    reg[$clog2(data_wd)-1 : 0] bit_index;

    //state transitions
    always@(posedge clk or posedge rst)
        begin
            if(rst)
                c_state <= IDLE;
            else
                c_state <= n_state;
        end

    //n_state handling (combinational)
    always@(*)
        case(c_state)
            IDLE    : n_state = tx_start? START : IDLE;
            START   : n_state = (tick_count == (oversampling_rate-1))? DATA : START;
            DATA    : n_state = ((tick_count == (oversampling_rate-1)) && (bit_index == (data_wd-1)))? (parity_en? PARITY : STOP) : DATA;
            PARITY  : n_state = (tick_count == (oversampling_rate-1))? STOP : PARITY;
            STOP    : n_state = (tick_count == (oversampling_rate-1))? DONE : STOP;
            DONE    : n_state = tx_done? IDLE : DONE;   //tx_done is raised means that the frame's transmitted successfully.
            default : n_state = IDLE;
        endcase  

    //output assinging & counters logic (sequential)
    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    tick_count <= 0;
                    bit_index <= 0;
                    tx_done <= 0;
                    tx_busy <= 0;
                    tx <= 1;        //waits for the start-bit (active-low)
                end
            else
                begin
                    case(c_state)
                        IDLE    : tx_busy <= tx_start;
                        START   : tx <= 0;    //start-bit
                        DATA    : 
                                if(tick && tick_count == 0)
                                    begin
                                        tx <= din[bit_index];
                                        bit_index <= bit_index + 1;
                                    end 
                        PARITY  : tx <= parity_res;
                        STOP    : tx <= 1;    //stop-bit
                        DONE    :
                                begin
                                    tx_busy <= 0;
                                    tx <= 1;    //waits for a start-bit to another frame
                                    tx_done <= 1;
                                end
                        default : 
                                begin
                                    tick_count <= 0;
                                    bit_index <= 0;
                                    tx_done <= 0;
                                    tx_busy <= 0;
                                    tx <= 1;        //waits for the start-bit (active-low) 
                                end
                    endcase
                end
            if(tick)
                if(tick_count == oversampling_rate-1)
                    tick_count <= 0;
                else    
                    tick_count <= tick_count + 1;
        end
endmodule