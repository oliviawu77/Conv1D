`timescale 1ms/1ms

module MEMController_tb		
		#(	
			parameter Weight_Addr_Width = 2,
			parameter Output_Addr_Width = 1,
			parameter Input_Addr_Width = 3, 
			parameter Nums_SRAM_In = 2,
			parameter Nums_SRAM_Out = 1,
			parameter Nums_SRAM = Nums_SRAM_In + Nums_SRAM_Out,
			parameter Weight_Nums_in_bits = Weight_Addr_Width,
			parameter Weight_Nums = 3,
			parameter Output_Nums_in_bits = Output_Addr_Width,
			parameter Output_Nums = 2,
			parameter Input_Numbs_in_bits = Input_Addr_Width,
			parameter Input_Nums = Weight_Nums + Output_Nums - 1,
			parameter Weight_Ram_Depth = Weight_Nums,
			parameter Output_Ram_Depth = Output_Nums,
			parameter Input_Ram_Depth = Input_Nums,
			parameter Nums_Pipeline_Stages = 4,
			parameter Pipeline_Tail = Nums_Pipeline_Stages - 1,
			parameter Total_Computation_Steps_in_bits = 6,
			parameter Total_Computation_Steps = Weight_Nums * Output_Nums + Pipeline_Tail,
			parameter Para_Deg = 1
		)
            ();
            
            reg clk, Mem_Reset, Comp_Reset;
            reg Weight_Mem_Index_Reset, Output_Mem_Index_Reset, Input_Mem_Index_Reset;
            reg Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal, Computing_Signal;

            wire Weight_Loading_From_File, Output_Loading_From_File, Input_Loading_From_File, Output_Writing_To_File;
            wire Computing;
            wire Initial_Accumulate;

            //memory signals
            wire [Nums_SRAM - 1:0] Mem_Clear, En_Chip_Select, En_Write, En_Read;
            wire [Weight_Addr_Width - 1:0] Weight_Addr_Read, Weight_Addr_Write;
            wire [Output_Addr_Width - 1:0] Output_Addr_Read, Output_Addr_Write;
            wire [Input_Addr_Width - 1:0] Input_Addr_Read, Input_Addr_Write;

            //test
            wire [Total_Computation_Steps_in_bits:0] Computation_Step_Counter;
            wire [Weight_Addr_Width:0] Weight_Mem_Index;
            MEMController #(.Weight_Addr_Width(Weight_Addr_Width), .Output_Addr_Width(Output_Addr_Width), .Input_Addr_Width(Input_Addr_Width),
            .Nums_SRAM_In(Nums_SRAM_In), .Nums_SRAM_Out(Nums_SRAM_Out), .Nums_SRAM(Nums_SRAM), 
            .Weight_Nums_in_bits(Weight_Nums_in_bits), .Weight_Nums(Weight_Nums), 
            .Output_Nums_in_bits(Output_Nums_in_bits), .Output_Nums(Output_Nums),
            .Input_Numbs_in_bits(Input_Numbs_in_bits), .Input_Nums(Input_Nums),
            .Weight_Ram_Depth(Weight_Ram_Depth), .Output_Ram_Depth(Output_Ram_Depth), .Input_Ram_Depth(Input_Ram_Depth),
            .Nums_Pipeline_Stages(Nums_Pipeline_Stages), .Pipeline_Tail(Pipeline_Tail), 
            .Total_Computation_Steps_in_bits(Total_Computation_Steps_in_bits), .Total_Computation_Steps(Total_Computation_Steps),
            .Para_Deg(Para_Deg))
            dut (.clk(clk), .Mem_Reset(Mem_Reset), .Comp_Reset(Comp_Reset), 
                .Weight_Mem_Index_Reset(Weight_Mem_Index_Reset), .Output_Mem_Index_Reset(Output_Mem_Index_Reset), .Input_Mem_Index_Reset(Input_Mem_Index_Reset),
                .Weight_Loading_Signal(Weight_Loading_Signal), .Output_Loading_Signal(Output_Loading_Signal), .Input_Loading_Signal(Input_Loading_Signal), 
                .Output_Writing_Signal(Output_Writing_Signal), .Computing_Signal(Computing_Signal), 
                .Weight_Loading_From_File(Weight_Loading_From_File), .Output_Loading_From_File(Output_Loading_From_File), .Input_Loading_From_File(Input_Loading_From_File), 
                .Output_Writing_To_File(Output_Writing_To_File), .Computing(Computing),
                .Mem_Clear(Mem_Clear), .En_Chip_Select(En_Chip_Select), .En_Write(En_Write), .En_Read(En_Read),
                .Weight_Addr_Read(Weight_Addr_Read), .Weight_Addr_Write(Weight_Addr_Write), 
                .Output_Addr_Read(Output_Addr_Read), .Output_Addr_Write(Output_Addr_Write),
                .Input_Addr_Read(Input_Addr_Read), .Input_Addr_Write(Input_Addr_Write),
                .Computation_Step_Counter(Computation_Step_Counter), .Weight_Mem_Index(Weight_Mem_Index),
                .Initial_Accumulate(Initial_Accumulate));

            initial begin
                clk = 1;
                Mem_Reset = 1;
                Comp_Reset = 1;
                Weight_Mem_Index_Reset = 1;
                Output_Mem_Index_Reset = 1;
                Input_Mem_Index_Reset = 1;

                Weight_Loading_Signal = 0;
                Output_Loading_Signal = 0;
                Input_Loading_Signal = 0;
                Output_Writing_Signal = 0;

                Computing_Signal = 0;
                #2
                Mem_Reset = 0;
                Comp_Reset = 0;
                Weight_Mem_Index_Reset = 0;
                Output_Mem_Index_Reset = 0;
                Input_Mem_Index_Reset = 0;

                Computing_Signal = 1;
                
                #2
                Computing_Signal = 0;
                /*
                #2
                Mem_Reset = 0;
                Comp_Reset = 0;
                Weight_Mem_Index_Reset = 0;
                Output_Mem_Index_Reset = 0;
                Input_Mem_Index_Reset = 0;

                Weight_Loading_Signal = 1;
                Output_Loading_Signal = 0;
                Input_Loading_Signal = 0;
                Output_Writing_Signal = 0;

                Computing_Signal = 0;
                #2

                Weight_Loading_Signal = 0;
                Output_Loading_Signal = 0;
                Input_Loading_Signal = 0;
                Output_Writing_Signal = 0;

                #20
                Output_Loading_Signal = 1;

                #2
                Output_Loading_Signal = 0;
                
                #20
                Input_Loading_Signal = 1;

                #2
                Input_Loading_Signal = 0;
                */
                //Computing_Signal = 0;
            end
            
            always #1 clk = ~clk;

            integer Ram_Index = 0;

            always #2 begin
                $display("--------------------------------------------------------------------------------------------");
                $display("time:%0d, Weight_Mem_Reset =%b, Output_Mem_Reset = %b, Input_Mem_Reset =%b, Comp_Reset =%b",
                $time, Weight_Mem_Index_Reset, Output_Mem_Index_Reset, Input_Mem_Index_Reset, Comp_Reset);
                $display("loading_weight =%b, loading_output =%b, loading_input =%b, writing_output =%b, Computing_Signal= %b, Initial_Accumulate =%b",
                Weight_Loading_Signal, Output_Loading_Signal, Input_Loading_Signal, Output_Writing_Signal, Computing_Signal, Initial_Accumulate);
                $display("Computing =%b, Steps: %d", Computing, Computation_Step_Counter);
                $display("Weight_Loading_From_File =%b, Weight_Mem_Index =%d", Weight_Loading_From_File, Weight_Mem_Index);
                for(Ram_Index = 0; Ram_Index < Nums_SRAM; Ram_Index = Ram_Index + 1) begin: showSignals
                    $display("RAM%0d: Mem_Clear =%b, En_Chip_Select =%b, En_Write =%b, En_Read=%b", 
                    Ram_Index, Mem_Clear[Ram_Index], En_Chip_Select[Ram_Index], En_Write[Ram_Index], En_Read[Ram_Index]);
                end
                $display("Weight_Addr_Read =%d, Output_Addr_Read =%d, Input_Addr_Read =%d", Weight_Addr_Read, Output_Addr_Read, Input_Addr_Read);
                $display("Weight_Addr_Write =%d, Output_Addr_Write =%d, Input_Addr_Write =%d", Weight_Addr_Write, Output_Addr_Write, Input_Addr_Write);
            end
endmodule
