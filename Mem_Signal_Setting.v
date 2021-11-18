module Mem_Signal_Setting
	#(
		parameter Weight_Addr_Width = 2,
		parameter Output_Addr_Width = 3,
		parameter Input_Addr_Width = 4,
		parameter Weight_Nums = 4,
		parameter Output_Nums = 8, 
		parameter Nums_SRAM_In = 2,
		parameter Nums_SRAM_Out = 1,
		parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
		parameter L0_Weight_Addr_Width = 1,
		parameter L0_Input_Addr_Width = 3,
		parameter L0_Output_Addr_Width = 3,
		parameter Nums_L0_In = 2,
		parameter Nums_L0_Out = 1,
		parameter Nums_L0 = Nums_L0_In + Nums_L0_Out,		
		parameter Nums_Pipeline_Stages = 4,
		parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,		
		parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail
	)
	(	
		clk, 
		Weight_Loading_From_File, Input_Loading_From_File, Output_Loading_From_File, Output_Writing_To_File,
		L0_Data_Is_Ready,
		Mem_Weight_Index, Mem_Input_Index, Mem_Output_Index,
		L0_Weight_Index, L0_Input_Index, L0_Output_Index,
		L0_Weight_Status, L0_Input_Status, L0_Output_Status,
		Mem_En_CS, Mem_En_W, Mem_En_R,
		Mem_Weight_Addr_Read, Mem_Weight_Addr_Write,
		Mem_Output_Addr_Read, Mem_Output_Addr_Write,
		Mem_Input_Addr_Read, Mem_Input_Addr_Write,
		L0_En_CS, L0_En_W, L0_En_R,
		L0_Weight_Addr_Read, L0_Weight_Addr_Write,
		L0_Input_Addr_Read, L0_Input_Addr_Write,
		L0_Output_Addr_Read, L0_Output_Addr_Write
	);

		input clk;
		input Weight_Loading_From_File, Input_Loading_From_File, Output_Loading_From_File;
		input Output_Writing_To_File;
		input L0_Data_Is_Ready;
		//Mem index
		input [Weight_Addr_Width:0] Mem_Weight_Index;
		input [Output_Addr_Width:0] Mem_Output_Index;
		input [Input_Addr_Width:0] Mem_Input_Index;

		//L0 Buffer index
		input [L0_Weight_Addr_Width:0] L0_Weight_Index;
		input [L0_Input_Addr_Width:0] L0_Input_Index;
		input [L0_Output_Addr_Width:0] L0_Output_Index;
		input [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;

		//Mem signals
		output reg [Nums_SRAM - 1:0] Mem_En_CS, Mem_En_W, Mem_En_R;
		output reg [Weight_Addr_Width - 1:0] Mem_Weight_Addr_Read, Mem_Weight_Addr_Write;
		output reg [Output_Addr_Width - 1:0] Mem_Output_Addr_Read, Mem_Output_Addr_Write;
		output reg [Input_Addr_Width - 1:0] Mem_Input_Addr_Read, Mem_Input_Addr_Write;

		//L0 Buffer signals
		output reg [Nums_L0 - 1:0] L0_En_CS, L0_En_W, L0_En_R;
		output reg [L0_Weight_Addr_Width - 1:0] L0_Weight_Addr_Read, L0_Weight_Addr_Write;
		output reg [L0_Input_Addr_Width - 1:0] L0_Input_Addr_Read, L0_Input_Addr_Write;
		output reg [L0_Output_Addr_Width - 1:0] L0_Output_Addr_Read, L0_Output_Addr_Write;
		
		always @(posedge clk) begin
			//set Mem Signals
			case(L0_Weight_Status)
				2'b00: begin
					if(Weight_Loading_From_File) begin
						Mem_En_CS[0] <= 1;
						Mem_En_R[0] <= 1;
						Mem_En_W[0] <= 1;		
						Mem_Weight_Addr_Write <= Mem_Weight_Index;
						Mem_Weight_Addr_Read <= Mem_Weight_Index - 2;						
					end
					else begin
						Mem_En_CS[0] <= 0;
						Mem_En_R[0] <= 0;
						Mem_En_W[0] <= 0;	
						Mem_Weight_Addr_Write <= 0;
						Mem_Weight_Addr_Read <= 0;									
					end
				end
				2'b01: begin
					Mem_En_CS[0] <= 1;
					Mem_En_R[0] <= 1;
					Mem_En_W[0] <= 0;	
					Mem_Weight_Addr_Write <= 0;
					Mem_Weight_Addr_Read <= Mem_Weight_Index - 2;						
				end
				default: begin
					Mem_En_CS[0] <= 0;
					Mem_En_R[0] <= 0;
					Mem_En_W[0] <= 0;	
					Mem_Weight_Addr_Write <= 0;
					Mem_Weight_Addr_Read <= 0;									
				end
			endcase

			case(L0_Input_Status) 
				2'b00: begin
					if(Input_Loading_From_File) begin
						Mem_En_CS[1] <= 1;
						Mem_En_R[1] <= 1;
						Mem_En_W[1] <= 1;		
						Mem_Input_Addr_Write <= Mem_Input_Index;
						Mem_Input_Addr_Read <= Mem_Input_Index - 2;
					end
					else begin
						Mem_En_CS[1] <= 0;
						Mem_En_R[1] <= 0;
						Mem_En_W[1] <= 0;			
						Mem_Input_Addr_Write <= 0;
						Mem_Input_Addr_Read <= 0;						
					end
				end
				2'b01: begin
					Mem_En_CS[1] <= 1;
					Mem_En_R[1] <= 1;
					Mem_En_W[1] <= 0;			
					Mem_Input_Addr_Write <= 0;
					Mem_Input_Addr_Read <= 0;							
				end
				default: begin
					Mem_En_CS[1] <= 0;
					Mem_En_R[1] <= 0;
					Mem_En_W[1] <= 0;			
					Mem_Input_Addr_Write <= 0;
					Mem_Input_Addr_Read <= 0;					
				end	
			endcase

			case (L0_Output_Status)
				2'b00: begin
					if(Output_Loading_From_File) begin
						Mem_En_CS[2] <= 1;
						Mem_En_R[2] <= 1;
						Mem_En_W[2] <= 1;
						Mem_Output_Addr_Write <= Mem_Output_Index;
						Mem_Output_Addr_Read <= Mem_Output_Index - 2;
					end
					else if (Output_Writing_To_File) begin
						Mem_En_CS[2] <= 1;
						Mem_En_R[2] <= 1;
						Mem_En_W[2] <= 0;
						Mem_Output_Addr_Read <= Mem_Output_Index;
						Mem_Output_Addr_Write <= 0;
					end
					else begin
						Mem_En_CS[2] <= 0;
						Mem_En_R[2] <= 0;
						Mem_En_W[2] <= 0;
						Mem_Output_Addr_Read <= 0;
						Mem_Output_Addr_Write <= 0;						
					end					
				end
				2'b01: begin
					Mem_En_CS[2] <= 1;
					Mem_En_R[2] <= 1;
					Mem_En_W[2] <= 0;
					Mem_Output_Addr_Read <= Mem_Output_Index;
					Mem_Output_Addr_Write <= 0;						
					
				end
				default: begin
					Mem_En_CS[2] <= 1;
					Mem_En_R[2] <= 1;
					Mem_En_W[2] <= 0;
					Mem_Output_Addr_Read <= Mem_Output_Index;
					Mem_Output_Addr_Write <= 0;	
				end
			endcase

			//set Buf Signals
			if (L0_Weight_Status == 2'b01) begin
				L0_En_CS[0] <= 1;
				L0_En_R[0] <= 0;
				L0_En_W[0] <= 1;
				L0_Weight_Addr_Read <= 0;
				L0_Weight_Addr_Write <= L0_Weight_Index;
			end
			else if(L0_Data_Is_Ready) begin
				L0_En_CS[0] <= 1;
				L0_En_R[0] <= 1;
				L0_En_W[0] <= 0;
				L0_Weight_Addr_Read <= L0_Weight_Index;
				L0_Weight_Addr_Write <= 0;				
			end
			else begin
				L0_En_CS[0] <= 0;
				L0_En_R[0] <= 0;
				L0_En_W[0] <= 0;
				L0_Weight_Addr_Read <= 0;
				L0_Weight_Addr_Write <= 0;					
			end

			if(L0_Input_Status == 2'b01) begin
				L0_En_CS[1] <= 1;
				L0_En_R[1] <= 0;
				L0_En_W[1] <= 1;
				L0_Input_Addr_Read <= 0;
				L0_Input_Addr_Write <= L0_Input_Index;				
			end
			else if(L0_Data_Is_Ready) begin
				L0_En_CS[1] <= 1;
				L0_En_R[1] <= 1;
				L0_En_W[1] <= 0;
				L0_Input_Addr_Read <= L0_Input_Index;
				L0_Input_Addr_Write <= 0;					
			end
			else begin
				L0_En_CS[1] <= 0;
				L0_En_R[1] <= 0;
				L0_En_W[1] <= 0;
				L0_Input_Addr_Read <= 0;
				L0_Input_Addr_Write <= 0;					
			end

			if(L0_Output_Status == 2'b01) begin
				L0_En_CS[2] <= 1;
				L0_En_R[2] <= 0;
				L0_En_W[2] <= 1;
				L0_Output_Addr_Read <= 0;
				L0_Output_Addr_Write <= L0_Output_Index;					
			end
			else if(L0_Data_Is_Ready) begin
				L0_En_CS[2] <= 1;
				L0_En_R[2] <= 1;
				L0_En_W[2] <= 0;
				L0_Output_Addr_Read <= L0_Output_Index;
				L0_Output_Addr_Write <= 0;				
			end
			else begin
				L0_En_CS[2] <= 0;
				L0_En_R[2] <= 0;
				L0_En_W[2] <= 0;
				L0_Output_Addr_Read <= 0;
				L0_Output_Addr_Write <= 0;				
			end
		end		
endmodule
