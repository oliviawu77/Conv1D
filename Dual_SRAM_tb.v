//3 SRAM module
//so we need to create an array of control signals
//so as data and address ports
`timescale 1ms/1ms
module Dual_SRAM_tb #(	
					parameter Data_Width_In = 8,
					parameter Data_Width_Out = 16,
					parameter Addr_Width = 4,
					parameter Ram_Depth = 1 << Addr_Width,
					parameter Nums_SRAM_In = 2,
					parameter Nums_SRAM_Out = 1,
					parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
					parameter Para_Deg = 2)
					();
		reg clk, Mem_Clear [Nums_SRAM-1:0], Chip_Select [Nums_SRAM-1:0], En_Write [Nums_SRAM-1:0], En_Read [Nums_SRAM-1:0];
		reg [Addr_Width-1:0] Write_Addr [Nums_SRAM-1:0], Read_Addr[Nums_SRAM-1:0];

		reg [Para_Deg * Data_Width_In-1:0] Write_Data_Input [Nums_SRAM_In-1:0];
		reg [Para_Deg * Data_Width_Out-1:0] Write_Data_Output [Nums_SRAM_Out-1:0];

		wire [Para_Deg * Data_Width_In-1:0] Read_Data_Input [Nums_SRAM_In-1:0];
		wire [Para_Deg * Data_Width_Out-1:0] Read_Data_Output [Nums_SRAM_Out-1:0];
		
		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Para_Deg(Para_Deg)) 
					sram0(clk, Mem_Clear[0], Chip_Select[0], En_Write[0], En_Read[0], Write_Addr[0], Read_Addr[0], Write_Data_Input[0], Read_Data_Input[0]); //for in1
		Dual_SRAM #(.Data_Width(Data_Width_In), .Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Para_Deg(Para_Deg)) 
					sram1(clk, Mem_Clear[1], Chip_Select[1], En_Write[1], En_Read[1], Write_Addr[1], Read_Addr[1], Write_Data_Input[1], Read_Data_Input[1]); //for in2
		Dual_SRAM #(.Data_Width(Data_Width_Out), .Addr_Width(Addr_Width), .Ram_Depth(Ram_Depth), .Para_Deg(Para_Deg)) 
					sram2(clk, Mem_Clear[2], Chip_Select[2], En_Write[2], En_Read[2], Write_Addr[2], Read_Addr[2], Write_Data_Output[0], Read_Data_Output[0]); //for out

		reg [Data_Width_In - 1:0] buffer_in [Nums_SRAM_In-1:0]; //to store input data read from file
		reg [Data_Width_Out - 1:0] buffer_out [Nums_SRAM_Out-1:0]; //to store output data read from file

		integer file [0:Nums_SRAM-1];
		integer Read_Index = 0;
		integer Ram_Index = 0;
		integer offset_Index = 0;

		initial begin
			clk <= 1;
			for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: initializeSRAMsignals
				Mem_Clear[Ram_Index] = 1;
				Chip_Select[Ram_Index] = 0;
				En_Write[Ram_Index] = 0;
				Write_Addr[Ram_Index] = 0;
				En_Read[Ram_Index] = 1;
				Read_Addr[Ram_Index] = 0;
			end

			for(Ram_Index = 0; Ram_Index < Nums_SRAM_In; Ram_Index = Ram_Index + 1) begin: initializeSRAMInputs
				Write_Data_Input[Ram_Index] = 0;
			end
			for(Ram_Index = 0; Ram_Index < Nums_SRAM_Out; Ram_Index = Ram_Index + 1) begin: initializeSRAMOutputs
				Write_Data_Output[Ram_Index] = 0;
			end

			file[0] = $fopen("input0.txt","r");
			file[1] = $fopen("input1.txt","r");
			file[2] = $fopen("output.txt","r");
			$display("loading...");
			for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: ReadFileSetSignals
					Mem_Clear[Ram_Index] = 0;
					Chip_Select[Ram_Index] = 1;
					En_Write[Ram_Index] = 1;
			end

			for(Read_Index = 0; Read_Index < Ram_Depth; Read_Index = Read_Index + Para_Deg) begin: ReadFile
				#2
				$display("---Index:%0d---", Read_Index);
				for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: SetWriteAddr
						Write_Addr[Ram_Index] = Read_Index;
				end
				for(offset_Index = 0; offset_Index < Para_Deg; offset_Index = offset_Index + 1) begin : loadingfromfileoffset
					$fscanf(file[0], "%d", buffer_in[0]);
					Write_Data_Input[0][offset_Index * Data_Width_In +: Data_Width_In] = buffer_in[0];
					$fscanf(file[1], "%d", buffer_in[1]);
					Write_Data_Input[1][offset_Index * Data_Width_In +: Data_Width_In] = buffer_in[1];
					$fscanf(file[2], "%d", buffer_out[0]);
					Write_Data_Output[0][offset_Index * Data_Width_Out +: Data_Width_Out] = buffer_out[0];
				end
			end
			$fclose(file);
			#2
			$display("loading complete!");
			Write_Data_Input[0] = 0;
			Write_Data_Input[1] = 0;
			Write_Data_Output[0] = 0;

			En_Read[0] = 1;
			En_Write[0] = 0;
			Write_Addr[0] = 0;
			Read_Addr[0] = 0;

			En_Read[1] = 1;
			En_Write[1] = 0;
			Write_Addr[1] = 0;
			Read_Addr[1] = 0;

			En_Read[2] = 1;
			En_Write[2] = 0;
			Write_Addr[2] = 0;
			Read_Addr[2] = 0;

			#2
			En_Read[0] = 1;
			En_Write[0] = 0;
			Write_Addr[0] = 0;
			Read_Addr[0] = 4;

			En_Read[1] = 1;
			En_Write[1] = 0;
			Write_Addr[1] = 0;
			Read_Addr[1] = 1;

			En_Read[2] = 1;
			En_Write[2] = 0;
			Write_Addr[2] = 0;
			Read_Addr[2] = 10;
		end

		always #1 clk = ~clk;
		
		integer  Para_Index;
		always begin
			#2
			$display("-time:%0d-", $time);
			$display("RAM0: Mem_Clear =%b, Chip_Select =%b, En_Write =%b, En_Read =%b, Write_Addr =%d, Read_Addr =%d"
					,Mem_Clear[0], Chip_Select[0], En_Write[0], En_Read[0], Write_Addr[0], Read_Addr[0]);
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: ReadParallel0
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data_Input[0][Para_Index * Data_Width_In +: Data_Width_In]);
			end
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: WriteParallel0
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data_Input[0][Para_Index * Data_Width_In +: Data_Width_In]);
			end			
			$display("RAM1: Mem_Clear =%b, Chip_Select =%b, En_Write =%b, En_Read =%b, Write_Addr =%d, Read_Addr =%d"
					,Mem_Clear[1], Chip_Select[1], En_Write[1], En_Read[1], Write_Addr[1], Read_Addr[1]);
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: ReadParallel1
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data_Input[1][Para_Index * Data_Width_In +: Data_Width_In]);
			end
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: WriteParallel1
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data_Input[1][Para_Index * Data_Width_In +: Data_Width_In]);
			end				
			$display("RAM2: Mem_Clear =%b, Chip_Select =%b, En_Write =%b, En_Read =%b, Write_Addr =%d, Read_Addr =%d"
					,Mem_Clear[2], Chip_Select[2], En_Write[2], En_Read[2], Write_Addr[2], Read_Addr[2]);
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: ReadParallel2
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data_Output[0][Para_Index * Data_Width_Out +: Data_Width_Out]);
			end
			for(Para_Index = 0; Para_Index < Para_Deg; Para_Index = Para_Index + 1) begin: WriteParallel2
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data_Output[0][Para_Index * Data_Width_Out +: Data_Width_Out]);
			end			
		end
endmodule
