module multiplier
		#(parameter Data_Width = 8)
		(in_data0, in_data1, out_data);
	
		input [Data_Width-1:0] in_data0, in_data1;
		output [Data_Width*2-1:0] out_data;
			
		assign out_data = in_data0 * in_data1;
			
endmodule
