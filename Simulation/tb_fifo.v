`timescale 1ns/1ps
module tb_fifo();

    parameter data_wd = 8;                      //data width
    parameter depth = 256;                      //fifo entries
    parameter almost_full_thr = 240;            //threshold point which the almost_full flag arise at
    parameter almost_empty_thr = 16;            //threshold point which the almost_empty flag arise at

    reg clk;                                    //system clk (active high)
    reg rst;                                    //system async rst (active high)
    reg wr_en;                                  //enables write operation
    reg rd_en;                                  //enables read operation
    reg [data_wd-1 : 0] wr_data;                //data to be written
    wire full;                                  //indicates all FIFO entries are used
    wire empty;                                 //indicates all FIFO entries aren't used
    wire almost_full;                           //inidcates that there are only (depth - almost_full_thr) entries or less available
    wire almost_empty;                          //inidcates that there are only (depth - almost_empty_thr) entries or less used
    wire [data_wd-1 : 0] rd_data;               //data to be read

    //Dsign Under Test (dut) instantiation
    fifo#(
        .data_wd(data_wd), 
        .depth(depth), 
        .almost_full_thr(almost_full_thr), 
        .almost_empty_thr(almost_empty_thr)
    )
    dut_fifo(
        .clk(clk), 
        .rst(rst), 
        .wr_en(wr_en), 
        .rd_en(rd_en), 
        .wr_data(wr_data), 
        .full(full), 
        .empty(empty), 
        .almost_full(almost_full), 
        .almost_empty(almost_empty), 
        .rd_data(rd_data)
    );

    //clk generation
    initial
        begin
            clk = 0;
            forever #10 clk = ~clk;             //clk frequency (50 MHZ)
        end
    
    initial
        begin
                            //first scenario (reset operation)
            $display("\n===================== first scenario (reset operation) =====================\n");
            rst = 1; wr_en = 0; rd_en = 0; wr_data = '0;    //activate rst
            repeat(10) @(negedge clk);
            rst = 0;                                        //release rst
            if((dut_fifo.head != '0) || (dut_fifo.tail != '0) || (dut_fifo.fifo_count != '0) || (rd_data != '0))
                $display("[FAIL] : first scenario (reset operation) | head = %d, tail = %d, fifo_count = %d, rd_data = %h", 
                        dut_fifo.head, dut_fifo.tail, dut_fifo.fifo_count, rd_data);
            else
                $display("[PASS] : first scenario (reset operation)");

                            //second scenario (full detection)
            $display("\n===================== second scenario (full detection) =====================\n");
            repeat(depth)
                begin
                    wr_en = 1; wr_data = $random;
                    @(negedge clk);
                    wr_en = 0; wr_data = '0;
                end
            if(full && !empty)
                $display("[PASS] : second scenario (full detection)");
            else 
                $display("[FAIL] : second scenario (full detection) | fifo_count = %d, full = %d, empty = %d", 
                        dut_fifo.fifo_count, full, empty);

                            //third scenario (empty detection)
            $display("\n===================== third scenario (empty detection) =====================\n");
            repeat(depth)
                begin
                    rd_en = 1;
                    @(negedge clk);
                    rd_en = 0;
                end
            if(empty && !full)
                $display("[PASS] : third scenario (empty detection)");
            else 
                $display("[FAIL] : third scenario (empty detection) | fifo_count = %d, empty = %d, full = %d", 
                        dut_fifo.fifo_count, empty, full);

                            //fourth scenario (almost_full detection)
            $display("\n===================== fourth scenario (almost_full detection) =====================\n");
            rst = 1; wr_en = 0; rd_en = 0; wr_data = '0;    //activate rst
            repeat(10) @(negedge clk);
            rst = 0;                                        //release rst
            repeat(depth - almost_empty_thr)
                begin
                    wr_en = 1; wr_data = $random;
                    @(negedge clk);
                    wr_en = 0; wr_data = '0;
                end
            if(almost_full && !full && !empty && !almost_empty)
                $display("[PASS] : fourth scenario (almost_full detection)");
            else    
                $display("[FAIL] : fourth scenario (almost_full detection) | almost_full = %d, full = %d, empty = %d, almost_empty = %d, fifo_count = %d", 
                        almost_full, full, empty, almost_empty, dut_fifo.fifo_count);

                            //fifth scenario (almost_empty detection)
            $display("\n===================== fifth scenario (almost_empty detection) =====================\n");
            repeat(depth)
                begin
                    wr_en = 1; wr_data = $random;
                    @(negedge clk);
                    wr_en = 0; wr_data = '0;
                end
            repeat(depth - almost_empty_thr)
                begin
                    rd_en = 1;
                    @(negedge clk);
                    rd_en = 0;
                end
            if(almost_empty && !full && !empty && !almost_full)
                $display("[PASS] : fifth scenario (almost_empty detection)");
            else    
                $display("[FAIL] : fifth scenario (almost_empty detection) | almost_empty = %d, full = %d, empty = %d, almost_full = %d, fifo_count = %d", 
                        almost_empty, full, empty, almost_full, dut_fifo.fifo_count);

                            //sixth scenario (FIFO validation using writememh, readmemh)
            $display("\n===================== sixth scenario (FIFO validation using writememh, readmemh) =====================\n");
            rst = 1; wr_en = 0; rd_en = 0; wr_data = '0;    //activate rst
            repeat(10) @(negedge clk);
            rst = 0;                                        //release rst
            $readmemh("test_rd.txt", dut_fifo.fifo);        //storing data from "test_rd.txt" in fifo
            $writememh("test_wr.txt", dut_fifo.fifo);       //write back data from fifo in "test_wr.txt" to compare it with "test_rd.txt"
            $display("This scenario is asserted by txt files. And it's done");

                            //seventh scenario (trying write operation even fifo is full)
            $display("\n===================== seventh scenario (trying write operation even fifo is full) =====================\n");
            rst = 1; wr_en = 0; rd_en = 0; wr_data = '0;    //activate rst
            repeat(10) @(negedge clk);
            rst = 0;         
            repeat(depth - 1)
                begin
                    wr_en = 1; wr_data = $random;
                    @(negedge clk);
                    wr_en = 0; wr_data = '0;
                end
                wr_en = 1; wr_data = 10;        //random known sample (10)
                @(negedge clk);
                wr_en = 0; wr_data = '0;
            //now fifo is full
            wr_en = 1; wr_data = 20;            //trying to store another data element (20)
            @(negedge clk);
            wr_en = 0; wr_data = '0;
            //the expected behaviour : ignoring the added data element (20)
            if(dut_fifo.fifo[depth-1] != 10)
                $display("[FAIL] : seventh scenario (trying write operation even fifo is full)");
            else        
                $display("[PASS] : seventh scenario (trying write operation even fifo is full)");

                            //STOP Simulation
            #100; $stop;
        end
endmodule