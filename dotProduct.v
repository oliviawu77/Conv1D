/*
Notes:
1. Write with Parallel Function is not verified

*/
/*
**parameters**

Addr_Width:					Address Width of Memories(SRAMs).
Ram_Depth:					Depth of Memories(SRAMs).
Nums_SRAM_In:				Number of SRAM to store input data.
Nums_SRAM_Out:				Number of SRAM to store output data.
Nums_SRAM:					Nums_SRAM_In + Nums_SRAM_Out.
Nums_Data_in_bits:			to record total computational steps to complete the dotproduct.
Nums_Data:					Number of Data to be processed.
Nums_Pipeline_Stages:		Number of Pipeline Stages.
Pipeline_Tail:				Number of Tail of this Pipeline.
Total_Computation_Steps:	total computational steps to complete the dotproduct.
Para_Deg:					parallelly compute #Para_deg products at once.
Data_Width_In:				Data Width for input data.
Data_Width_Out:				Data Width for output data.

**inputs**

clk: 				clock signal
Mem_reset:			if 1 then clear the memory 
Comp_reset:			if 1 then clear the computational steps counter
Mem_Index_reset:	if 1 then clear the memory index counter
Computing:			if 1 then set $computing_signal to 1 and start doing compute(dotproduct)
PE_reset:			if 1 then reset the PEGroups 
load_old_output:	if 1 then sum up multiplication result with old output, if 0 then directlly write multiplication result to the output SRAM
load_from_file:		if 1 then set $loading_signal to 1, and switch to read data from file mode
write_to_file:		if 1 then set $loading_signal to 1, and switch to write data to file mode

**outputs**

result:				dotProduct result at each state
state:				the counter to record the computational steps

*/
module dotProduct
		#(
			parameter Addr_Width = 4,
			parameter Ram_Depth = 1 << Addr_Width,
			parameter Nums_SRAM_In = 2,
			parameter Nums_SRAM_Out = 1,
			parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
			parameter Nums_Data_in_bits = 4,
			parameter Nums_Data = 1 << Nums_Data_in_bits,
			parameter Nums_Pipeline_Stages = 4,
			parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
			parameter Total_Computation_Steps = Nums_Data + Pipeline_Tail,
			parameter Para_Deg = 2,
			parameter Data_Width_In = 8,
			parameter Data_Width_Out = 16
		)
		(clk, Mem_reset, Comp_reset, Mem_Index_reset, Computing,
		PE_reset, load_old_output, load_from_file, write_to_file,
		input_data_from_file, output_data_from_file, output_data_to_file,
		result, state,
		test_r, test_w, test_data, en_write_test,
		mem_index_test, test_en_read, test_signal); 
				
		input clk, Mem_reset, Comp_reset, Mem_Index_reset, Computing;
		input PE_reset, load_old_output, load_from_file, write_to_file;
		input [Nums_SRAM_In * Para_Deg * Data_Width_In - 1:0] input_data_from_file;
		input [Nums_SRAM_Out * Para_Deg * Data_Width_Out - 1:0] output_data_from_file;

		output [Nums_SRAM_Out * Para_Deg * Data_Width_Out - 1:0] output_data_to_file;
		output [Para_Deg * Data_Width_Out - 1:0] result;
		output [Nums_Data_in_bits:0] state;
		
		//tests
		output [Nums_SRAM * Addr_Width - 1:0] test_r , test_w;
		output [Nums_SRAM_In * Para_Deg * Data_Width_In - 1:0] test_data;
		//

		wire [Nums_SRAM - 1:0] memclear, cs, en_w, en_r;
		wire [Nums_SRAM * Addr_Width - 1:0] read_addr, write_addr;

		wire [Para_Deg * Data_Width_In - 1:0] data_in [0:Nums_SRAM_In-1];
		wire [Para_Deg * Data_Width_Out - 1:0] old_output;
		wire [Para_Deg * Data_Width_Out - 1:0] data_out [0:Nums_SRAM_Out-1];
		wire [Para_Deg * Data_Width_In - 1:0] write_in_data [0:Nums_SRAM_In-1];
		wire [Para_Deg * Data_Width_Out - 1:0] write_out_data [0:Nums_SRAM_Out-1];
		wire loading_signal, computing_signal, write_to_file_signal;

		MEMController #(.Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out), .Nums_SRAM(Nums_SRAM),
		.Nums_Data_in_bits(Nums_Data_in_bits), .Nums_Data(Nums_Data), .Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail),
		.Total_Computation_Steps(Total_Computation_Steps), .Para_Deg(Para_Deg))
		memcontroller (.clk(clk), .Mem_reset(Mem_reset), .Comp_reset(Comp_reset), .Mem_Index_reset(Mem_Index_reset), 
		.load_from_file(load_from_file), .Computing(Computing), .write_to_file(write_to_file), 
		.loading_signal(loading_signal), .computing_signal(computing_signal), .write_to_file_signal(write_to_file_signal),
		.Mem_Clear(memclear), .En_Chip_Select(cs), .En_Write(en_w), .En_Read(en_r), .Addr_Read(read_addr), .Addr_Write(write_addr),
		 .test(state), .mem_index_test(mem_index_test));

		//tests
		output en_write_test;
		assign en_write_test = en_w[0];
		output [Addr_Width:0] mem_index_test;
		output test_en_read;
		assign test_en_read = en_r[2];
		output test_signal;
		assign test_signal = computing_signal;
		//

		genvar SRAM_Index;
		genvar offset_Index;

		generate
			for(SRAM_Index = 0; SRAM_Index < Nums_SRAM_In; SRAM_Index = SRAM_Index + 1) begin: SRAMsINs
				Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Para_Deg(Para_Deg))
				srams_inputs (.clk(clk), .Mem_Clear(memclear[SRAM_Index]), .Chip_Select(cs[SRAM_Index]), .En_Write(en_w[SRAM_Index]),
				.En_Read(en_r[SRAM_Index]), .Addr_Write(write_addr[Addr_Width * SRAM_Index +: Addr_Width]), 
				.Addr_Read(read_addr[Addr_Width * SRAM_Index +: Addr_Width]), .Write_Data(write_in_data[SRAM_Index]), .Read_Data(data_in[SRAM_Index]));
				assign write_in_data[SRAM_Index] = loading_signal ? input_data_from_file[SRAM_Index * Para_Deg * Data_Width_In +: Para_Deg * Data_Width_In] : 0;
				
				//test data read from memory
				for(offset_Index = 0; offset_Index < Para_Deg; offset_Index = offset_Index + 1) begin: SRAMsINsParallel
					assign test_data[SRAM_Index * Para_Deg * Data_Width_In + offset_Index * Data_Width_In +: Data_Width_In] = 
							data_in[SRAM_Index][Data_Width_In * (offset_Index + 1) - 1 :Data_Width_In * offset_Index];
				end

				assign test_r[SRAM_Index * Addr_Width +: Addr_Width] = read_addr[Addr_Width * SRAM_Index +: Addr_Width];
				assign test_w[SRAM_Index * Addr_Width +: Addr_Width] = write_addr[Addr_Width * SRAM_Index +: Addr_Width];
			end
			for(SRAM_Index = Nums_SRAM_In; SRAM_Index < Nums_SRAM; SRAM_Index = SRAM_Index + 1) begin: SRAMsOuts
				Dual_SRAM #(.Data_Width(Data_Width_Out), .Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Para_Deg(Para_Deg))
				srams_outputs (.clk(clk), .Mem_Clear(memclear[SRAM_Index]), .Chip_Select(cs[SRAM_Index]), .En_Write(en_w[SRAM_Index]), 
				.En_Read(en_r[SRAM_Index]), .Addr_Write(write_addr[Addr_Width * SRAM_Index +: Addr_Width]), 
				.Addr_Read(read_addr[Addr_Width * SRAM_Index +: Addr_Width]), .Write_Data(write_out_data[SRAM_Index-Nums_SRAM_In]), .Read_Data(old_output));
				
				assign write_out_data[SRAM_Index-Nums_SRAM_In] = loading_signal ? 
						output_data_from_file[(SRAM_Index-Nums_SRAM_In) * Para_Deg * Data_Width_Out +: Para_Deg * Data_Width_Out] : data_out[SRAM_Index-Nums_SRAM_In];

				assign test_r[(SRAM_Index) * Addr_Width +: Addr_Width] = read_addr[Addr_Width * SRAM_Index +: Addr_Width];
				assign test_w[(SRAM_Index) * Addr_Width +: Addr_Width] = write_addr[Addr_Width * SRAM_Index +: Addr_Width];
			end
		endgenerate

		assign output_data_to_file = old_output;

		PEGroup #(.Data_Width(Data_Width_In), .Para_Deg(Para_Deg))
		pegroups (.clk(clk), .reset(PE_reset), .load_old_output(load_old_output), .data0(data_in[0]), .data1(data_in[1]), .result(data_out[0]), .old_output(old_output));


		genvar result_index;
		generate
			for(SRAM_Index = 0; SRAM_Index < Nums_SRAM_Out; SRAM_Index = SRAM_Index + 1) begin : resultOutParallel
				for(result_index = 0; result_index < Para_Deg; result_index = result_index + 1) begin: resultParallel
					assign result[result_index * Data_Width_Out +: Data_Width_Out] = data_out[SRAM_Index][result_index * Data_Width_Out +: Data_Width_Out];
				end
			end	
		endgenerate

endmodule
