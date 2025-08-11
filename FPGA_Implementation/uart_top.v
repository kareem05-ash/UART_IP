////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// Digital IC Design & ASIC Verififcation Engineer
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
module uart_top#
(   //parameters
        parameter BAUD = 9600,                          // baud rate per second
        parameter clk_freq = 50_000_000,                // system clk frequency in 'HZ'
        parameter clk_period = 1_000_000_000/clk_freq,  // system clk period in 'ns'
        parameter oversampling_rate = 16,               // to maintain valid data (avoiding noise)
        parameter data_wd = 8,                          // data width 
        parameter parity = 1,  //odd-parity             // 1:odd, 2:even, default:no-parity
        parameter fifo_depth = 256,                     // fifo entries
        parameter almost_full_thr = 240,                // threshold point which the almost_full flag arise at
        parameter almost_empty_thr = 16                 // threshold point which the almost_empty flag arise at
)
(   //system ports
    //inputs 
        input wire clk,                                 // system active-high clk signal
        input wire rst,                                 // system async. active-high reset signal
        input wire tx_wr_en,                            // fifo_tx write enable
        input wire tx_rd_en,                            // fifo_tx read enable
        input wire rx_wr_en,                            // fifo_rx write enable
        input wire rx_rd_en,                            // fifo_rx read enable
        input wire tx_start,                            // enables transmittion operation
        input wire rx_start,                            // enables reception operation
        input wire [data_wd-1 : 0] din,                 // system parallel input data
    //outputs
        output wire tx_full,                            // tx_fifo full flag
        output wire tx_empty,                           // tx_fifo empty flag
        output wire tx_almost_full,                     // tx_fifo almost_full flag
        output wire tx_almost_empty,                    // tx_fifo almost_empty flag
        output wire rx_full,                            // rx_fifo full flag
        output wire rx_empty,                           // rx_fifo empty flag
        output wire rx_almost_full,                     // rx_fifo almost_full flag
        output wire rx_almost_empty,                    // rx_fifo almost_empty flag
        output wire tx_done,                            // indicates a valid frame's been transmitted 
        output wire tx_busy,                            // inidcates that a frame is being transmitted
        output wire rx_done,                            // indicates a valid frame's been received
        output wire rx_busy,                            // indicates that a frame is being received
        output wire framing_error_flag,                 // indicates invalid start-bit, or stop-bit or noise on start-bit, stop-bit, even or data bits
        output wire parity_error_flag,                  // indicates invalid parity-bit's been received
        output wire [data_wd-1 : 0] dout                // system parallel output data                
);
    //internal signals
        wire tick;                                      // tick signal pulse from 'uart_baudgen'
        wire tx_rx;                                     // tx => rx line 
        wire [data_wd-1 : 0] din_tx;                    // fifo_tx read data output === TX parallel din
        wire [data_wd-1 : 0] dout_rx;                   // fifo_rx write data input === RX parallel dout

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

    //TX Instantiation
        uart_tx#(
            .BAUD(BAUD), 
            .clk_freq(clk_freq), 
            .clk_period(clk_period), 
            .oversampling_rate(oversampling_rate), 
            .data_wd(data_wd), 
            .parity(parity)
        )
        TX(
            .clk(clk), 
            .rst(rst), 
            .tx_start(tx_start), 
            .tick(tick), 
            .din(din_tx), 
            .tx(tx_rx), 
            .tx_done(tx_done), 
            .tx_busy(tx_busy)
        );

    //FIFO_TX Instantiation
        fifo#(
            .data_wd(data_wd), 
            .depth(fifo_depth), 
            .almost_full_thr(almost_full_thr), 
            .almost_empty_thr(almost_empty_thr)
        )
        fifo_tx(
            .clk(clk), 
            .rst(rst), 
            .wr_en(tx_wr_en), 
            .rd_en(tx_rd_en), 
            .wr_data(din),      //system parallel input data
            .full(tx_full), 
            .empty(tx_empty), 
            .almost_full(tx_almost_full), 
            .almost_empty(tx_almost_empty), 
            .rd_data(din_tx)    
        );

    //RX Instantiation
        uart_rx#(
            .BAUD(BAUD), 
            .clk_freq(clk_freq), 
            .clk_period(clk_period), 
            .oversampling_rate(oversampling_rate), 
            .data_wd(data_wd), 
            .parity(parity)
        )
        RX(
            .clk(clk), 
            .rst(rst), 
            .rx(tx_rx), 
            .tick(tick), 
            .rx_start(rx_start), 
            .rx_done(rx_done), 
            .rx_busy(rx_busy), 
            .framing_error_flag(framing_error_flag), 
            .parity_error_flag(parity_error_flag), 
            .dout(dout_rx)
        );

    //FIFO_RX Instantiation
        fifo#(
            .data_wd(data_wd), 
            .depth(fifo_depth), 
            .almost_full_thr(almost_full_thr), 
            .almost_empty_thr(almost_empty_thr)
        )
        fifo_rx(
            .clk(clk), 
            .rst(rst), 
            .wr_en(rx_wr_en), 
            .rd_en(rx_rd_en), 
            .wr_data(dout_rx), 
            .full(rx_full), 
            .empty(rx_empty), 
            .almost_full(rx_almost_full), 
            .almost_empty(rx_almost_empty),
            .rd_data(dout)  //system parallel output data
        );
endmodule