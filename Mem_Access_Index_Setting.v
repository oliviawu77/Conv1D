module Mem_Access_Index_Setting
    #(
		parameter Weight_Addr_Width = 2,
		parameter Output_Addr_Width = 3,
		parameter Input_Addr_Width = 4,
        parameter Weight_Nums = 4,
        parameter Output_Nums = 8,
        parameter Input_Nums = Output_Nums - Weight_Nums + 1,
		parameter L0_Weight_Addr_Width = 1,
		parameter L0_Input_Addr_Width = 3,
		parameter L0_Output_Addr_Width = 3,
 		parameter L0_Weight_Nums = 2,
		parameter L0_Input_Nums = 8,
		parameter L0_Output_Nums =  8,       
        parameter Weight_Para_Deg = 1
    )
    (clk, 
    Mem_Weight_Index_Reset, Mem_Input_Index_Reset, Mem_Output_Index_Reset,
    L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset,
	L0_Weight_Status, L0_Input_Status, L0_Output_Status, L0_Data_Is_Ready,
    Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File,
    Mem_Weight_Index, Mem_Input_Index, Mem_Output_Index,
    L0_Weight_Index, L0_Input_Index, L0_Output_Index);
    
    input clk;
    input Mem_Weight_Index_Reset, Mem_Input_Index_Reset, Mem_Output_Index_Reset;
    input L0_Weight_Index_Reset, L0_Input_Index_Reset, L0_Output_Index_Reset;
	input [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
	input L0_Data_Is_Ready;
    input Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File;
    output reg [Weight_Addr_Width:0] Mem_Weight_Index;
    output reg [Output_Addr_Width:0] Mem_Input_Index;
    output reg [Input_Addr_Width:0] Mem_Output_Index;
    output reg [L0_Weight_Addr_Width:0] L0_Weight_Index;
    output reg [L0_Input_Addr_Width:0] L0_Input_Index;
    output reg [L0_Output_Addr_Width:0] L0_Output_Index;

		always@(posedge clk) begin
			//Memory weight
			if (Mem_Weight_Index_Reset) begin
				Mem_Weight_Index <= 0;
			end
			else if(Weight_Loading_From_File) begin
				if (Mem_Weight_Index < Weight_Nums - 1) begin
					//Mem_Weight_Index <= Mem_Weight_Index + Para_Deg;
					Mem_Weight_Index <= Mem_Weight_Index + 1; 
				end
				else begin
					Mem_Weight_Index <= Mem_Weight_Index;
				end
			end
			else if (L0_Weight_Status == 2'b01) begin
				if (Mem_Weight_Index < Weight_Nums - 1) begin
					if(L0_Weight_Index == L0_Weight_Nums - 1) begin
						//Mem_Weight_Index <= Mem_Weight_Index + Para_Deg;
						Mem_Weight_Index <= Mem_Weight_Index + 1; 
					end
					else begin
						Mem_Weight_Index <= Mem_Weight_Index;
					end 
				end
				else begin
					Mem_Weight_Index <= Mem_Weight_Index;
				end				
			end
			else begin
				Mem_Weight_Index <= Mem_Weight_Index;
			end

			//Memory input
			if (Mem_Input_Index_Reset) begin
				Mem_Input_Index <= 0;
			end
			else if (Input_Loading_From_File) begin
				if (Mem_Input_Index < Input_Nums) begin
					//Mem_Input_Index <= Mem_Input_Index + Para_Deg;
					Mem_Input_Index <= Mem_Input_Index + 1;
				end
				else begin
					Mem_Input_Index <= 0;
				end
			end
			else if(L0_Input_Status == 2'b01) begin
				if(Mem_Weight_Index == Weight_Nums - 1) begin
					//Mem_Input_Index <= (Mem_Output_Index + Para_Deg);
					Mem_Input_Index <= (Mem_Output_Index + 1);
				end
				else begin
					//Mem_Input_Index <= Mem_Output_Index + (Mem_Weight_Index + Para_Deg);
					Mem_Input_Index <= Mem_Output_Index + (Mem_Weight_Index + 1);
				end
			end
			else begin
				Mem_Input_Index <= Mem_Input_Index;
			end

			//Memory output
			if (Mem_Output_Index_Reset) begin
				Mem_Output_Index <= 0;
			end
			else if (Output_Loading_From_File || Output_Writing_To_File) begin
				if (Mem_Output_Index < Output_Nums) begin
					//Mem_Output_Index <= Mem_Output_Index + Para_Deg;
					Mem_Output_Index <= Mem_Output_Index + 1;
				end
				else begin
					Mem_Output_Index <= Mem_Output_Index;
				end
			end
			else if (L0_Output_Status == 2'b01) begin
				if (Mem_Weight_Index == Weight_Nums - 1) begin
					// Mem_Output_Index <= Mem_Output_Index + Para_Deg;
					Mem_Output_Index <= Mem_Output_Index + 1;
				end
				else begin
					Mem_Output_Index <= Mem_Output_Index;
				end
			end
			else begin
				Mem_Output_Index <= Mem_Output_Index;
			end


			// L0 Weight
			if(L0_Weight_Index_Reset) begin
				L0_Weight_Index <= 0;
			end
			else if(L0_Data_Is_Ready) begin
				if(L0_Weight_Index < (L0_Weight_Nums - 1)) begin
					L0_Weight_Index <= L0_Weight_Index + 1;
				end
				else begin
					L0_Weight_Index <= 0;
				end
			end
			else begin
				L0_Weight_Index <= L0_Weight_Index;
			end

			// L0 Input
			if(L0_Input_Index_Reset) begin
				L0_Input_Index <= 0;
			end
			else if(L0_Data_Is_Ready) begin
				if(L0_Weight_Index < (L0_Weight_Nums - 1)) begin
					L0_Input_Index <= L0_Output_Index + (L0_Weight_Index + 1);
				end
				else begin
					L0_Input_Index <= (L0_Output_Index + 1);
				end
			end
			else begin
				L0_Input_Index <= L0_Input_Index;
			end
			
			// L0 Output
			if(L0_Output_Index_Reset) begin
				L0_Output_Index <= 0;
			end
			else if(L0_Data_Is_Ready) begin
				if(L0_Weight_Index < (L0_Weight_Nums - 1)) begin
					L0_Output_Index <= L0_Output_Index;
				end
				else begin
					L0_Output_Index <= L0_Output_Index + 1;
				end
			end
			else begin
				L0_Output_Index <= L0_Output_Index;
			end
		
		end
endmodule
