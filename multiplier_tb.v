`timescale 100ns/100ns

module multiplier_tb
		#(
			parameter Data_Width = 8)
		();
		
		reg [Data_Width-1:0] in_data0, in_data1;
		wire [Data_Width*2-1:0] out_data;
		
		multiplier #(.Data_Width(Data_Width)) mul(in_data0, in_data1, out_data);
		
		initial begin
			in_data0 = 0;
			in_data1 = 0;
		end
		
		always #1 in_data0 = in_data0 + 1;
		always #1 in_data1 = in_data1 + 10;
		
endmodule
