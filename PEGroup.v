module PEGroup
			#(
			parameter Data_Width = 8,
			parameter Para_Deg = 4)
			(clk, reset, Initial_Accumulate, data0, data1, result, old_output);
			input clk, reset, Initial_Accumulate;
			input [Para_Deg * Data_Width - 1:0] data0, data1;
			input [Para_Deg * Data_Width * 2 - 1:0] old_output;
			output [Para_Deg * Data_Width * 2 - 1:0] result;
			
			
			wire [Data_Width * 2 - 1:0] mul_result [0:Para_Deg-1];
			
			reg [Data_Width * 2 - 1:0] tmp_result [0:Para_Deg-1];
			
			genvar PE_index;
			generate
				for(PE_index = 0; PE_index < Para_Deg; PE_index = PE_index + 1) begin: PEs
					multiplier #(.Data_Width(Data_Width)) mul(.in_data0(data0[Data_Width * (PE_index+1) - 1:Data_Width * PE_index]), 
					.in_data1(data1[Data_Width * (PE_index+1) - 1:Data_Width * PE_index]), .out_data(mul_result[PE_index]));
				end
			endgenerate
			
			integer acc_index;
			
			always@(posedge clk) begin
				if(reset) begin
					for(acc_index = 0; acc_index < Para_Deg; acc_index = acc_index + 1) begin: clearRegs
						tmp_result[acc_index] <= 0;
					end					
				end
				else if (Initial_Accumulate) begin
					for(acc_index = 0; acc_index < Para_Deg; acc_index = acc_index + 1) begin: restartAccumulate
						tmp_result[acc_index] <= old_output[2 * Data_Width * acc_index +:2 * Data_Width] + mul_result[acc_index];
					end					
				end
				else begin	
					for(acc_index = 0; acc_index < Para_Deg; acc_index = acc_index + 1) begin: accumulate
						tmp_result[acc_index] <= tmp_result[acc_index] + mul_result[acc_index];
					end
				end
			end
			
			genvar out_index;
				generate
				for(out_index = 0; out_index < Para_Deg; out_index = out_index + 1) begin: output_connection
					assign result[Data_Width * 2 * out_index +:2 * Data_Width] = tmp_result[out_index];
				end
			endgenerate

endmodule
