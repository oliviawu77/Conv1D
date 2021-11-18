/*
	(Weight_Output/Input)_Loading_Counter: Assume loading data from mem to L0 buffer need 100 cycles
	Output_Writing_To_Mem_Counter: Assume Writing from L0 buffer to Mem need 100 cycles
	*Notes: Maximum of Counter is 2048, It can be adjusted as needed.
*/
module L0_Loading_Cycle_Counter
    #(	
        parameter Nums_Pipeline_Stages = 4,
        parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
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
    (	clk,
    	L0_Weight_Status, L0_Input_Status, L0_Output_Status,
    	Weight_Loading_From_Mem_Counter, Input_Loading_From_Mem_Counter, Output_Loading_From_Mem_Counter
	);
        input clk;
        input [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
        output reg [10:0] Weight_Loading_From_Mem_Counter = 0, Input_Loading_From_Mem_Counter = 0, Output_Loading_From_Mem_Counter = 0;

		always@(posedge clk) begin
			if(L0_Weight_Status == 2'b01) begin
				if(Weight_Loading_From_Mem_Counter < (LO_Weight_Loading_From_Mem_Cycles - 1)) begin
					Weight_Loading_From_Mem_Counter <= Weight_Loading_From_Mem_Counter + 1;
				end
				else begin
					Weight_Loading_From_Mem_Counter <= Weight_Loading_From_Mem_Counter;
				end				
			end
			else begin
				Weight_Loading_From_Mem_Counter <= Weight_Loading_From_Mem_Counter;
			end

			if(L0_Input_Status == 2'b01) begin
				if(Input_Loading_From_Mem_Counter < (LO_Input_Loading_From_Mem_Cycles - 1)) begin
					Input_Loading_From_Mem_Counter <= Input_Loading_From_Mem_Counter + 1;
				end
				else begin
					Input_Loading_From_Mem_Counter <= Input_Loading_From_Mem_Counter;
				end
			end
			else begin
				Input_Loading_From_Mem_Counter <= Input_Loading_From_Mem_Counter;
			end

			if(L0_Output_Status == 2'b01) begin
				if(Output_Loading_From_Mem_Counter < (LO_Output_Loading_From_Mem_Cycles - 1)) begin
					Output_Loading_From_Mem_Counter <= Output_Loading_From_Mem_Counter + 1;
				end
				else begin
					Output_Loading_From_Mem_Counter <= Output_Loading_From_Mem_Counter;
				end
			end
			else begin
				Output_Loading_From_Mem_Counter <= Output_Loading_From_Mem_Counter;
			end 
		end
endmodule
