"# Conv1D"
# Introduction
This project is used to demonstrated the Effect of **loop tiling** and **parallel for loop** in Conv1D Hardware.<br>

(Origin)<br>
```C
  for(i = 0; i < 8; i++)
    for(j = 0; j < 4; j++)
      Output[i] = Output[i] + W[j] * Input[i+j];
```
(Transformed by Tiling on j)<br>
```C
  for(i = 0; i < 8; i++)
    for(j = 0; j < 4; j+=2)
      for(k = j; k < 2; k++)
      Output[i] = Output[i] + W[j] * Input[i+j];
```

(Transformed by Loop Interchange)<br>
```C
  for(j = 0; j < 4; j+=2)
    for(i = 0; i < 8; i++)
      for(k = j; k < 2; k++)
      Output[i] = Output[i] + W[j] * Input[i+j];
```

Compute Sequence is showed in below figure.<br>
<img src="https://ppt.cc/fJgSUx@.jpg">

# Framework
Processing Element(Convolution Core) + Memory Controller + Memory Module(DRAM Memory + L0 Buffer)<br>
<img src="https://ppt.cc/fo8WFx@.png">
*notes 1: All the Data which are needed by Computing need to be fetched only from L0 Buffer.*<br> 
*notes 2: I assume the Number of overhead of DRAM loading cycles is 100 cycles.*<br>
<img src="https://ppt.cc/fCK4ex@.jpg">
*Assume Number of Data to be load is 4.*<br>

# Memory Controller Components
<img src="https://ppt.cc/fXdeKx@.jpg">

## Mem_Reset.v
To Clear the content of DRAMs or L0 Buffers.<br>

## Computation_Step_Counter.v
There are 2 Registers **Computation_Step_Counter** and **L0_Computation_Step_Counter** to record the Computation Steps.<br>

**Computation_Step_Counter**: Count until reach Number of Total Computation Steps.<br>
**L0_Computation_Step_Counter**: Count until reach Number of Total Computation Steps at each phase.<br><br>
*L0_Output_Nums = 8*<br>
*L0_Weight_Nums = 2*<br>
*Pipeline_Stage_Nums = 4*<br>
*Pipeline_Tail_Nums: Pipeline_Stage_Nums - 2 = 2*<br>
*Phases_Nums = 2*<br>
*Loading_Overhead_Cycles = 100*<br>
*Loading_Cycles = Loading_Overhead_Cycles + Data_Nums + Pipeline_Tail*<br>
*L0 Computation Steps: (L0_Weight_Nums * L0_Output_Nums) + Pipeline_Tail_Nums*<br>
*Total_Steps: (Loading_Cycles + L0_Computing_Steps) * Phase_Nums<br>*<br>

## L0_Loading_Cycle_Counter.v
For Simulating the delay of slow DRAM Access.<br>
I assume loading overhead is 100 clock cycles.<br> 
After 100 cycle, the data can be smoothly bumped into L0 Buffer at each cycle.<br>

## L0_Status_Setting.v
To set the L0 status.

*2'b00: Nothing.(default)*<br>
*2'b01: Loading is in progress.*<br>
*2'b10: Computing.*<br>
*2'b11: Computation is done.*<br>

<img src="https://ppt.cc/f8ytox@.jpg">

## Signal_Setting.v
To set the loading (from file) and writing (to file) States.<br>

## Mem_Access_Index_Setting.v
To set the Memory and L0 Buffer Acceess Index.<br>
```verilog
case(L0_Status):
2'b00: if (loading_from_file) then set Memory Index
2'b01: set Memory Index
2'b10: set Buffer Access Index
2'b11: x
```

## Mem_Signal_Setting.v
To set the Memory Signals(Chip_Select, En_Write, En_Read, Write_Addr, Read_Addr).
```verilog
case(L0_Status):
2'b00: if (loading_from_file) then set Memory Signals
2'b01: set Memory Signals
2'b10: set Buffer Signals
2'b11: x
```
