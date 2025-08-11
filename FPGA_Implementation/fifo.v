////////////////////////////////////////////////////
// Kareem Ashraf Mostafa
// Digital IC Design & ASIC Verififcation Engineer
// kareem.ash05@gmail.com
// 01002321067
// github.com/kareem05-ash
////////////////////////////////////////////////////
module fifo#
(
    parameter data_wd = 8,                      //data width
    parameter depth = 256,                      //fifo entries
    parameter almost_full_thr = 240,            //threshold point which the almost_full flag arise at
    parameter almost_empty_thr = 16             //threshold point which the almost_empty flag arise at
)
(
    input wire clk,                             //system clk (active high)
    input wire rst,                             //system async rst (active high)
    input wire wr_en,                           //enables write operation
    input wire rd_en,                           //enables read operation
    input wire [data_wd-1 : 0] wr_data,         //data to be written
    output wire full,                           //indicates all FIFO entries are used
    output wire empty,                          //indicates all FIFO entries aren't used
    output wire almost_full,                    //inidcates that there are only (depth - almost_full_thr) entries or less available
    output wire almost_empty,                   //inidcates that there are only (depth - almost_empty_thr) entries or less used
    output reg [data_wd-1 : 0] rd_data          //data to be read
);
    reg [$clog2(depth) : 0] head;               //head pointer : which points to the data will be read
    reg [$clog2(depth) : 0] tail;               //tail pointer : which points to the data will be written
    reg [$clog2(depth + 1)-1 : 0] fifo_count;   //its vaule represents the number of data which fifo holds (min:0 , max:depth)
    reg [data_wd-1 : 0] fifo [0 : depth-1];     //fifo register

    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    head <= 0;                  
                    tail <= 0;
                    rd_data <= 0;
                    fifo_count <= 0;
                end
            else 
                begin
                    if((wr_en && !full) && !(rd_en && !empty))
                        fifo_count <= fifo_count + 1;       //fifo holds another entry
                    else if((rd_en && !empty) && !(wr_en && !full))
                        fifo_count <= fifo_count - 1;       //fifo releases an entry
                    if(wr_en && !full)
                        begin
                            fifo[tail] <= wr_data;
                            tail <= (tail == depth-1)? 0 : tail + 1;
                        end
                    if(rd_en && !empty)
                        begin
                            rd_data <= fifo[head];
                            head <= (head == depth-1)? 0 : head + 1;
                        end
                end
        end
    //statue flags logic
    assign full = (fifo_count == depth);
    assign empty = (fifo_count == 0);
    assign almost_full = (fifo_count >= almost_full_thr);
    assign almost_empty = (fifo_count <= almost_empty_thr);
endmodule