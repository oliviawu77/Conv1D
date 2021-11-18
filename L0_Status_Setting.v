/*
	L0_(Weight/Input/Output)_Status: to record loading status
	2'b00: nothing (default)
	2'b01: loading in progress
	2'b10: loading completely, but computation undone
	2'b11: computation done
*/
module L0_Status_Setting
    #(
		parameter Nums_Pipeline_Stages = 4,
		parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
        parameter Weight_Nums = 4,
        parameter Output_Nums = 8,
		parameter Total_Computation_Steps_in_bits = 6,
		parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail,
		parameter L0_Weight_Nums = 2,
        parameter L0_Input_Nums = 8,
		parameter L0_Output_Nums =  8,        
        parameter L0_Computation_Steps_in_bits = 5,
		parameter L0_Computation_Steps = L0_Weight_Nums * L0_Output_Nums + Pipeline_Tail,        
		parameter Loading_From_Mem_Cycles_Start_Overhead = 100,
		parameter LO_Weight_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Weight_Nums,
		parameter LO_Input_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Input_Nums,
		parameter LO_Output_Loading_From_Mem_Cycles = Loading_From_Mem_Cycles_Start_Overhead + L0_Output_Nums
    )
    (
		clk, Computing_Signal, 
    	Computation_Step_Counter, L0_Computation_Step_Counter,
    	L0_Weight_Loading_Counter, L0_Input_Loading_Counter, L0_Output_Loading_Counter,
    	L0_Weight_Status, L0_Input_Status, L0_Output_Status
	);

		input clk;
		input Computing_Signal;
		input [Total_Computation_Steps_in_bits - 1:0] Computation_Step_Counter;
		input [L0_Computation_Steps_in_bits - 1:0] L0_Computation_Step_Counter;
		input [10:0] L0_Weight_Loading_Counter, L0_Input_Loading_Counter, L0_Output_Loading_Counter;
		output reg [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
		//L0 Status
		always@(posedge clk) begin
			if(Computing_Signal) begin
				L0_Weight_Status <= 2'b01;
			end
			else if(L0_Weight_Status == 2'b01) begin
				if(L0_Weight_Loading_Counter == (LO_Weight_Loading_From_Mem_Cycles - 1)) begin
					L0_Weight_Status <= 2'b10;
				end
				else begin
					L0_Weight_Status <= L0_Weight_Status;
				end
			end
			else if(L0_Weight_Status == 2'b10) begin
				if(L0_Computation_Step_Counter == (L0_Computation_Steps - 1)) begin
					if(Computation_Step_Counter == (Total_Computation_Steps - 1)) begin
						L0_Weight_Status <= 2'b11;
					end
					else begin
						L0_Weight_Status <= 2'b01;
					end
				end
				else begin
					L0_Weight_Status <= L0_Weight_Status;
				end
			end
			else begin
				L0_Weight_Status <= L0_Weight_Status;
			end

			if(Computing_Signal) begin
				L0_Input_Status <= 2'b01;
			end
			else if(L0_Input_Status == 2'b01) begin
				if(L0_Input_Loading_Counter == (LO_Input_Loading_From_Mem_Cycles - 1)) begin
					L0_Input_Status <= 2'b10;
				end
				else begin
					L0_Input_Status <= L0_Input_Status;
				end
			end
			else if(L0_Input_Status == 2'b10) begin
				if(L0_Computation_Step_Counter == (L0_Computation_Steps - 1)) begin
					if(Computation_Step_Counter == (Total_Computation_Steps - 1)) begin
						L0_Input_Status <= 2'b11;
					end
					else begin
						L0_Input_Status <= 2'b01;
					end
				end
				else begin
					L0_Input_Status <= L0_Input_Status;
				end
			end
			else begin
				L0_Input_Status <= L0_Input_Status;
			end

			if(Computing_Signal) begin
				L0_Output_Status <= 2'b01;
			end
			else if(L0_Output_Status == 2'b01) begin
				if(L0_Output_Loading_Counter == (LO_Output_Loading_From_Mem_Cycles - 1)) begin
					L0_Output_Status <= 2'b10;
				end
				else begin
					L0_Output_Status <= L0_Output_Status;
				end
			end
			else if(L0_Output_Status == 2'b10) begin
				if(L0_Computation_Step_Counter == (L0_Computation_Steps - 1)) begin
					if(Computation_Step_Counter == (Total_Computation_Steps - 1)) begin
						L0_Output_Status <= 2'b11;
					end
					else begin
						L0_Output_Status <= 2'b01;
					end
				end
			end
			else begin
				L0_Output_Status <= L0_Output_Status;
			end
		end
endmodule
