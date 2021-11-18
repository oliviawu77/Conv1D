`timescale 100ns/100ns

module PEGroup_tb
			#(
				parameter Data_Width = 8,
				parameter Para_Deg = 3)
			();

			reg clk, reset, Initial_Accumulate;
			reg [Para_Deg * Data_Width - 1:0] data0, data1;
			reg [Para_Deg * Data_Width * 2 - 1:0] old_output;
			wire [Para_Deg * Data_Width * 2 - 1:0] result;
			
			PEGroup #(.Data_Width(Data_Width), .Para_Deg(Para_Deg)) pegroups(clk, reset, Initial_Accumulate, data0, data1, result, old_output);
			
			integer i;

			initial begin
				clk <= 1;
				reset <= 1;
				data0 <= 0;
				data1 <= 0;
				Initial_Accumulate <= 0;
				old_output <= 0;
				#2
				reset <= 0;
				#4
				Initial_Accumulate <= 1;
				#2
				Initial_Accumulate <= 0;
			end
			
			always #1 clk <= ~clk;
			
			always #2 begin
				for(i = 0; i < Para_Deg; i = i + 1) begin: assigndata
					//data0[i * Data_Width +: 8] = {$random} %65536;
					//data1[i * Data_Width +: 8] = {$random} %65536;
					//old_output[2 * i * Data_Width +: 16]= {$random} %65536;
					data0[i * Data_Width +: 8] = 2;
					data1[i * Data_Width +: 8] = 100;
					old_output[2 * i * Data_Width +: 16]= 1000;
				end
			end			
			
			always #2 begin
				$display("time = %0d, reset = %b, Initial_Accumulate = %b", $time, reset, Initial_Accumulate);
				for(i = 0; i < Para_Deg; i = i + 1) begin: displayDataAlways
					$display("i = %0d, old_output =%d, data0 =%d, data1 =%d, result =%d",
					i, old_output[2 * i * Data_Width +: 2 * Data_Width], data0[i * Data_Width +: Data_Width], data1[i * Data_Width +: Data_Width],
					result[2 * i * Data_Width +: 2 * Data_Width]);
				end
			end

endmodule
