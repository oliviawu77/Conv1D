//loading or writing
module Signal_Setting
    #(
		parameter Weight_Addr_Width = 2,
		parameter Output_Addr_Width = 3,
		parameter Input_Addr_Width = 4, 
        parameter Weight_Nums = 4,
        parameter Output_Nums = 8,
        parameter Input_Nums = Output_Nums - Weight_Nums + 1,
		parameter Nums_Pipeline_Stages = 4,
		parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
        parameter Total_Computation_Steps_in_bits = 6,
        parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail
    )
    (clk, 
    Weight_Loading_Signal, Input_Loading_Signal, Output_Loading_Signal,
    Weight_Loading_From_File, Input_Loading_From_File, Output_Loading_From_File,
    Output_Writing_Signal, Output_Writing_To_File,
    Mem_Weight_Index, Mem_Input_Index, Mem_Output_Index, 
    Computation_Step_Counter,
    );

        input clk;

        input Weight_Loading_Signal, Input_Loading_Signal, Output_Loading_Signal;
        output reg Weight_Loading_From_File, Input_Loading_From_File, Output_Loading_From_File;

        input Output_Writing_Signal;
        output reg Output_Writing_To_File;

        input [Weight_Addr_Width:0] Mem_Weight_Index;
        input [Input_Addr_Width:0] Mem_Input_Index;
        input [Output_Addr_Width:0] Mem_Output_Index;
        input [Total_Computation_Steps_in_bits:0] Computation_Step_Counter;


		always@(posedge clk) begin
			if(Weight_Loading_Signal) begin
				Weight_Loading_From_File <= 1;
			end
			else if (Weight_Loading_From_File)  begin
				if (Mem_Weight_Index < Weight_Nums - 1) begin
					Weight_Loading_From_File <= Weight_Loading_From_File;
				end
				else begin
					Weight_Loading_From_File <= 0;
				end
			end
			else begin
				Weight_Loading_From_File <= 0;
			end

			if(Output_Loading_Signal) begin
				Output_Loading_From_File <= 1;
			end
			else if (Output_Loading_From_File)  begin
				if (Mem_Output_Index < Output_Nums - 1) begin
					Output_Loading_From_File <= Output_Loading_From_File;
				end
				else begin
					Output_Loading_From_File <= 0;
				end
			end
			else begin
				Output_Loading_From_File <= 0;
			end

			if(Input_Loading_Signal) begin
				Input_Loading_From_File <= 1;
			end
			else if (Input_Loading_From_File)  begin
				if (Mem_Input_Index < Input_Nums - 1) begin
					Input_Loading_From_File <= Input_Loading_From_File;
				end
				else begin
					Input_Loading_From_File <= 0;
				end
			end
			else begin
				Input_Loading_From_File <= 0;
			end

			if (Output_Writing_Signal) begin
				Output_Writing_To_File <= 1;	
			end
			else if (Output_Writing_To_File) begin
				if(Mem_Output_Index < Output_Nums + 1) begin
					Output_Writing_To_File <= Output_Writing_To_File;
				end
				else begin
					Output_Writing_To_File <= 0;
				end
			end
			else begin
				Output_Writing_To_File <= Output_Writing_To_File;
			end
		end
endmodule
