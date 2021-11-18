module MEMController
		#(	
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
			parameter File_Para_Deg = 1,
			parameter Weight_Para_Deg = 1,
			parameter Output_Para_Deg = 1,
			parameter Input_Para_Deg = Weight_Para_Deg * Output_Para_Deg,
			parameter Nums_L0_In = 2,
			parameter Nums_L0_Out = 1,
			parameter Nums_L0 = Nums_L0_In + Nums_L0_Out,
			parameter L0_Weight_Addr_Width = 1,
			parameter L0_Input_Addr_Width = 3,
			parameter L0_Output_Addr_Width = 3,
			parameter L0_Weight_Nums = 2,
			parameter L0_Input_Nums = 8,
			parameter L0_Output_Nums =  8,
			parameter Loading_From_Mem_Cycles_Start_Overhead = 100,
			parameter LO_Weight_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Weight_Nums,
			parameter LO_Input_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Input_Nums,
			parameter LO_Output_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Output_Nums,
			parameter L0_Computation_Steps_in_bits = 5,
			parameter L0_Computation_Steps = L0_Weight_Nums * L0_Output_Nums + Pipeline_Tail
		)
		(clk, Mem_Reset, L0_Reset, Comp_Reset, 
		Mem_Weight_Index_Reset, Mem_Output_Index_Reset, Mem_Input_Index_Reset, 
		L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset,
		Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal,
		Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File,
		L0_Weight_Status, L0_Input_Status, L0_Output_Status,
		Computing_Signal, Computing, Computation_Step_Counter,
		Mem_Clear, Mem_En_CS, Mem_En_W, Mem_En_R,
		Mem_Weight_Addr_Read, Mem_Weight_Addr_Write, 
		Mem_Output_Addr_Read, Mem_Output_Addr_Write,
		Mem_Input_Addr_Read, Mem_Input_Addr_Write,
		L0_Clear, L0_En_CS, L0_En_W, L0_En_R,
		L0_Weight_Addr_Read, L0_Weight_Addr_Write, 
		L0_Input_Addr_Read, L0_Input_Addr_Write,
		L0_Output_Addr_Read, L0_Output_Addr_Write,
		Mem_Weight_Index,
		Initial_Accumulate);

		input clk, Mem_Reset, L0_Reset, Comp_Reset;
		input Mem_Weight_Index_Reset, Mem_Output_Index_Reset, Mem_Input_Index_Reset;
		input L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset;
		
		//Loading Data from File
		input Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal;
		output Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File;

		output [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
		
		wire [10:0] L0_Weight_Loading_Counter, L0_Output_Loading_Counter, L0_Input_Loading_Counter; 

		//Computation
		input Computing_Signal;
		output reg Computing;
		output [Total_Computation_Steps_in_bits - 1:0] Computation_Step_Counter;

		wire [L0_Computation_Steps_in_bits - 1:0] L0_Computation_Step_Counter;

		//Mem signals
		output [Nums_SRAM - 1:0] Mem_Clear, Mem_En_CS, Mem_En_W, Mem_En_R;
		output [Weight_Addr_Width - 1:0] Mem_Weight_Addr_Read, Mem_Weight_Addr_Write;
		output [Output_Addr_Width - 1:0] Mem_Output_Addr_Read, Mem_Output_Addr_Write;
		output [Input_Addr_Width - 1:0] Mem_Input_Addr_Read, Mem_Input_Addr_Write;

		//L0 Buffer signals
		output [Nums_L0 - 1:0] L0_Clear, L0_En_CS, L0_En_W, L0_En_R;
		output [L0_Weight_Addr_Width - 1:0] L0_Weight_Addr_Read, L0_Weight_Addr_Write;
		output [L0_Input_Addr_Width - 1:0] L0_Input_Addr_Read, L0_Input_Addr_Write;
		output [L0_Output_Addr_Width - 1:0] L0_Output_Addr_Read, L0_Output_Addr_Write;

		//Mem index
		output [Weight_Addr_Width:0] Mem_Weight_Index; //for debug
		wire [Output_Addr_Width:0] Mem_Output_Index;
		wire [Input_Addr_Width:0] Mem_Input_Index;

		//L0 Buffer index
		wire [L0_Weight_Addr_Width:0] L0_Weight_Index;
		wire [L0_Input_Addr_Width:0] L0_Input_Index;
		wire [L0_Output_Addr_Width:0] L0_Output_Index;
		
		//to restart accumulating the register
		output reg Initial_Accumulate;

		integer Ram_Index;
		integer Addr_Index;

		reg L0_Data_Is_Ready;
		always@(posedge clk) begin
			if(L0_Weight_Status == 2'b10 && L0_Input_Status == 2'b10 && L0_Output_Status == 2'b10) begin
				L0_Data_Is_Ready <= 1;
			end
			else begin
				L0_Data_Is_Ready <= 0;
			end
			if((L0_Weight_Status == 2'b01 && L0_Input_Status == 2'b01 && L0_Output_Status == 2'b01) 
				|| (L0_Weight_Status == 2'b10 && L0_Input_Status == 2'b10 && L0_Output_Status == 2'b10)) begin
				Computing <= 1;
			end
			else begin
				Computing <= 0;
			end
            if(L0_Data_Is_Ready) begin
                if(Mem_Weight_Index == Weight_Nums - 1) begin
                    Initial_Accumulate <= 1;
                end
                else begin
                    Initial_Accumulate <= 0;
                end
            end	
		end


		Mem_Reset #(.Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out), .Nums_SRAM(Nums_SRAM),
		.Nums_L0_In(Nums_L0_In), .Nums_L0_Out(Nums_L0_Out), .Nums_L0(Nums_L0))
		mem_reset (.clk(clk), .Mem_Reset(Mem_Reset), .L0_Reset(L0_Reset), .Mem_Clear(Mem_Clear), .L0_Clear(L0_Clear));		

		L0_Status_Setting #(.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), 
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums),
		.Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits), .Total_Computation_Steps(Total_Computation_Steps), 
		.L0_Weight_Nums(L0_Weight_Nums), .L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums), 
		.L0_Computation_Steps_in_bits(L0_Computation_Steps_in_bits), .L0_Computation_Steps(L0_Computation_Steps), 
		.Loading_From_Mem_Cycles_Start_Overhead(Loading_From_Mem_Cycles_Start_Overhead),
		.LO_Weight_Loading_From_Mem_Cycles(LO_Weight_Loading_From_Mem_Cycles), 
		.LO_Input_Loading_From_Mem_Cycles(LO_Input_Loading_From_Mem_Cycles),
		.LO_Output_Loading_From_Mem_Cycles(LO_Output_Loading_From_Mem_Cycles))
		l0_status_setting (.clk(clk), .Computing_Signal(Computing_Signal), 
		.Computation_Step_Counter(Computation_Step_Counter), .L0_Computation_Step_Counter(L0_Computation_Step_Counter),
		.L0_Weight_Loading_Counter(L0_Weight_Loading_Counter), .L0_Input_Loading_Counter(L0_Input_Loading_Counter), .L0_Output_Loading_Counter(L0_Output_Loading_Counter),
		.L0_Weight_Status(L0_Weight_Status), .L0_Input_Status(L0_Input_Status), .L0_Output_Status(L0_Output_Status));

		L0_Loading_Cycle_Counter #(.L0_Weight_Nums(L0_Weight_Nums), .L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums),
		.Loading_From_Mem_Cycles_Start_Overhead(Loading_From_Mem_Cycles_Start_Overhead),
		.LO_Weight_Loading_From_Mem_Cycles(LO_Weight_Loading_From_Mem_Cycles), 
		.LO_Input_Loading_From_Mem_Cycles(LO_Input_Loading_From_Mem_Cycles),
		.LO_Output_Loading_From_Mem_Cycles(LO_Output_Loading_From_Mem_Cycles), 
		.L0_Computation_Steps_in_bits(L0_Computation_Steps_in_bits),
		.L0_Computation_Steps(L0_Computation_Steps))
		L0_loading_cycle_counter (.clk(clk),
		.L0_Weight_Status(L0_Weight_Status), 
		.L0_Input_Status(L0_Input_Status), 
		.L0_Output_Status(L0_Output_Status),
		.Weight_Loading_From_Mem_Counter(L0_Weight_Loading_Counter), 
		.Input_Loading_From_Mem_Counter(L0_Input_Loading_Counter), 
		.Output_Loading_From_Mem_Counter(L0_Output_Loading_Counter));

		Signal_Setting #(.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width),
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Input_Nums(Input_Nums), 
		.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), .Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits),
		.Total_Computation_Steps(Total_Computation_Steps))
		signal_setting (.clk(clk), 
		.Weight_Loading_Signal(Weight_Loading_Signal), .Input_Loading_Signal(Input_Loading_Signal), .Output_Loading_Signal(Output_Loading_Signal),
		.Weight_Loading_From_File(Weight_Loading_From_File), .Input_Loading_From_File(Input_Loading_From_File), .Output_Loading_From_File(Output_Loading_From_File),
		.Output_Writing_Signal(Output_Writing_Signal), .Output_Writing_To_File(Output_Writing_To_File),
		.Mem_Weight_Index(Mem_Weight_Index), .Mem_Input_Index(Mem_Input_Index), .Mem_Output_Index(Mem_Output_Index), 
		.Computation_Step_Counter(Computation_Step_Counter));

		Computation_Steps_Counter #(.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), 
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Input_Nums(Input_Nums), 
		.Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits), .Total_Computation_Steps(Total_Computation_Steps), 
		.L0_Weight_Nums(L0_Weight_Nums), .L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums), 
		.L0_Computation_Steps_in_bits(L0_Computation_Steps_in_bits), .L0_Computation_Steps(L0_Computation_Steps))
		computation_steps_counter (.clk(clk), .Comp_Reset(Comp_Reset), .Computing(Computing), 
		.L0_Weight_Status(L0_Weight_Status), .L0_Input_Status(L0_Input_Status), .L0_Output_Status(L0_Output_Status), .L0_Data_Is_Ready(L0_Data_Is_Ready),
		.Computation_Step_Counter(Computation_Step_Counter), .L0_Computation_Step_Counter(L0_Computation_Step_Counter));

		Mem_Access_Index_Setting #(.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width), 
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Input_Nums(Input_Nums), .L0_Weight_Addr_Width(L0_Weight_Addr_Width),
		.L0_Input_Addr_Width(L0_Input_Addr_Width), .L0_Output_Addr_Width(L0_Output_Addr_Width), .L0_Weight_Nums(L0_Weight_Nums),
		.L0_Input_Nums(L0_Input_Nums), .L0_Output_Nums(L0_Output_Nums), .Weight_Para_Deg(Weight_Para_Deg))
		Mem_Access_Index_Setting (.clk(clk),
		.Mem_Weight_Index_Reset(Mem_Weight_Index_Reset), .Mem_Input_Index_Reset(Mem_Input_Index_Reset), .Mem_Output_Index_Reset(Mem_Output_Index_Reset),
		.L0_Weight_Index_Reset(L0_Weight_Index_Reset), .L0_Input_Index_Reset(L0_Input_Index_Reset), .L0_Output_Index_Reset(L0_Output_Index_Reset),
		.L0_Weight_Status(L0_Weight_Status), .L0_Input_Status(L0_Input_Status), .L0_Output_Status(L0_Output_Status), .L0_Data_Is_Ready(L0_Data_Is_Ready),
		.Weight_Loading_From_File(Weight_Loading_From_File), .Output_Loading_From_File(Output_Loading_From_File), .Input_Loading_From_File(Input_Loading_From_File), 
		.Output_Writing_To_File(Output_Writing_To_File),
		.Mem_Weight_Index(Mem_Weight_Index), .Mem_Input_Index(Mem_Input_Index), .Mem_Output_Index(Mem_Output_Index),
		.L0_Weight_Index(L0_Weight_Index), .L0_Input_Index(L0_Input_Index), .L0_Output_Index(L0_Output_Index));

		Mem_Signal_Setting #(.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width),
		.Weight_Nums(Weight_Nums), .Output_Nums(Output_Nums), .Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out),
		.Nums_SRAM(Nums_SRAM), .L0_Weight_Addr_Width(L0_Weight_Addr_Width), .L0_Input_Addr_Width(L0_Input_Addr_Width),
		.L0_Output_Addr_Width(L0_Output_Addr_Width), .Nums_L0_In(Nums_L0_In), .Nums_L0_Out(Nums_L0_Out), .Nums_L0(Nums_L0),
		.Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), .Total_Computation_Steps(Total_Computation_Steps))
		mem_signal_setting(.clk(clk), 
		.Weight_Loading_From_File(Weight_Loading_From_File), .Input_Loading_From_File(Input_Loading_From_File), 
		.Output_Loading_From_File(Output_Loading_From_File), .Output_Writing_To_File(Output_Writing_To_File),
		.L0_Data_Is_Ready(L0_Data_Is_Ready),
		.L0_Weight_Status(L0_Weight_Status), .L0_Input_Status(L0_Input_Status), .L0_Output_Status(L0_Output_Status),
		.Mem_Weight_Index(Mem_Weight_Index), .Mem_Input_Index(Mem_Input_Index), .Mem_Output_Index(Mem_Output_Index),
		.L0_Weight_Index(L0_Weight_Index), .L0_Input_Index(L0_Input_Index), .L0_Output_Index(L0_Output_Index),
		.Mem_En_CS(Mem_En_CS), .Mem_En_W(Mem_En_W), .Mem_En_R(Mem_En_R),
		.Mem_Weight_Addr_Read(Mem_Weight_Addr_Read), .Mem_Weight_Addr_Write(Mem_Weight_Addr_Write),
		.Mem_Output_Addr_Read(Mem_Output_Addr_Read), .Mem_Output_Addr_Write(Mem_Output_Addr_Write),
		.Mem_Input_Addr_Read(Mem_Input_Addr_Read), .Mem_Input_Addr_Write(Mem_Input_Addr_Write),
		.L0_En_CS(L0_En_CS), .L0_En_W(L0_En_W), .L0_En_R(L0_En_R),
		.L0_Weight_Addr_Read(L0_Weight_Addr_Read), .L0_Weight_Addr_Write(L0_Weight_Addr_Write),
		.L0_Input_Addr_Read(L0_Input_Addr_Read), .L0_Input_Addr_Write(L0_Input_Addr_Write),
		.L0_Output_Addr_Read(L0_Output_Addr_Read), .L0_Output_Addr_Write(L0_Output_Addr_Write));
		
endmodule