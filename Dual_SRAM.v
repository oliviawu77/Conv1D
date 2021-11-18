//para_deg: read/write #para_deg data at once (parallelly)
module Dual_SRAM
		#(
		parameter Data_Width = 8,
		parameter Addr_Width = 4,
		parameter Ram_Depth = 1 << Addr_Width,
		parameter Para_Deg = 2)
		(clk, Mem_Clear, Chip_Select, En_Write, En_Read, Addr_Write, Addr_Read, Write_Data, Read_Data);
			
			input clk, Mem_Clear, Chip_Select, En_Write, En_Read;
			input [Addr_Width-1:0] Addr_Write, Addr_Read;

			input [Para_Deg * Data_Width-1:0] Write_Data;
			
			output [Para_Deg * Data_Width-1:0] Read_Data;
			
			reg [Para_Deg * Data_Width-1:0] Read_Data;
			
			reg [Data_Width-1:0] Mem_Data [0:Ram_Depth-1];
			
			integer Mem_Index;
			integer Write_Index;
			
			//Write
			always@(posedge clk) begin
				if(Mem_Clear) begin
					for(Mem_Index = 0; Mem_Index < Ram_Depth;Mem_Index = Mem_Index + 1) begin: ClearMemory
						Mem_Data[Mem_Index] <= 0;
					end
				end
				else if(Chip_Select && En_Write) begin
					for(Write_Index = 0; Write_Index < Para_Deg; Write_Index = Write_Index + 1) begin: WriteParallel
						Mem_Data[Addr_Write + Write_Index] <= Write_Data[Write_Index * Data_Width +: Data_Width];
					end
				end
				else begin
					for(Mem_Index = 0; Mem_Index < Ram_Depth;Mem_Index = Mem_Index + 1) begin: MemoryNoWrite
						Mem_Data[Mem_Index] <= Mem_Data[Mem_Index];
					end					
				end
			end
			
			integer Read_Index;
			//Read
			always@(posedge clk) begin
				if(!Mem_Clear && Chip_Select && En_Read) begin
					for(Read_Index = 0; Read_Index < Para_Deg; Read_Index = Read_Index + 1) begin: ReadParallel
						Read_Data[Read_Index * Data_Width +: Data_Width] <= Mem_Data[Addr_Read + Read_Index];
					end
				end
				else begin
					Read_Data <= 0;
				end
			end
			
endmodule

