/*
	SRAMs:
		SRAM_0: for Weight
		SRAM_1: for input
		SRAM_2: for output

	Buffers:
		Buffer_0: for weight
		Buffer_1: for input
		Buffer_2: for output
*/
module Conv1D
		#(	
			parameter Data_Width_In = 8,
			parameter Data_Width_Out = 2 * Data_Width_In,
			parameter Weight_Addr_Width = 2,
			parameter Output_Addr_Width = 3,
			parameter Input_Addr_Width = 4, 
			parameter Nums_SRAM_In = 2,
			parameter Nums_SRAM_Out = 1,
			parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
			parameter Weight_Nums = 4,
			parameter Output_Nums = 8,
			parameter Input_Nums = Output_Nums - Weight_Nums + 1,
			parameter Nums_Pipeline_Stages = 4,
			parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
			parameter Total_Computation_Steps_in_bits = 6,
			parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail,
			parameter Weight_Para_Deg = 1,
			parameter Output_Para_Deg = 1,
			parameter Input_Para_Deg = Weight_Para_Deg * Output_Para_Deg,
			parameter Nums_L0_In = 2,
			parameter Nums_L0_Out = 1,
			parameter Nums_L0 = Nums_L0_In + Nums_L0_Out,
			parameter L0_Weight_Addr_Width = 1,
			parameter L0_Input_Addr_Width = 1,
			parameter L0_Output_Addr_Width = 1,
			parameter L0_Weight_Nums = 1 << L0_Weight_Addr_Width,
			parameter L0_Input_Nums = 1 << L0_Input_Addr_Width,
			parameter L0_Output_Nums =  1 << L0_Output_Addr_Width,
			parameter Loading_From_Mem_Cycles_Start_Overhead = 100,
			parameter LO_Weight_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Weight_Nums,
			parameter LO_Input_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Input_Nums,
			parameter LO_Output_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Output_Nums,
			parameter L0_Computation_Steps_in_bits = 5,
			parameter L0_Computation_Steps = L0_Weight_Nums * L0_Output_Nums + Pipeline_Tail
		)
		(clk, Mem_Reset, L0_Reset, Comp_Reset, Mem_Weight_Index_Reset, Mem_Output_Index_Reset, Mem_Input_Index_Reset,
		L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset, 
		PE_reset,
		Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal, Computing_Signal,
		Weight_Data_From_File, Input_Data_From_File, Output_Data_From_File, Output_Data_To_File,
		result, state,
		L0_Weight_Status, L0_Input_Status, L0_Output_Status,
		Mem_Weight_Index); 
				
		input clk, Mem_Reset, L0_Reset, Comp_Reset, Mem_Weight_Index_Reset, Mem_Output_Index_Reset, Mem_Input_Index_Reset;
		input L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset;
		input PE_reset;
		input Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal, Computing_Signal;

		input [Weight_Para_Deg * Data_Width_In - 1:0] Weight_Data_From_File;
		input [Input_Para_Deg * Data_Width_In - 1:0] Input_Data_From_File;
		input [Output_Para_Deg * Data_Width_Out - 1:0] Output_Data_From_File;
		output [Output_Para_Deg * Data_Width_Out - 1:0] Output_Data_To_File;

		output [Output_Para_Deg * Data_Width_Out - 1:0] result;
		output [Total_Computation_Steps_in_bits:0] state;
		output [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
		output Mem_Weight_Index;

		wire [Nums_SRAM - 1:0] Mem_Clear, Mem_En_CS, Mem_En_W, Mem_En_R;
		wire [Weight_Addr_Width - 1:0] Mem_Weight_Addr_Read, Mem_Weight_Addr_Write;
		wire [Output_Addr_Width - 1:0] Mem_Output_Addr_Read, Mem_Output_Addr_Write;
		wire [Input_Addr_Width - 1:0] Mem_Input_Addr_Read, Mem_Input_Addr_Write;

		wire [Nums_L0 - 1:0] L0_Clear, L0_En_CS, L0_En_W, L0_En_R;
		wire [L0_Weight_Addr_Width - 1:0] L0_Weight_Addr_Read, L0_Weight_Addr_Write;
		wire [L0_Output_Addr_Width - 1:0] L0_Input_Addr_Read, L0_Input_Addr_Write;
		wire [L0_Input_Addr_Width - 1:0] L0_Output_Addr_Read, L0_Output_Addr_Write;

		wire [Weight_Para_Deg * Data_Width_In - 1:0] Weight_Data_Read, Weight_Data_Write;
		wire [Input_Para_Deg * Data_Width_In - 1:0] Input_Data_Read, Input_Data_Write;
		wire [Output_Para_Deg * Data_Width_Out - 1:0] Output_Data_Read, Output_Data_Write;

		wire Initial_Accumulate;

		wire Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File;

		assign Weight_Data_Write = Weight_Loading_From_File ? Weight_Data_From_File : 0;
		assign Input_Data_Write = Input_Loading_From_File ? Input_Data_From_File : 0;
		assign Output_Data_Write = Output_Loading_From_File ? Output_Data_From_File : result;
		assign Output_Data_To_File = Output_Writing_To_File ? Output_Data_Read : 0 ;
		

		MEMController #(.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width),
		.Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out), .Nums_SRAM(Nums_SRAM),
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Input_Nums(Input_Nums),
		.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail),
		.Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits), .Total_Computation_Steps(Total_Computation_Steps),
		.Weight_Para_Deg(Weight_Para_Deg), .Output_Para_Deg(Output_Para_Deg), .Input_Para_Deg(Input_Para_Deg),
		.Nums_L0_In(Nums_L0_In), .Nums_L0_Out(Nums_L0_Out), .Nums_L0(Nums_L0),
		.L0_Weight_Addr_Width(L0_Weight_Addr_Width), .L0_Input_Addr_Width(L0_Input_Addr_Width), .L0_Output_Addr_Width(L0_Output_Addr_Width),
		.L0_Weight_Nums(L0_Weight_Nums), .L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums),
		.Loading_From_Mem_Cycles_Start_Overhead(Loading_From_Mem_Cycles_Start_Overhead),
		.LO_Weight_Loading_From_Mem_Cycles(LO_Weight_Loading_From_Mem_Cycles), 
		.LO_Input_Loading_From_Mem_Cycles(LO_Input_Loading_From_Mem_Cycles),
		.LO_Output_Loading_From_Mem_Cycles(LO_Output_Loading_From_Mem_Cycles),
		.L0_Computation_Steps_in_bits(L0_Computation_Steps_in_bits),
		.L0_Computation_Steps(L0_Computation_Steps))
		memcontroller (.clk(clk), .Mem_Reset(Mem_Reset), .L0_Reset(L0_Reset), .Comp_Reset(Comp_Reset), 
		.Mem_Weight_Index_Reset(Mem_Weight_Index_Reset), .Mem_Output_Index_Reset(Mem_Output_Index_Reset), .Mem_Input_Index_Reset(Mem_Input_Index_Reset), 
		.L0_Weight_Index_Reset(L0_Weight_Index_Reset), .L0_Input_Index_Reset(L0_Input_Index_Reset), .L0_Output_Index_Reset(L0_Output_Index_Reset),
		.Weight_Loading_Signal(Weight_Loading_Signal), .Output_Loading_Signal(Output_Loading_Signal), .Input_Loading_Signal(Input_Loading_Signal), 
		.Output_Writing_Signal(Output_Writing_Signal),
		.Weight_Loading_From_File(Weight_Loading_From_File), .Output_Loading_From_File(Output_Loading_From_File), .Input_Loading_From_File(Input_Loading_From_File), .Output_Writing_To_File(Output_Writing_To_File),
		.L0_Weight_Status(L0_Weight_Status), .L0_Input_Status(L0_Input_Status), .L0_Output_Status(L0_Output_Status),
		.Computing_Signal(Computing_Signal), .Computing(Computing), .Computation_Step_Counter(state),
		.Mem_Clear(Mem_Clear), .Mem_En_CS(Mem_En_CS), .Mem_En_W(Mem_En_W), .Mem_En_R(Mem_En_R),
		.Mem_Weight_Addr_Read(Mem_Weight_Addr_Read), .Mem_Weight_Addr_Write(Mem_Weight_Addr_Write), 
		.Mem_Output_Addr_Read(Mem_Output_Addr_Read), .Mem_Output_Addr_Write(Mem_Output_Addr_Write),
		.Mem_Input_Addr_Read(Mem_Input_Addr_Read), .Mem_Input_Addr_Write(Mem_Input_Addr_Write),
		.L0_Clear(L0_Clear), .L0_En_CS(L0_En_CS), .L0_En_W(L0_En_W), .L0_En_R(L0_En_R),
		.L0_Weight_Addr_Read(L0_Weight_Addr_Read), .L0_Weight_Addr_Write(L0_Weight_Addr_Write), 
		.L0_Input_Addr_Read(L0_Input_Addr_Read), .L0_Input_Addr_Write(L0_Input_Addr_Write),
		.L0_Output_Addr_Read(L0_Output_Addr_Read), .L0_Output_Addr_Write(L0_Output_Addr_Write),
		.Mem_Weight_Index(Mem_Weight_Index),
		.Initial_Accumulate(Initial_Accumulate));

		MemModule #(.Data_Width_In(Data_Width_In), .Data_Width_Out(Data_Width_Out),
		.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width),
		.Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out), .Nums_SRAM(Nums_SRAM),
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Input_Nums(Input_Nums),
		.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), 
		.Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits), .Total_Computation_Steps(Total_Computation_Steps),
		.Weight_Para_Deg(Weight_Para_Deg), .Output_Para_Deg(Output_Para_Deg), .Input_Para_Deg(Input_Para_Deg),
		.Nums_L0_In(Nums_L0_In), .Nums_L0_Out(Nums_L0_Out), .Nums_L0(Nums_L0), 
		.L0_Weight_Addr_Width(L0_Weight_Addr_Width), .L0_Input_Addr_Width(L0_Input_Addr_Width), .L0_Output_Addr_Width(L0_Output_Addr_Width), 
		.L0_Weight_Nums(L0_Weight_Nums), .L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums))
		memmodule(.clk(clk), .Mem_Reset(Mem_Reset),
    	.Mem_Clear(Mem_Clear), .Mem_CS(Mem_CS), .Mem_En_W(Mem_En_W), .Mem_En_R(Mem_En_R),
  		.L0_Clear(L0_Clear), .L0_CS(L0_CS), .L0_En_W(L0_En_W), .L0_En_R(L0_En_R),
    	.Mem_Weight_Addr_Read(Mem_Weight_Addr_Read), .Mem_Weight_Addr_Write(Mem_Weight_Addr_Write), 
		.Mem_Output_Addr_Read(Mem_Output_Addr_Read), .Mem_Output_Addr_Write(Mem_Output_Addr_Write),
		.Mem_Input_Addr_Read(Mem_Input_Addr_Read), .Mem_Input_Addr_Write(Mem_Input_Addr_Write),
        .Weight_Data_Read(Weight_Data_Read), .Weight_Data_Write(Weight_Data_Write), 
		.Input_Data_Read(Input_Data_Read), .Input_Data_Write(Input_Data_Write), 
		.Output_Data_Read(Output_Data_Read), .Output_Data_Write(Output_Data_Write),
        .L0_Weight_Addr_Read(L0_Weight_Addr_Read), .L0_Weight_Addr_Write(L0_Weight_Addr_Write), 
		.L0_Input_Addr_Read(L0_Input_Addr_Read), .L0_Input_Addr_Write(L0_Input_Addr_Write),
		.L0_Output_Addr_Read(L0_Output_Addr_Read), .L0_Output_Addr_Write(L0_Output_Addr_Write)); 

		PEGroup #(.Data_Width(Data_Width_In), .Para_Deg(Weight_Para_Deg))
		pegroups (.clk(clk), .reset(PE_reset), .Initial_Accumulate(Initial_Accumulate), 
		.data0(Weight_Data_Read), .data1(Input_Data_Read), .result(result), .old_output(Output_Data_Read));

		
endmodule
