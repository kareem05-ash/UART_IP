# (و ما توفيقى إلا بالله)
# UART (Universal Asynchrounus Receiver/Transmitter)    

The project implements a **UART(Universal Asynchronous Receiver/Transmitter)** module using **Verilog HDL**, designed for FPGA-based digital systems. The design includes both transmitter **uart_tx** and receiver **uart_rx** modules, supporting configurable baud rate, parity checking, data width, fifo depth, and oversampling for noise reduction.      
The frame consists of: **start-bit**, **data-bits** LSB => MSB, **parity-bit** if enabled, and finally, **stop-bit**.   
### Frame Sequence  
![Frame Sequence](Docs/frame.png)

--- 

## Table of Contents (TOC)      

- [Folder Structure](#floder-structure)
- [Block Diagram & Module Interfaces](#block-diagram--module-interfaces)
- [Reusability & Configurable Parameters](#reusability--configurable-parameters)
- [FSM](#fsm)
- [Testbenches](#testbenches)
    - [Top TB](#top-tb)
    - [RX TB](#rx-tb)
    - [TX TB](#tx-tb)
    - [FIFO TB](#fifo-tb)
    - [Baud Generator TB](#baud-generator-tb)
- [How to Run](#how-to-run)
- [Future Work](#future-work)
- [Author](#author)
- [NOTEs](#notes)

---         

## Folder Structure

```UART_IP/
├── Docs/ # Block Diagram, State Digrams, transcript output, waveform snippets, ....
├── RTL/ # RTL Design
│   ├── uart_top.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── uart_fifo.v
│   └── uart_baudgen.v
├── TB/ # Testbenches
│   ├── tb_top.v
│   ├── tb_rx.v
│   ├── tb_tx.v
│   ├── tb_fifo.v
│   ├── tb_baudgen.v
│   ├── test_rd.txt # for tb_fifo.v
│   └── test_wr.txt # for tb_fifo.v
├── Simulation/
│   ├── trans_out.log   # Sotres Transcript output for tb_top.v
│   ├── top.do  
│   ├── rx.do
│   ├── tx.do
│   ├── fifo.do
│   └── baudgen.do
├── LICENSE
└── README.md
```            

---         

## Block Diagram & Module Interfaces

The design consists of 5 modules: **TX**, **RX**, **Baud Generator**, **FIFO_TX**, and **FIFO_RX**. Baud Generator module generates a `tick` signal for **TX** and **RX**. Input data `din` get into **FIFO_TX** then **FIFO_TX** feeds **TX** module. Data is transmitted bit-by-bit on line `tx_rx` from **TX** to **RX**. `dout_rx` get into **FIFO_RX** then **FIFO_RX** buffers `dout_rx` as `dout`. 

### Block Diagram       

![Block Diagram](Docs/UART_block_diagram.png)

---             

## Reusability & Configurable Parameters

The design is considered **Fully Parameterized**. It has 9 parametrs.       
### Parameter Declaration      
![Parameters](Docs/parameters.png)      

- **BAUD**: Baud rate per second. `uart_baudgen` generates a tick pulse every **BAUD** clk cycles. Default value & most common rate used is *9600*.
- **clk_freq**: Frequency of system clk signal. Default value is *50 MHZ*. 
- **clk_period**: The period of the clk signal. It measured in **ns**.  
- **oversampling_rate**: Used to sample data bits to avoid noise or glitches on line. Default value & most common rate used is *16*.    
- **data_wb**: Data Width. Default value is *8*. 
- **parity**: This for parirty enable & type. If(parity == 1), **odd-parity**. Else if(parity == 2), **even-parity**. Else, no-parity: parity is disabled. Default value is *1: odd-parity*. 
- **fifo_depth**: Number of max frames can **FIFO_TX** or **FIFO_RX** can store. Default value is *256*.    
- **almost_full_thr**: This is for FIFOs. If the FIFO stores frames greater than or equal **almost_full_thr**, Flag **almost_full** goes high. Default value is *240*.        
- **almost_empty_thr**: This is for FIFOs. If the FIFO stores frames less than or equal **almost_empty_thr**, Flag **almost_empty** goes high. Default value is *16*.           

---             

## FSM



---         