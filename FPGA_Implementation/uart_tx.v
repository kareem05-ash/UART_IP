////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
module uart_tx#
(   // parameters
        parameter BAUD = 9600,                          //baud rate per second
        parameter clk_freq = 50_000_000,                //system clk frequency in 'HZ'
        parameter clk_period = 1_000_000_000/clk_freq,  //system clk period in 'ns'
        parameter oversampling_rate = 16,               //to maintain valid data (avoiding noise)
        parameter data_wd = 8,                          //data width 
        parameter parity = 1                            //1:odd, 2:even, default:no-parity
)
(   // Ports
    // Inputs
        input wire clk,                                 // active-hgih clk signal
        input wire rst,                                 // async active-high rst signal
        input wire tx_start,                            // enables transmittion operation
        input wire tick,                                // tick pulse from uart_baudgen
        input wire [data_wd-1 : 0] din,                 // parallel input data
    // Outputs
        output reg tx,                                  // serial output data line
        output reg tx_done,                             // indicates that, the transmittion operatoin's done successfully
        output reg tx_busy                              // indicates that, the transmittion operation's being processed                              
);
    // Needed Internal Signals
        reg [5:0] c_state, n_state;                     // current & next state registers
        reg [$clog2(oversampling_rate)-1 : 0] tick_count;   
        reg [$clog2(data_wd+1)-1 : 0] bit_index;        // counts bit indeces from 0 up to data_wd.
        wire parity_en = (parity == 1 || parity == 2);  // if parity = (1, 2) (odd, even), parity-bit is enables
        wire parity_res = parity_en? ((parity == 1)? ~(^din) : ^din) : 0;

    // State Encoding : OneHot to minmize glitches
        localparam  IDLE    = 6'b000001,                // waits for tx_start signal
                    START   = 6'b000010,                // send start-bit (1'b0)
                    DATA    = 6'b000100,                // send all data bits
                    PARITY  = 6'b001000,                // send parity-bit
                    STOP    = 6'b010000,                // send stop-bit (1'b1)
                    DONE    = 6'b100000;                // waits to assert that, tx_done is high 

    // State Transitions
        always@(posedge clk or posedge rst) begin
            if(rst) begin
                c_state <= IDLE;    // default state : waits for a new fram
            end else begin
                c_state <= n_state; // update state 
            end
        end

    // Next State Logic (combintional)
        always@(*)begin
            case(c_state)
                IDLE    : n_state = tx_start? START : IDLE; 
                START   : n_state = (tick_count == oversampling_rate-1)? DATA : START;
                DATA    : n_state = (tick_count == oversampling_rate-1 && bit_index == data_wd)? (parity_en? PARITY : STOP) : DATA;
                PARITY  : n_state = (tick_count == oversampling_rate-1)? STOP : PARITY;
                STOP    : n_state = (tick_count == oversampling_rate-1)? DONE : STOP;
                DONE    : n_state = tx_done? IDLE : DONE;   // if tx_done is raised, the transmittion opearation's done successfully 
                default : n_state = IDLE;   // default state : waits for a new frame
            endcase
        end

    // Outputs & Counters Logic (sequential)
        always@(posedge clk or posedge rst)begin
            if(rst)begin
                tx <= 1;                                // waits for start-bit (1'b0)
                tx_busy <= 0;                           // no frames are being transmitted 
                tx_done <= 0;                           // no frames've transmitted 
                bit_index <= 0;                         // reset bit counter for new frames
                tick_count <= 0;                        // reset tick counter for new frames
            end else begin
                // tick_count logic
                    if(tick)begin
                        if(tick_count == oversampling_rate-1)begin
                            tick_count <= 0;            // reset the counter to sample another bit
                        end else begin
                            // if it's not full, increment the counter
                            tick_count <= tick_count + 1;
                        end
                    end
                
                // ouputs & bit_index logic
                    case(c_state)
                        IDLE    : begin
                            tx <= 1;        // default
                            tx_done <= 0;   // default
                            bit_index <= 0; // default
                            // reset tick_counter to sample start-bit
                            tick_count <= 0;
                            // if (tx_start), then the transmittion operation's enabled
                            tx_busy <= tx_start;
                        end
                        START   : begin
                            if(tick)
                                tx <= 1'b0; // send start-bit (1'b0)
                            tx_busy <= 1;   // a frame is being transmitted
                            tx_done <= 0;   // no frame's been transmitted 
                            // reset bit_index counter to transmit data bits properly
                            bit_index <= 0;
                        end
                        DATA    : begin
                            if(tick && bit_index != data_wd)begin
                                if(tick_count == 0)begin
                                    // send data-bit
                                    tx <= din[bit_index];
                                    // increment bit_index counter to send the adjacent bit
                                    bit_index <= bit_index + 1;
                                end
                            end
                            tx_busy <= 1;   // a frame is being transmitted
                            tx_done <= 0;   // no frame's been transmitted 
                        end
                        PARITY  : begin
                            if(tick)begin   // send parity-bit
                                tx <= parity_res;       
                            end
                            tx_busy <= 1;   // a frame is being transmitted
                            tx_done <= 0;   // no frame's been transmitted 
                        end
                        STOP    : begin
                            if(tick)begin   // send stop-bit
                                tx <= 1;    // stop-bit (1'b1)
                            end
                            tx_busy <= 1;   // a frame is being transmitted
                            tx_done <= 0;   // no frame's been transmitted 
                        end
                        DONE    : begin
                            // the transmition operation's done successully
                            if(tick)
                                tx_done <= 1'b1;      
                        end
                        default : begin
                            tx <= 1;                // waits for start-bit (1'b0)
                            tx_busy <= 0;           // no frames are being transmitted 
                            tx_done <= 0;           // no frames've transmitted 
                            bit_index <= 0;         // reset bit counter for new frames
                            tick_count <= 0;        // reset tick counter for new frames
                        end
                    endcase
                // tick_count has to reset its value before entering another state
                    if(c_state != n_state)
                        // reset the tick_count
                        tick_count <= 0;
            end
        end

endmodule