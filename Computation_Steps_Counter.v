module Computation_Steps_Counter
	#(
		parameter Nums_Pipeline_Stages = 4,
		parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
		parameter Weight_Nums = 4,
		parameter Output_Nums = 8,
		parameter Input_Nums = Output_Nums - Weight_Nums + 1,
		parameter Total_Computation_Steps_in_bits = 6,
		parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail,
		parameter L0_Weight_Nums = 2,
		parameter L0_Input_Nums = 8,
		parameter L0_Output_Nums =  8,
		parameter L0_Computation_Steps_in_bits = 5,
		parameter L0_Computation_Steps = L0_Weight_Nums * L0_Output_Nums + Pipeline_Tail
	)
	(clk, Comp_Reset, Computing,
	L0_Weight_Status, L0_Input_Status, L0_Output_Status, L0_Data_Is_Ready,
	Computation_Step_Counter, L0_Computation_Step_Counter);
	
	input clk, Comp_Reset, Computing;
	input [1:0] L0_Weight_Status, L0_Input_Status, L0_Output_Status;
	input L0_Data_Is_Ready;

	output reg [Total_Computation_Steps_in_bits:0] Computation_Step_Counter;
	output reg [L0_Computation_Steps_in_bits:0] L0_Computation_Step_Counter;
		
		always@(posedge clk) begin
			if(Comp_Reset) begin
				Computation_Step_Counter <= 0;
			end
			else if(Computing) begin
				if (Computation_Step_Counter < Total_Computation_Steps) begin
					//Computation_Step_Counter <= Computation_Step_Counter + Para_Deg;
					Computation_Step_Counter <= Computation_Step_Counter + 1;
				end
				else begin
					Computation_Step_Counter <= Computation_Step_Counter;
				end
			end
			else begin
				Computation_Step_Counter <= 0;
			end

			if(Comp_Reset) begin
				L0_Computation_Step_Counter <= 0;
			end
			else if(L0_Data_Is_Ready) begin
				if(L0_Computation_Step_Counter < L0_Computation_Steps - 1) begin
					L0_Computation_Step_Counter <= L0_Computation_Step_Counter + 1;
				end
				else begin
					L0_Computation_Step_Counter <= L0_Computation_Step_Counter;
				end
			end
			else begin
				L0_Computation_Step_Counter <= 0;
			end
		end
endmodule
