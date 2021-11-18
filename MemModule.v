module MemModule
		#(	
			parameter Data_Width_In = 8,
			parameter Data_Width_Out = 2 * Data_Width_In,
			parameter Weight_Addr_Width = 2,
			parameter Output_Addr_Width = 4,
			parameter Input_Addr_Width = 4, 
			parameter Nums_SRAM_In = 2,
			parameter Nums_SRAM_Out = 1,
			parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
			parameter Weight_Nums = 3,
			parameter Output_Nums = 16,
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
			parameter L0_Output_Nums =  1 << L0_Output_Addr_Width)
		(
            clk, Mem_Reset,
            Mem_Clear, Mem_CS, Mem_En_W, Mem_En_R,
            L0_Clear, L0_CS, L0_En_W, L0_En_R,
            Mem_Weight_Addr_Read, Mem_Weight_Addr_Write, Mem_Output_Addr_Read, Mem_Output_Addr_Write, Mem_Input_Addr_Read, Mem_Input_Addr_Write,
            Weight_Data_Read, Weight_Data_Write, Input_Data_Read, Input_Data_Write, Output_Data_Read, Output_Data_Write,
            L0_Weight_Addr_Read, L0_Weight_Addr_Write, L0_Input_Addr_Read, L0_Input_Addr_Write, L0_Output_Addr_Read, L0_Output_Addr_Write
        ); 
				
		input clk, Mem_Reset;

        input [Nums_SRAM - 1:0] Mem_Clear, Mem_CS, Mem_En_W, Mem_En_R;
		input [Weight_Addr_Width - 1:0] Mem_Weight_Addr_Read, Mem_Weight_Addr_Write;
        input [Input_Addr_Width - 1:0] Mem_Input_Addr_Read, Mem_Input_Addr_Write; 
		input [Output_Addr_Width - 1:0] Mem_Output_Addr_Read, Mem_Output_Addr_Write;

        input [Weight_Para_Deg * Data_Width_In - 1:0] Weight_Data_Write;
        input [Input_Para_Deg * Data_Width_In - 1:0] Input_Data_Write;
        input [Input_Para_Deg * Data_Width_Out - 1:0] Output_Data_Write;

        output [Weight_Para_Deg * Data_Width_In - 1:0] Weight_Data_Read;
        output [Input_Para_Deg * Data_Width_In - 1:0] Input_Data_Read;
        output [Input_Para_Deg * Data_Width_Out - 1:0] Output_Data_Read;

		input [Nums_L0 - 1:0] L0_Clear, L0_CS, L0_En_W, L0_En_R;
		input [L0_Weight_Addr_Width - 1:0] L0_Weight_Addr_Read, L0_Weight_Addr_Write;
		input [L0_Input_Addr_Width - 1:0] L0_Input_Addr_Read, L0_Input_Addr_Write;
		input [L0_Output_Addr_Width - 1:0] L0_Output_Addr_Read, L0_Output_Addr_Write;

		wire [Weight_Para_Deg * Data_Width_In - 1:0] Weight_Data_From_Mem_To_L0;
		wire [Input_Para_Deg * Data_Width_In - 1:0] Input_Data_From_Mem_To_L0;
		wire [Output_Para_Deg * Data_Width_Out -1:0] Output_Data_From_Mem_To_L0;

		genvar SRAM_Index;
		genvar offset_Index;

		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(L0_Weight_Addr_Width), .Ram_Depth(L0_Weight_Nums), .Para_Deg(Weight_Para_Deg))
		buffer_weight (.clk(clk), .Mem_Clear(L0_Clear[0]), .Chip_Select(L0_CS[0]), .En_Write(L0_En_W[0]),
		.En_Read(L0_En_R[0]), .Addr_Write(L0_Weight_Addr_Write), 
		.Addr_Read(L0_Weight_Addr_Read), .Write_Data(Weight_Data_From_Mem_To_L0), .Read_Data(Weight_Data_Read));

		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(L0_Input_Addr_Width), .Ram_Depth(L0_Input_Nums), .Para_Deg(Input_Para_Deg))
		buffer_input (.clk(clk), .Mem_Clear(L0_Clear[1]), .Chip_Select(L0_CS[1]), .En_Write(L0_En_W[1]),
		.En_Read(L0_En_R[1]), .Addr_Write(L0_Input_Addr_Write), 
		.Addr_Read(L0_Input_Addr_Read), .Write_Data(Input_Data_From_Mem_To_L0), .Read_Data(Input_Data_Read));

		Dual_SRAM #(.Data_Width(Data_Width_Out), .Addr_Width(L0_Output_Addr_Width), .Ram_Depth(L0_Output_Nums), .Para_Deg(Output_Para_Deg))
		buffer_output (.clk(clk), .Mem_Clear(L0_Clear[2]), .Chip_Select(L0_CS[2]), .En_Write(L0_En_W[2]),
		.En_Read(L0_En_R[2]), .Addr_Write(L0_Output_Addr_Write), 
		.Addr_Read(L0_Output_Addr_Read), .Write_Data(Output_Data_From_Mem_To_L0), .Read_Data(Output_Data_Read));
		
		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(Weight_Addr_Width), .Ram_Depth(L0_Weight_Nums), .Para_Deg(Weight_Para_Deg))
		srams_weight (.clk(clk), .Mem_Clear(Mem_Clear[0]), .Chip_Select(Mem_CS[0]), .En_Write(Mem_En_W[0]),
		.En_Read(Mem_En_R[0]), .Addr_Write(Mem_Weight_Addr_Write), 
		.Addr_Read(Mem_Weight_Addr_Read), .Write_Data(Weight_Data_Write), .Read_Data(Weight_Data_From_Mem_To_L0));

		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(Input_Addr_Width), .Ram_Depth(L0_Input_Nums), .Para_Deg(Input_Para_Deg))
		srams_input (.clk(clk), .Mem_Clear(Mem_Clear[1]), .Chip_Select(Mem_CS[1]), .En_Write(Mem_En_W[1]),
		.En_Read(Mem_En_R[1]), .Addr_Write(Mem_Input_Addr_Write), 
		.Addr_Read(Mem_Input_Addr_Read), .Write_Data(Input_Data_Write), .Read_Data(Input_Data_From_Mem_To_L0));

		Dual_SRAM #(.Data_Width(Data_Width_Out), .Addr_Width(Output_Addr_Width), .Ram_Depth(L0_Output_Nums), .Para_Deg(Output_Para_Deg))
		srams_output (.clk(clk), .Mem_Clear(Mem_Clear[2]), .Chip_Select(Mem_CS[2]), .En_Write(Mem_En_W[2]),
		.En_Read(Mem_En_R[2]), .Addr_Write(Mem_Output_Addr_Write),
		.Addr_Read(Mem_Output_Addr_Read), .Write_Data(Output_Data_Write), .Read_Data(Output_Data_From_Mem_To_L0));

endmodule
