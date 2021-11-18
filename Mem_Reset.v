//reset memory and L0 buffer
module Mem_Reset
	#(			
		parameter Nums_SRAM_In = 2,
		parameter Nums_SRAM_Out = 1,
		parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
		parameter Nums_L0_In = 2,
		parameter Nums_L0_Out = 1,
		parameter Nums_L0 = Nums_L0_In + Nums_L0_Out
	)
	(clk, Mem_Reset, L0_Reset, Mem_Clear, L0_Clear);
		input clk, Mem_Reset, L0_Reset;
		output reg [Nums_SRAM - 1:0] Mem_Clear;
		output reg [Nums_L0 - 1:0] L0_Clear;
		
		integer Ram_Index;
	
		always@(posedge clk) begin
			if(Mem_Reset) begin
				for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: MemReset
					Mem_Clear[Ram_Index] <= 0;
				end
			end
			if (L0_Reset) begin
				for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: L0Reset
					L0_Clear[Ram_Index] <= 0;
				end				
			end
		end
endmodule
