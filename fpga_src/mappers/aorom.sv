module aorom(
				 sysclk,
				 cpu_clock,
				 reset,
				 //
				 mirror,
				 //cpu
				 cpu_bus,
				 cpu_wr,
				 cpu_data_in,
				 cpu_data_out,
				 //ppu
				 ppu_bus,
				 ppu_wr,
				 ppu_data_in,
				 ppu_data_out,
				 //external ram  cpu
				 ext_cpu_bus,
				 ext_cpu_data_in,
				 ext_cpu_data_out,
				 ext_cpu_wr,
				 //external ram ppu
				 ext_ppu_bus,
				 ext_ppu_data_in,
				 ext_ppu_data_out,
				 ext_ppu_wr
				);
				
input		sysclk;
input		cpu_clock;
input		reset;
//
output	mirror;
//cpu
input		[15:0]cpu_bus;
input		cpu_wr;
input		[7:0]cpu_data_in;
output	[7:0]cpu_data_out;
//ppu
input		[13:0]ppu_bus;
input		ppu_wr;
input		[7:0]ppu_data_in;
output	[7:0]ppu_data_out;
//memory manager  cpu
output	[24:0]ext_cpu_bus;
input		[7:0]ext_cpu_data_in;
output	[7:0]ext_cpu_data_out;
output	ext_cpu_wr;
//memory manager  ppu
output	[24:0]ext_ppu_bus;
input		[7:0]ext_ppu_data_in;
output	[7:0]ext_ppu_data_out;
output	ext_ppu_wr;		
		
assign	mirror		=	1'b0;  //0 - vertical , 1 - horizontal		
		
wire		aorom_write;
assign	aorom_write	=	cpu_bus[15] & cpu_wr;
//--------------------------------------------------------------------------------
reg		[3:0]bank_select;
always@(posedge sysclk or negedge reset)begin
	if(!reset)bank_select<=0;
	else if(cpu_clock && aorom_write)begin
		bank_select<={cpu_data_in[4],cpu_data_in[2:0]};
	end
end

wire		[2:0]prg_sel = bank_select[2:0];
wire		nt_sel		 = bank_select[3];	
//--------------------------------------------------------------------------------
//memory manager  cpu
wire			[24:0]cpu_rom;	
assign		cpu_rom				=	{prg_sel,cpu_bus[14:0]};

wire			[24:0]cpu_ram;	
assign		cpu_ram				=	(25'h100000 | cpu_bus[14:0]);
																		
assign		ext_cpu_bus			=  cpu_bus[15] ? cpu_rom : cpu_ram;																	
assign		ext_cpu_data_out	=	cpu_data_in;
assign		ext_cpu_wr			=	cpu_bus[15] ? 1'b0 : cpu_wr;

assign		cpu_data_out		=	(~cpu_bus[15] & (&cpu_bus[14:13])) ? 8'h00 :				//fix error in battletoads (access to $5000-$5FFF)
																							 ext_cpu_data_in;  
//--------------------------------------------------------------------------------
//memory manager  ppu										
wire			[12:0]ppu_rom		=	ppu_bus[12:0];

wire			[13:0]ppu_ram;
assign		ppu_ram				= ( &ppu_bus[13:8])   ? ppu_bus:					//3F00 - 3FFF
																	  {nt_sel,ppu_bus[9:0]};//2000 - 2FFF
																	

assign		ext_ppu_bus			= 	ppu_bus[13] ? (25'h100000 | ppu_ram) : ppu_rom;
assign		ext_ppu_data_out	=	ppu_data_in;
assign		ext_ppu_wr			=	ppu_wr;

assign		ppu_data_out		=	ext_ppu_data_in;
endmodule
