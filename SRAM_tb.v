//3 SRAM module
//so we need to create an array of control signals
//so as data and address ports
`timescale 1ms/1ms
module SRAM_tb #(	
					parameter data_width = 8,
					parameter addr_width = 4,
					parameter Ram_Depth = 1 << addr_width,
					parameter Nums_SRAM = 3,
					parameter para_deg = 4)
					();
		reg clk, Mem_Clear [Nums_SRAM-1:0] , Chip_Select [Nums_SRAM-1:0], En_Write [Nums_SRAM-1:0], En_Read [Nums_SRAM-1:0];
		reg [addr_width-1:0] Write_Addr [Nums_SRAM-1:0], Read_Addr[Nums_SRAM-1:0];
		reg [para_deg * data_width-1:0] Write_Data [Nums_SRAM-1:0];

		wire [para_deg * data_width-1:0] Read_Data [Nums_SRAM-1:0];
		
		Dual_SRAM #(.data_width(data_width), .addr_width(addr_width), .Ram_Depth(Ram_Depth), .para_deg(para_deg)) 
					sram0(clk, Mem_Clear[0], Chip_Select[0], En_Write[0], En_Read[0], Write_Addr[0], Read_Addr[0], Write_Data[0], Read_Data[0]); //for in1
		Dual_SRAM #(.data_width(data_width), .addr_width(addr_width), .Ram_Depth(Ram_Depth), .para_deg(para_deg)) 
					sram1(clk, Mem_Clear[1], Chip_Select[1], En_Write[1], En_Read[1], Write_Addr[1], Read_Addr[1], Write_Data[1], Read_Data[1]); //for in2
		Dual_SRAM #(.data_width(data_width), .addr_width(addr_width), .Ram_Depth(Ram_Depth), .para_deg(para_deg)) 
					sram2(clk, Mem_Clear[2], Chip_Select[2], En_Write[2], En_Read[2], Write_Addr[2], Read_Addr[2], Write_Data[2], Read_Data[2]); //for out

		reg [data_width-1:0] buffer; //to store data read from file

		integer file [0:Nums_SRAM-1];
		integer Read_Index = 0;
		integer Ram_Index = 0;

		initial begin
			clk <= 1;
			for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: initialize
				Mem_Clear[Ram_Index] = 1;
				Chip_Select[Ram_Index] = 0;
				En_Write[Ram_Index] = 0;
				En_Read[Ram_Index] = 1;
				Write_Addr[Ram_Index] = 0;
				Read_Addr[Ram_Index] = 0;
				Write_Data[Ram_Index] = 0;
			end
			file[0] = $fopen("input0.txt","r");
			file[1] = $fopen("input1.txt","r");
			file[2] = $fopen("output.txt","r+b");
			$display("loading...");
			for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: ReadFileSetSignals
					Mem_Clear[Ram_Index] = 0;
					Chip_Select[Ram_Index] = 1;
					En_Write[Ram_Index] = 1;
			end

			for(Read_Index = 0; Read_Index < Ram_Depth; Read_Index = Read_Index + 1) begin: ReadFile
				#2
				$display("---Index:%0d---", Read_Index);
				for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: SetWriteAddr
						Write_Addr[Ram_Index] = Read_Index;
				end

				$fscanf(file[0], "%d", buffer);
				Write_Data[0] = buffer;
				$fscanf(file[1], "%d", buffer);
				Write_Data[1] = buffer;
				$fscanf(file[2], "%d", buffer);
				Write_Data[2] = buffer;
			end
			$fclose(file);
			#2
			$display("loading complete!");
			Write_Data[0] = 0;
			Write_Data[1] = 0;
			Write_Data[2] = 0;

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
			Read_Addr[0] = 1;

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
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: ReadParallel0
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data[0][Para_Index * data_width +: data_width]);
			end
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: WriteParallel0
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data[0][Para_Index * data_width +: data_width]);
			end			
			$display("RAM1: Mem_Clear =%b, Chip_Select =%b, En_Write =%b, En_Read =%b, Write_Addr =%d, Read_Addr =%d"
					,Mem_Clear[1], Chip_Select[1], En_Write[1], En_Read[1], Write_Addr[1], Read_Addr[1]);
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: ReadParallel1
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data[1][Para_Index * data_width +: data_width]);
			end
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: WriteParallel1
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data[1][Para_Index * data_width +: data_width]);
			end				
			$display("RAM2: Mem_Clear =%b, Chip_Select =%b, En_Write =%b, En_Read =%b, Write_Addr =%d, Read_Addr =%d"
					,Mem_Clear[2], Chip_Select[2], En_Write[2], En_Read[2], Write_Addr[2], Read_Addr[2]);
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: ReadParallel2
				$display("Read_Data[%0d] = %d", Para_Index, Read_Data[2][Para_Index * data_width +: data_width]);
			end
			for(Para_Index = 0; Para_Index < para_deg; Para_Index = Para_Index + 1) begin: WriteParallel2
				$display("Write_Data[%0d] = %d", Para_Index, Write_Data[2][Para_Index * data_width +: data_width]);
			end			
		end
endmodule
