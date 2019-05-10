
module core6502(
						sysclk,
						cpu_clock,
						reset,
						rdy,
						irq,
						nmi,
						addr_bus,
						rw,
						data_in,
						data_out,
						//for debug
						unk_cmd
					);
					
input		sysclk;
input 		cpu_clock;
input		reset;
input 	    rdy;
input		irq;
input		nmi;
output	   [15:0]addr_bus;
output	    rw;
input		[7:0]data_in;
output		[7:0]data_out;
//for_debug
output		unk_cmd;

assign unk_cmd = (sm_decode == NOP && hold_opcode != 8'hEA);
//--------------------------------------------------------------------------------	
parameter 
	DECODE 		= 6'd0,
	INT0 		= 6'd1,
	INT1 		= 6'd2,
	INT2 		= 6'd3,
	INT3 		= 6'd4,
	INT4 		= 6'd5,
	INT5 		= 6'd6,
	IMPL_REGS 	= 6'd7,
	IMPL_FLAGS  = 6'd8,
	RTN_COMMON0 = 6'd9,          //ADDR_BUS = SP + 1(inc)
	RTN_I0	    = 6'd10,		 //read flags
	RTN_I1		= 6'd11,         //read low addr
	RTN_I2	    = 6'd12,         //read hight addr
	RTN_S0	    = 6'd13,		 //read low addr	
	RTN_S1		= 6'd14,         //read hight addr
	RTN_S2	    = 6'd15,         //hight addr:low addr + 1
	RTN_COMMON1 = 6'd16,		 //PC = hight addr:low addr
	PUSH0		= 6'd17,
	PUSH1       = 6'd18,
	PULL0		= 6'd19,		 //SP<=SP+1
	PULL1		= 6'd20,		 //AB = SP, A/FLAGS <= SP[0]
	PULL2		= 6'd21,	     //dummy
	ALU_IMM	    = 6'd22,		 //read second alu operand	
	NOP			= 6'd23,
	ABS_ADDR0   = 6'd24,
	ABS_ADDR1   = 6'd25,
	ABS_RDATA   = 6'd26,
	ALU_WR0		= 6'd27,		//get alu result
	ALU_WR1     = 6'd28, 		//write hold alu result in memory
	ABS_JSR0	= 6'd29,
	ABS_JSR1	= 6'd30,
	ABS_JSR2	= 6'd31,
	ZP_ADDR0    = 6'd32,
	ZP_RDATA    = 6'd33,
	JXX0		= 6'd34,
	JXX1		= 6'd35,
	JXX2		= 6'd36,
	ZP_XY_ADDR0 = 6'd37,
	ZP_XY_ADDR1 = 6'd38,
	ABS_IND0	= 6'd39,
	ABS_IND1	= 6'd40,
	ACCUM		= 6'd41,
	RD_ADDR_ABS_XY0 = 6'd42,
	RD_ADDR_ABS_XY1 = 6'd43,
	ABS_XY0_C 		= 6'd44,
	ABS_XY0_RD_DATA = 6'd45,
	IND_X_RDBYTE	= 6'd46,
	IND_X_ADD_X     = 6'd47,
	IND_X_ADDR0		= 6'd48,
	IND_X_ADDR1		= 6'd49,
	
	IND_Y_RDBYTE	= 6'd50,
	IND_Y_ADDR0		= 6'd51,
	IND_Y_ADDR1		= 6'd52,
	IND_Y_C			= 6'd53,

	IND_XY_RDDATA	= 6'd54,
	
	ALU_SVMEM		= 6'd55; 
	
wire	cond_some_int = (hold_opcode == 8'h00) | hold_nmi | (hold_irq & ~i_flag);

wire	cond_immediate = (hold_opcode == 8'h69) |  // adc
						(hold_opcode == 8'h29) |   // and
						(hold_opcode == 8'hC9) |   // cmp
						(hold_opcode == 8'hE0) |   // cpx
						(hold_opcode == 8'hC0) |   // cpy
						(hold_opcode == 8'h49) |   // eor
						(hold_opcode == 8'h09) |   // ora 
						(hold_opcode == 8'hA9) |   // lda alu_data_a = 0
						(hold_opcode == 8'hA2) |   // ldx alu_data_a = 0
						(hold_opcode == 8'hA0) |   // ldy alu_data_a = 0
						(hold_opcode == 8'hE9);    // sbc

wire 	cond_impl_regs = (hold_opcode == 8'hA8) |  //  tay
						(hold_opcode == 8'hBA) |   //  tsx
						(hold_opcode == 8'h8A) |   //  txa
						(hold_opcode == 8'h9A) |   //  txs
						(hold_opcode == 8'h98) |   //  tya
						(hold_opcode == 8'hCA) |   //  dex
						(hold_opcode == 8'h88) |   //  dey	
						(hold_opcode == 8'hE8) |   //  inx
						(hold_opcode == 8'hC8) |   //  iny
						(hold_opcode == 8'hAA) ;   //  tax					
//wire 	cond_nop        =(hold_opcode == 8'hEA);    //  nop

wire	cond_impl_flags = (hold_opcode == 8'h18) | //  clc
						(hold_opcode == 8'hD8) |   //  cld
						(hold_opcode == 8'h58) |   //  cli
						(hold_opcode == 8'hB8) |   //  clv
						(hold_opcode == 8'h38) |   //  sec
						(hold_opcode == 8'hF8) |   //  sed
						(hold_opcode == 8'h78);    //  sei

wire	cond_return =   (hold_opcode == 8'h40) |   //  rti
						(hold_opcode == 8'h60);    //  rts

wire 	cond_push	=	(hold_opcode == 8'h48) |   // pha
						(hold_opcode == 8'h08);    // php
wire 	cond_pull	= 	(hold_opcode == 8'h68) |   // pla
						(hold_opcode == 8'h28);	   // plp 
						
wire 	cond_abs	=	//1)alu+reg+mem => save into reg or no save
						(hold_opcode == 8'h6D) |   // adc   (no write into mem)   A dest
						(hold_opcode == 8'hED) |   // sbc   (no write into mem)   A dest
						(hold_opcode == 8'h2D) |   // and   (no write into mem)   A dest
						(hold_opcode == 8'hCD) |   // cmp   (no write into mem)   A dest
						(hold_opcode == 8'h4D) |   // eor   (no write into mem)   A dest
						(hold_opcode == 8'h0D) |   // ora   (no write into mem)   A dest
						(hold_opcode == 8'h2C) |   // bit   (no write into mem)   A dest
						(hold_opcode == 8'hEC) |   // cpx  (no write into mem)
						(hold_opcode == 8'hCC) |   // cpy ( no write into mem)
						(hold_opcode == 8'hAE) |   // ldx (no write into mem)  alu_data_a = 0
						(hold_opcode == 8'hAC) |   // ldy (no write into mem)  alu_data_a = 0
						(hold_opcode == 8'hAD) |   // lda (no write into mem) alu_data_a = 0 
						//2)alu+mem => save into mem
						(hold_opcode == 8'h0E) |   // asl +
						(hold_opcode == 8'hCE) |   // dec +	
						(hold_opcode == 8'hEE) |   // inc +
						(hold_opcode == 8'h4E) |   // lsr +
						(hold_opcode == 8'h2E) |   // rol +
						(hold_opcode == 8'h6E) |   // ror +
						//3)only save reg into mem
						(hold_opcode == 8'h8D) |   // sta+
						(hold_opcode == 8'h8E) |   // stx+
						(hold_opcode == 8'h8C) |   // sty+	
						//4)other (prepare individual)
						(hold_opcode == 8'h4C) |   // jmp +						
						(hold_opcode == 8'h20);    // jsr +
						
wire		cond_abs_ind = (hold_opcode == 8'h6C);	//jmp abs indirect
						
wire 		cond_zp	=	//1)alu+reg+mem => save into reg or no save
						(hold_opcode == 8'h65) |    // adc 1 (no write into mem)   A dest
						(hold_opcode == 8'hE5) |	// sbc 1 (no write into mem)   A dest
						(hold_opcode == 8'h25) |	// and 1 (no write into mem)   A dest
						(hold_opcode == 8'hC5) |	// cmp 1 (no write into mem)   A dest
						(hold_opcode == 8'h45) |	// eor 1 (no write into mem)   A dest
						(hold_opcode == 8'h05) |	// ora 1 (no write into mem)   A dest
						(hold_opcode == 8'h24) |	// bit 1 (no write into mem)   A dest
						(hold_opcode == 8'hE4) |	// cpx 1 (no write into mem)
						(hold_opcode == 8'hC4) |	// cpy 1 (no write into mem)
						(hold_opcode == 8'hA5) |	// lda 1 (no write into mem)   alu_data_a = 0 
						(hold_opcode == 8'hA6) |	// ldx 1 (no write into mem)   alu_data_a = 0 
						(hold_opcode == 8'hA4) |	// ldy 1 (no write into mem)   alu_data_a = 0 
						//2)alu+mem => save into mem
						(hold_opcode == 8'hE6) |	// inc
						(hold_opcode == 8'h26) |	// rol
						(hold_opcode == 8'h66) |	// ror
						(hold_opcode == 8'hC6) |	// dec
						(hold_opcode == 8'h06) |	// asl
						(hold_opcode == 8'h46) |	// lsr
						//3)only save reg into mem
						(hold_opcode == 8'h85) |	// sta+
						(hold_opcode == 8'h86) |	// stx+
						(hold_opcode == 8'h84);		// sty+
						
wire 		cond_jxx =  (hold_opcode == 8'h90) |	// bcc
						(hold_opcode == 8'hB0) |	// bcs
						(hold_opcode == 8'hF0) |	// beq
						(hold_opcode == 8'h30) |	// bmi
						(hold_opcode == 8'hD0) |	// bne
						(hold_opcode == 8'h10) |	// bpl
						(hold_opcode == 8'h50) |	// bvc
						(hold_opcode == 8'h70);		// bvs
						
wire		cond_zp_x = (hold_opcode == 8'h75) |	//adc  (no write into mem)   A dest
						(hold_opcode == 8'h35) |	//and  (no write into mem)   A dest
						(hold_opcode == 8'hD5) |	//cmp  (no write into mem)   A dest
						(hold_opcode == 8'h55) |	//eor  (no write into mem)   A dest
						(hold_opcode == 8'h15) |	//ora  (no write into mem)   A dest
						(hold_opcode == 8'hF5) |	//sbc  (no write into mem)   A dest
						(hold_opcode == 8'hB5) |	//lda  (no write into mem)   A dest
						(hold_opcode == 8'hB4) |	//ldy  (no write into mem)   
						(hold_opcode == 8'h16) |    //asl
						(hold_opcode == 8'hD6) |	//dec
						(hold_opcode == 8'hF6) |	//inc
						(hold_opcode == 8'h56) |	//lsr
						(hold_opcode == 8'h36) |	//rol
						(hold_opcode == 8'h76) |	//ror
						(hold_opcode == 8'h95) |	//sta
						(hold_opcode == 8'h94);		//sty

wire		cond_zp_y = (hold_opcode == 8'hB6) |	//ldx  (no write into mem)   
						(hold_opcode == 8'h96);     //stx

wire 		cond_acc	 =(hold_opcode == 8'h0A) |	//asl
						  (hold_opcode == 8'h4A) |	//lsr
						  (hold_opcode == 8'h2A) |  //rol
						  (hold_opcode == 8'h6A);	//ror
						  
wire 		cond_abs_x	 =(hold_opcode == 8'h7D) |	//adc  (no write into mem)   A dest  4+
						  (hold_opcode == 8'h3D) |	//and  (no write into mem)   A dest  4+
						  (hold_opcode == 8'h5D) |	//eor  (no write into mem)   A dest  4+
						  (hold_opcode == 8'hDD) |  //cmp  (no write into mem)  A dest  4+
						  (hold_opcode == 8'hBD) |  //lda  (no write into mem)    A dest  4+
						  (hold_opcode == 8'h1D) |	//ora  (no write into mem)   A dest  4+
						  (hold_opcode == 8'hFD) |  //sbc  (no write into mem)   A dest  4+
						  (hold_opcode == 8'hBC) |  //ldy  (no write into mem)                4+  
						  (hold_opcode == 8'h1E) |  //asl
						  (hold_opcode == 8'hDE) |  //dec
						  (hold_opcode == 8'hFE) |	//inc
						  (hold_opcode == 8'h5E) |  //lsr	  
						  (hold_opcode == 8'h3E) |	//rol
						  (hold_opcode == 8'h7E) |  //ror
						  (hold_opcode == 8'h9D);	//sta				

wire 		cond_abs_y	 =(hold_opcode == 8'h79) |	//adc  no write into mem)   A dest  4+
						  (hold_opcode == 8'h39) |	//and  no write into mem)   A dest  4+
						  (hold_opcode == 8'h59) |  //eor  no write into mem)   A dest  4+
						  (hold_opcode == 8'hD9) |	//cmp no write into mem)   A dest  4+
						  (hold_opcode == 8'hB9) |  //lda  no write into mem)   A dest  4+
						  (hold_opcode == 8'h19) |  //ora  no write into mem)   A dest  4+
						  (hold_opcode == 8'hF9) |  //sbc no write into mem)   A dest  4+
						  (hold_opcode == 8'hBE) |	//ldx
						  (hold_opcode == 8'h99);	//sta			

wire 		cond_ind_x	 =(hold_opcode == 8'h61) |	//adc
						  (hold_opcode == 8'h21) |	//and
						  (hold_opcode == 8'hC1) |	//cmp
						  (hold_opcode == 8'h41) |	//eor
						  (hold_opcode == 8'hA1) |	//lda
						  (hold_opcode == 8'h01) |	//ora
						  (hold_opcode == 8'hE1) |	//sbc
						  (hold_opcode == 8'h81);	//sta
					
wire 		cond_ind_y	 =(hold_opcode == 8'h71) |	//adc
						  (hold_opcode == 8'h31) |	//and
						  (hold_opcode == 8'hD1) |	//cmp
						  (hold_opcode == 8'h51) |	//eor
						  (hold_opcode == 8'hB1) |	//lda
						  (hold_opcode == 8'h11) |	//ora
						  (hold_opcode == 8'hF1) |	//sbc
						  (hold_opcode == 8'h91);	//sta
										  
reg [5:0]sm_decode;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sm_decode<=INT0;
	else if(cpu_clock && rdy)begin
		case(sm_decode)
			DECODE:begin
				if(cond_some_int)					sm_decode<=INT0;
				else if(cond_immediate)				sm_decode<=ALU_IMM;
				else if(cond_abs || cond_abs_ind)	sm_decode<=ABS_ADDR0;
				else if(cond_zp)					sm_decode<=ZP_ADDR0;
				else if(cond_zp_x || cond_zp_y)		sm_decode<=ZP_XY_ADDR0;
				else if(cond_acc)					sm_decode<=ACCUM;
				else if(cond_impl_regs)				sm_decode<=IMPL_REGS;
				else if(cond_impl_flags)			sm_decode<=IMPL_FLAGS;
				else if(cond_return)				sm_decode<=RTN_COMMON0;
				else if(cond_push)					sm_decode<=PUSH0;
				else if(cond_pull)					sm_decode<=PULL0;
				else if(cond_jxx)					sm_decode<=JXX0;
				else if(cond_ind_x)					sm_decode<=IND_X_RDBYTE;
				else if(cond_ind_y)					sm_decode<=IND_Y_RDBYTE;
				else if(cond_abs_x || cond_abs_y)	sm_decode<=RD_ADDR_ABS_XY0;
				else 								sm_decode<=NOP;
			end
			INT0:			sm_decode<=INT1;
			INT1:			sm_decode<=INT2;
			INT2:			sm_decode<=INT3;
			INT3:			sm_decode<=INT4;
			INT4:			sm_decode<=INT5;
			INT5:			sm_decode<=DECODE;
			ALU_IMM:		sm_decode<=DECODE;
			ACCUM:			sm_decode<=DECODE;
			ABS_ADDR0:		sm_decode<=ABS_ADDR1;
			ABS_ADDR1:begin
				if( hold_opcode == 8'h4C )										sm_decode<=DECODE;      	//jmp abs+
				else if( hold_opcode == 8'h6C )									sm_decode<=ABS_IND0;		//jmp abs indirect+
				else if( hold_opcode[7:4] == 4'h8 )								sm_decode<=ALU_WR1;   		//sta,stx,sty+
				else if( hold_opcode[3:0] == 4'h0 )								sm_decode<=ABS_JSR0;  		//jsr+
				else if(hold_opcode[7:4] != 4'hA && hold_opcode[3:0] == 4'hE )	sm_decode<=ALU_SVMEM;
				else 															sm_decode<=ABS_RDATA;
			end
			ABS_IND0:		sm_decode<=ABS_IND1;
			ABS_IND1:		sm_decode<=DECODE;
			ABS_RDATA:		sm_decode<=DECODE;
			ALU_SVMEM:		sm_decode<=ALU_WR0;
			ALU_WR0:		sm_decode<=ALU_WR1;
			ALU_WR1:		sm_decode<=DECODE;
			ABS_JSR0:		sm_decode<=ABS_JSR1;
			ABS_JSR1:		sm_decode<=ABS_JSR2;
			ABS_JSR2:		sm_decode<=DECODE;
			ZP_XY_ADDR0:	sm_decode<=ZP_XY_ADDR1;
			ZP_XY_ADDR1:begin
				if(hold_opcode[7:4] == 4'h9)									sm_decode<=ALU_WR1;			 //sta,stx,sty
				else if(hold_opcode[7:4] != 4'h9 && 
						hold_opcode[7:4] != 4'hB && 
						hold_opcode[3:0] == 4'h6)								sm_decode<=ALU_SVMEM;
				else 															sm_decode<=ZP_RDATA;
			end
			ZP_ADDR0:begin
			   if(hold_opcode[7:4] == 4'h8)										sm_decode<=ALU_WR1;			 //sta,stx,sty
			   else if(hold_opcode[7:4] != 4'hA && hold_opcode[3:0] == 4'h6 )	sm_decode<=ALU_SVMEM;
			   else 															sm_decode<=ZP_RDATA;
			end		
			ZP_RDATA:		sm_decode<=DECODE;
			IMPL_REGS:		sm_decode<=DECODE;
			IMPL_FLAGS:		sm_decode<=DECODE;
			RTN_COMMON0:	sm_decode<=(hold_opcode[7:4] == 4'h4) ? RTN_I0 : RTN_S0;
			RTN_S0:			sm_decode<=RTN_S1;
			RTN_S1:			sm_decode<=RTN_S2;
			RTN_S2:			sm_decode<=RTN_COMMON1;
			RTN_I0:			sm_decode<=RTN_I1;
			RTN_I1:			sm_decode<=RTN_I2;
			RTN_I2:			sm_decode<=RTN_COMMON1;
			RTN_COMMON1:	sm_decode<=DECODE;
			PUSH0:			sm_decode<=PUSH1;
			PUSH1:			sm_decode<=DECODE;
			PULL0:			sm_decode<=PULL1;
			PULL1:			sm_decode<=PULL2;
			PULL2:			sm_decode<=DECODE;
			JXX0:begin
				if( (hold_opcode[7:4] == 4'h9 && !c_flag) ||   //bcc
					(hold_opcode[7:4] == 4'hB && c_flag)||     //bcs
					(hold_opcode[7:4] == 4'hF && z_flag) ||    //beq
					(hold_opcode[7:4] == 4'hD && !z_flag)||    //bne
					(hold_opcode[7:4] == 4'h3 && n_flag)||     //bmi
					(hold_opcode[7:4] == 4'h1 && !n_flag)||    //bpl
					(hold_opcode[7:4] == 4'h5 && !v_flag)||    //bvc
					(hold_opcode[7:4] == 4'h7 && v_flag))      //bvs
							sm_decode<=JXX1;
				else 
							sm_decode<=DECODE;
			end
			JXX1:begin
				if((hold_data_in[7] && !alu_co) || (!hold_data_in[7] && alu_co)) sm_decode<=JXX2;  //hold_data_in[7] equ -127
				else 		sm_decode<=DECODE;
			end
			JXX2:			sm_decode<=DECODE;
			IND_X_RDBYTE:	sm_decode<=IND_X_ADD_X;
			IND_X_ADD_X:	sm_decode<=IND_X_ADDR0;
			IND_X_ADDR0:	sm_decode<=IND_X_ADDR1;
			IND_X_ADDR1:begin
				if( hold_opcode[7:4] == 4'h8 )		sm_decode<=ALU_WR1;		    	//sta
				else 		sm_decode<=IND_XY_RDDATA;
			end
			IND_XY_RDDATA:	sm_decode<=DECODE;
			IND_Y_RDBYTE:	sm_decode<=IND_Y_ADDR0;
			IND_Y_ADDR0:	sm_decode<=IND_Y_ADDR1;
			IND_Y_ADDR1:begin
				if( alu_co || 
					hold_opcode[7:4] == 4'h9)		sm_decode<=IND_Y_C;  			//why? because sta,asr,shl,rol,ror,inc,dec has not add 1 clock with cross bound page(always has a max clock need)
				else 								sm_decode<=IND_XY_RDDATA;
			end
			IND_Y_C:begin
				if( hold_opcode[7:4] == 4'h9 )		sm_decode<=ALU_WR1;		    	//sta
				else 								sm_decode<=IND_XY_RDDATA;
			end
			
			RD_ADDR_ABS_XY0:sm_decode<=RD_ADDR_ABS_XY1;
			RD_ADDR_ABS_XY1:begin
				if( alu_co || hold_opcode[7:4] == 4'h9 ||
					(hold_opcode[7:4] != 4'hB && hold_opcode[3:0] == 4'hE) )	sm_decode<=ABS_XY0_C;
				else 								sm_decode<=ABS_XY0_RD_DATA;
			end
			ABS_XY0_C:begin
				if( hold_opcode[7:4] == 4'h9 )		sm_decode<=ALU_WR1;		    //sta
				else if(hold_opcode[7:4] != 4'hB && hold_opcode[3:0] == 4'hE)	sm_decode<=ALU_SVMEM;
				else 								sm_decode<=ABS_XY0_RD_DATA;
			end
			ABS_XY0_RD_DATA:						sm_decode<=DECODE;
			NOP:if(hold_opcode == 8'hEA)			sm_decode<=DECODE;
		endcase
	end
end	
//--------------------------------------------------------------------------------
////////////////////////////////ALU_IMM PARAMETERS SELECT/////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel0;
always@(posedge sysclk)begin
	if( sm_decode == ALU_IMM )begin
		if( hold_opcode[3:0] == 4'h9 && hold_opcode[7:4] != 4'hA )alu_data_a_sel0<=REG_A;
		else if( hold_opcode[7:4] == 4'hE )alu_data_a_sel0<=REG_X;
		else if( hold_opcode[7:4] == 4'hC )alu_data_a_sel0<=REG_Y;
		else alu_data_a_sel0<=0;													   //lda,ldx,ldy
	end
end

wire	[7:0]alu_data_b_sel0 = hold_data_in;

reg 	[3:0]alu_cmd_sel0;
always@(posedge sysclk)begin
	if( sm_decode == ALU_IMM )begin
		if( hold_opcode[7:4] == 4'hC || hold_opcode[7:4] == 4'hE )alu_cmd_sel0<=4'd1;   // [-]
		else if( hold_opcode[7:4] == 4'h2 )alu_cmd_sel0<=4'd3;  					    // [and]
		else if( hold_opcode[7:4] == 4'h4 )alu_cmd_sel0<=4'd4;  					    // [xor]
		else if( hold_opcode[7:4] == 4'h0 )alu_cmd_sel0<=4'd2;  					    // [ora]
		else alu_cmd_sel0<=4'd0;  					   								    // [+] (lda,ldx,ldy,etc)
	end
end

reg 	alu_ci_sel0;
always@(posedge sysclk)begin
	if( sm_decode == ALU_IMM )begin
		if( hold_opcode == 8'hE9 )				alu_ci_sel0<=~c_flag; 					//sbc get invert C flag
		else if ( hold_opcode[7:4] == 4'h6 )	alu_ci_sel0<=c_flag; 					//adc get C flag
		else 									alu_ci_sel0<=0;
	end
end
//--------------------------------------------------------------------------------
///////////////////////////////ALU_WR0 PARAMETERS SELECT//////////////////////////
//--------------------------------------------------------------------------------	

wire 	[7:0]alu_data_a_sel2 = hold_data_in;
reg 	[7:0]alu_data_b_sel2;
always@(posedge sysclk)begin
	if( sm_decode == ALU_WR0 )begin
		if( hold_opcode[7:4] == 4'hC || hold_opcode[7:4] == 4'hE ||
			hold_opcode[7:4] == 4'hF || hold_opcode[7:4] == 4'hD) 	alu_data_b_sel2 <= 8'h1;         //inc,dec  
		else 														alu_data_b_sel2 <= 0;
	end
end

reg 	[3:0]alu_cmd_sel2;
always@(posedge sysclk)begin
	if( sm_decode == ALU_WR0 || sm_decode == ACCUM) begin
		if(	hold_opcode[7:4] == 4'h0 ||
			hold_opcode[7:4] == 4'h1 )		alu_cmd_sel2 <= 4'd5;        //[lsl]
		else if(hold_opcode[7:4] == 4'h4 ||
				hold_opcode[7:4] == 4'h5 )	alu_cmd_sel2 <= 4'd6;        //[lsr]
		else if(hold_opcode[7:4] == 4'h2 ||
				hold_opcode[7:4] == 4'h3 )	alu_cmd_sel2 <= 4'd7;        //[rol]
		else if(hold_opcode[7:4] == 4'h6 ||
				hold_opcode[7:4] == 4'h7 )	alu_cmd_sel2 <= 4'd8;        //[ror]
		else if(hold_opcode[7:4] == 4'hE ||
				hold_opcode[7:4] == 4'hF )	alu_cmd_sel2 <= 4'd0;        //[inc]
		else if(hold_opcode[7:4] == 4'hC ||
				hold_opcode[7:4] == 4'hD )	alu_cmd_sel2 <= 4'd1;        //[dec]
		else 								alu_cmd_sel2 <= 4'd0; 
	end
end

reg 	alu_ci_sel2;
always@(posedge sysclk)begin
	if( sm_decode == ALU_WR0 )begin
		if( hold_opcode[7:4] == 4'hC || hold_opcode[7:4] == 4'hE ||
			hold_opcode[7:4] == 4'hF || hold_opcode[7:4] == 4'hD )	alu_ci_sel2 <= 0;//inc,dec without C flag
		else 														alu_ci_sel2 <= c_flag;
	end 
end
//--------------------------------------------------------------------------------
//////////////////////////ABS_RDATA PARAMETERS SELECT/////////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel1;
always@(posedge sysclk)begin
	if( sm_decode == ABS_RDATA )begin
		if ( hold_opcode[7:4] == 4'hA )alu_data_a_sel1 <= 0;		//lda,ldx,ldy 
		else if( hold_opcode == 8'hEC )alu_data_a_sel1 <= REG_X;
		else if( hold_opcode == 8'hCC )alu_data_a_sel1 <= REG_Y;
		else alu_data_a_sel1 <= REG_A;
	end
end	

wire 	[7:0]alu_data_b_sel1 = hold_data_in;
	
reg 	[3:0]alu_cmd_sel1;
always@(posedge sysclk)begin
	if(	sm_decode == ABS_RDATA || sm_decode == ZP_RDATA || 
		sm_decode == ABS_XY0_RD_DATA || sm_decode == IND_XY_RDDATA )begin
		if( hold_opcode[7:4] == 4'hE ||
			hold_opcode[7:4] == 4'hC ||
			hold_opcode[7:4] == 4'hF ||
			hold_opcode[7:4] == 4'hD )		alu_cmd_sel1 <= 4'd1;  //[-]
		else if( hold_opcode[7:4] == 4'h2 ||
			hold_opcode[7:4] == 4'h3 )		alu_cmd_sel1 <= 4'd3;  //[and]
		else if( hold_opcode[7:4] == 4'h0 ||
			hold_opcode[7:4] == 4'h1)		alu_cmd_sel1 <= 4'd2;  //[or]
		else if( hold_opcode[7:4] == 4'h4 ||
			hold_opcode[7:4] == 4'h5 )		alu_cmd_sel1 <= 4'd4;  //[xor]
		else 								alu_cmd_sel1 <= 4'd0; 		
	end
end

reg 	alu_ci_sel1;
always@(posedge sysclk)begin	
	if(	sm_decode == ABS_RDATA || sm_decode == ZP_RDATA || 
		sm_decode == ABS_XY0_RD_DATA || sm_decode == IND_XY_RDDATA )begin
		if( hold_opcode[7:4] == 4'h6 || 
			hold_opcode[7:4] == 4'h7 )
			alu_ci_sel1  <= c_flag;						//adc
		else if (
			hold_opcode == 8'hED || hold_opcode == 8'hE5 ||	hold_opcode == 8'hE1 ||
			hold_opcode == 8'hF1 || hold_opcode == 8'hF5 || hold_opcode == 8'hFD ||
			hold_opcode == 8'hF9 )
			alu_ci_sel1  <= ~c_flag;				   //sbc  
		else alu_ci_sel1 <= 0; 
	end	
end
//--------------------------------------------------------------------------------
//////////////////////////ZP_RDATA PARAMETERS SELECT/////////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel3;
always@(posedge sysclk)begin
	if( sm_decode == ZP_RDATA )begin
		if( hold_opcode[7:4] == 4'hA || hold_opcode[7:4] == 4'hB)alu_data_a_sel3 <= 0; //lda,ldx,ldy   
		else if( hold_opcode == 8'hE4 || hold_opcode == 8'hA6 || hold_opcode == 8'hB6 )alu_data_a_sel3 <= REG_X;
		else if( hold_opcode == 8'hC4 || hold_opcode == 8'hA4 || hold_opcode == 8'hB4 )alu_data_a_sel3 <= REG_Y;
		else alu_data_a_sel3 <= REG_A;
	end
end	
wire 	[7:0]alu_data_b_sel3 	= 	hold_data_in;
wire  	[3:0]alu_cmd_sel3	 	=	alu_cmd_sel1;
wire  	alu_ci_sel3		 		= 	alu_ci_sel1;
//--------------------------------------------------------------------------------
/////////////////////////////ACCUM PARAMETERS SELECT//////////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel4 	= 	REG_A;
wire 	[7:0]alu_data_b_sel4 	= 	8'h0;
wire  	[3:0]alu_cmd_sel4	 	=	alu_cmd_sel2;
wire  	alu_ci_sel4		 		= 	c_flag; 
//--------------------------------------------------------------------------------
//////////////////////////IMPL_REGS PARAMETERS SELECT/////////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel5;
always@(posedge sysclk)begin
	if( sm_decode == IMPL_REGS )begin
		if( hold_opcode[7:4] == 4'hB )alu_data_a_sel5 <= REG_SP;
		else if(hold_opcode[7:4] == 4'hA)alu_data_a_sel5 <= REG_A;
		else if( hold_opcode[7:4] == 4'hE || hold_opcode[3:0] == 4'hA )alu_data_a_sel5 <= REG_X;
		else alu_data_a_sel5 <= REG_Y; 
	end
end	

reg 	[7:0]alu_data_b_sel5;
always@(posedge sysclk)begin
	if( sm_decode == IMPL_REGS )begin
		if( hold_opcode == 8'hCA ||   //  dex
			hold_opcode == 8'h88 ||   //  dey	
			hold_opcode == 8'hE8 ||   //  inx
			hold_opcode == 8'hC8)     //  iny
									alu_data_b_sel5 = 8'h1;  	 
			else 					alu_data_b_sel5 = 0;
	end
end	

reg 	[3:0]alu_cmd_sel5;
always@(posedge sysclk)begin
	if(	sm_decode == IMPL_REGS )begin
		if(	hold_opcode[7:4] == 4'h8 ||
			hold_opcode == 8'hCA )	alu_cmd_sel5 = 4'd1;   			//[-]
		else 						alu_cmd_sel5 = 4'd0;
	end
end		

wire  	alu_ci_sel5	 			= 	0; 
//--------------------------------------------------------------------------------
/////////////////////////////JXX1 PARAMETERS SELECT///////////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel6 	= 	REG_PC[7:0];
wire 	[7:0]alu_data_b_sel6 	= 	hold_data_in;
wire  	[3:0]alu_cmd_sel6	 	=	4'd0;
wire  	alu_ci_sel6		 		= 	0; 
//--------------------------------------------------------------------------------
/////////////////////////////JXX2 PARAMETERS SELECT///////////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel7 	= 	REG_PC[15:8];

reg 	[7:0]alu_data_b_sel7;
always@(posedge sysclk)begin
	if( sm_decode == JXX2 )begin
		if(hold_data_in[7])	alu_data_b_sel7 = 8'hFF;       
		else 				alu_data_b_sel7 = 8'h0; 
	end
end

wire  	[3:0]alu_cmd_sel7	 	=	4'd0;

reg  	alu_ci_sel7;
always@(posedge sysclk)begin
	if( rdy && cpu_clock)
		if( sm_decode == JXX1 )alu_ci_sel7<=alu_co;  //trick(save alu_co from last state)
end
//--------------------------------------------------------------------------------
////////////////////////IND_XY_RDDATA PARAMETERS SELECT///////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel8;
always@(posedge sysclk)begin
	if( sm_decode == IND_XY_RDDATA )begin
		if( hold_opcode[7:4] == 4'hA || hold_opcode[7:4] == 4'hB)	alu_data_a_sel8 <= 0; //lda,ldx,ldy   
		else 														alu_data_a_sel8 <= REG_A;
	end
end	

wire 	[7:0]alu_data_b_sel8 	= 	hold_data_in;
wire  	[3:0]alu_cmd_sel8	 	=	alu_cmd_sel1;
wire  	alu_ci_sel8		 		= 	alu_ci_sel1;
//--------------------------------------------------------------------------------
/////////////////////////IND_Y_ADDR1 PARAMETERS SELECT////////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel9	=	hold_data_in;
wire 	[7:0]alu_data_b_sel9 	= 	REG_Y;
wire  	[3:0]alu_cmd_sel9	 	=	4'd0;
wire  	alu_ci_sel9		 		= 	0;
//--------------------------------------------------------------------------------
//////////////////////IND_Y_C,ABS_XY0_C PARAMETERS SELECT/////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel10	=	abs_addr[15:8];
wire 	[7:0]alu_data_b_sel10 	= 	8'd0;
wire  	[3:0]alu_cmd_sel10	 	=	4'd0;
reg  	alu_ci_sel10;
always@(posedge sysclk)begin
	if( rdy && cpu_clock)
		if( sm_decode == RD_ADDR_ABS_XY1 ||
			sm_decode == IND_Y_ADDR1)alu_ci_sel10<=alu_co;  //trick(save alu_co from last state)
end
//--------------------------------------------------------------------------------
///////////////////////RD_ADDR_ABS_XY1 PARAMETERS SELECT//////////////////////////
//--------------------------------------------------------------------------------
wire 	[7:0]alu_data_a_sel11	=	abs_addr[7:0];
reg 	[7:0]alu_data_b_sel11;
always@(posedge sysclk)begin
	if( sm_decode == RD_ADDR_ABS_XY1 )begin
		if(hold_opcode[3:0] == 4'h9 || hold_opcode == 8'hBE)alu_data_b_sel11 <= REG_Y;
		else alu_data_b_sel11 <= REG_X;
	end
end	
wire  	[3:0]alu_cmd_sel11	 	=	4'd0;
wire  	alu_ci_sel11			=   0;
//--------------------------------------------------------------------------------
///////////////////////ABS_XY0_RD_DATA PARAMETERS SELECT//////////////////////////
//--------------------------------------------------------------------------------
reg 	[7:0]alu_data_a_sel12;
always@(posedge sysclk)begin
	if( sm_decode == ABS_XY0_RD_DATA )begin
		if( hold_opcode[7:4] == 4'hB )alu_data_a_sel12 <= 0; //lda,ldx,ldy   
		else alu_data_a_sel12 <= REG_A;
	end
end
wire  	[7:0]alu_data_b_sel12	=	hold_data_in;
wire  	[3:0]alu_cmd_sel12	 	=	alu_cmd_sel1;
wire  	alu_ci_sel12			=   alu_ci_sel1;

//--------------------------------------------------------------------------------
//////////////////////////SELECT ALU PARAMETERS///////////////////////////////////
//--------------------------------------------------------------------------------
reg [7:0]alu_data_a;
always@* begin
	case(sm_decode)
		ALU_IMM:			alu_data_a = alu_data_a_sel0;
		ABS_RDATA:			alu_data_a = alu_data_a_sel1;	
		ALU_WR0:			alu_data_a = alu_data_a_sel2;
		ZP_RDATA:			alu_data_a = alu_data_a_sel3;
		ACCUM:				alu_data_a = alu_data_a_sel4;
		IMPL_REGS:			alu_data_a = alu_data_a_sel5;
		JXX1:				alu_data_a = alu_data_a_sel6;
		JXX2:				alu_data_a = alu_data_a_sel7;
		IND_XY_RDDATA:		alu_data_a = alu_data_a_sel8;
		IND_Y_ADDR1:		alu_data_a = alu_data_a_sel9;
		IND_Y_C,
		ABS_XY0_C:			alu_data_a = alu_data_a_sel10;
		RD_ADDR_ABS_XY1:	alu_data_a = alu_data_a_sel11;
		ABS_XY0_RD_DATA:	alu_data_a = alu_data_a_sel12;
		default:			alu_data_a = 8'd0;
	endcase
end

reg [7:0]alu_data_b;
always@* begin
	case(sm_decode)
		ALU_IMM:			alu_data_b = alu_data_b_sel0;
		ABS_RDATA:			alu_data_b = alu_data_b_sel1;
		ALU_WR0:			alu_data_b = alu_data_b_sel2;
		ZP_RDATA:			alu_data_b = alu_data_b_sel3;
		ACCUM:				alu_data_b = alu_data_b_sel4;
		IMPL_REGS:			alu_data_b = alu_data_b_sel5;
		JXX1:				alu_data_b = alu_data_b_sel6;
		JXX2:				alu_data_b = alu_data_b_sel7;
		IND_XY_RDDATA:		alu_data_b = alu_data_b_sel8;
		IND_Y_ADDR1:		alu_data_b = alu_data_b_sel9;
		IND_Y_C,
		ABS_XY0_C:			alu_data_b = alu_data_b_sel10;
		RD_ADDR_ABS_XY1:	alu_data_b = alu_data_b_sel11;
		ABS_XY0_RD_DATA:	alu_data_b = alu_data_b_sel12;
		default:			alu_data_b = 8'd0;
	endcase
end

reg [3:0]alu_cmd;
always@* begin
	case(sm_decode)
		ALU_IMM:			alu_cmd = alu_cmd_sel0;
		ABS_RDATA:			alu_cmd = alu_cmd_sel1;
		ALU_WR0:			alu_cmd = alu_cmd_sel2;
		ZP_RDATA:			alu_cmd = alu_cmd_sel3;
		ACCUM:				alu_cmd = alu_cmd_sel4;
		IMPL_REGS:			alu_cmd = alu_cmd_sel5;
		JXX1:				alu_cmd = alu_cmd_sel6;
		JXX2:				alu_cmd = alu_cmd_sel7;
		IND_XY_RDDATA:		alu_cmd = alu_cmd_sel8;
		IND_Y_ADDR1:		alu_cmd = alu_cmd_sel9;
		IND_Y_C,
		ABS_XY0_C:			alu_cmd = alu_cmd_sel10;
		RD_ADDR_ABS_XY1:	alu_cmd = alu_cmd_sel11;
		ABS_XY0_RD_DATA:	alu_cmd = alu_cmd_sel12;
		default:			alu_cmd = 4'd0;
	endcase
end

reg alu_ci;
always@* begin
	case(sm_decode)
		ALU_IMM:			alu_ci = alu_ci_sel0;
		ABS_RDATA:			alu_ci = alu_ci_sel1;
		ALU_WR0:			alu_ci = alu_ci_sel2;
		ZP_RDATA:			alu_ci = alu_ci_sel3;
		ACCUM:				alu_ci = alu_ci_sel4;
		IMPL_REGS:			alu_ci = alu_ci_sel5;
		JXX1:				alu_ci = alu_ci_sel6;
		JXX2:				alu_ci = alu_ci_sel7;
		IND_XY_RDDATA:		alu_ci = alu_ci_sel8;
		IND_Y_ADDR1:		alu_ci = alu_ci_sel9;
		IND_Y_C,
		ABS_XY0_C:			alu_ci = alu_ci_sel10;
		RD_ADDR_ABS_XY1:	alu_ci = alu_ci_sel11;
		ABS_XY0_RD_DATA:	alu_ci = alu_ci_sel12;
		default:			alu_ci = 0;
	endcase
end
//--------------------------------------------------------------------------------	
wire alu_no,alu_zo,alu_co,alu_vo;
wire [7:0]alu_result;
alu	m_alu(
		.cmd(alu_cmd),
		.ci(alu_ci),
		.data_a(alu_data_a),
		.data_b(alu_data_b),
		.result(alu_result),
		.no(alu_no),
		.zo(alu_zo),
		.co(alu_co),
		.vo(alu_vo)
		);
//--------------------------------------------------------------------------------
reg [7:0]hold_alu_result;
always@(posedge sysclk)if(sm_decode == ALU_WR0 && cpu_clock)hold_alu_result<=alu_result;		
//--------------------------------------------------------------------------------
wire [15:0]abs_addr_inc 	= abs_addr+1'd1;
wire [7:0]abs_addr_inc_low 	= abs_addr[7:0]+1'd1;
wire [7:0]abs_addr_zpxy  	= abs_addr[7:0] + ((hold_opcode == 8'hB6 | hold_opcode == 8'h96) ? REG_Y : REG_X);
wire [7:0]abs_addr_indx 	= abs_addr[7:0]+ REG_X;
//absolute addr
reg [15:0]abs_addr;
always@(posedge sysclk)begin
	if(rdy && cpu_clock)begin
		case(sm_decode)
			INT3,
			ABS_ADDR0,
			ZP_XY_ADDR0:	abs_addr[7:0]<=data_in;
			ZP_XY_ADDR1:	abs_addr<={8'b0,abs_addr_zpxy};
			INT4,
			ABS_ADDR1:		abs_addr[15:8]<=data_in;
			ABS_IND0:		abs_addr[7:0]<=abs_addr_inc_low;
			ZP_ADDR0:		abs_addr<={8'h0,data_in};
			RTN_S0:			abs_addr[7:0]<=data_in;
			RTN_S1:			abs_addr[15:8]<=data_in;
			RTN_S2:			abs_addr<=abs_addr_inc;
			RTN_I1:			abs_addr[7:0]<=data_in;
			RTN_I2:			abs_addr[15:8]<=data_in;
			IND_X_RDBYTE:	abs_addr<={8'h0,data_in};
			IND_X_ADD_X:	abs_addr<={8'b0,abs_addr_indx};
			IND_X_ADDR0:	abs_addr[7:0]<=abs_addr_inc_low;
			IND_X_ADDR1:	abs_addr<={data_in,hold_data_in};
			IND_Y_RDBYTE:	abs_addr<={8'h0,data_in};
			IND_Y_ADDR0:	abs_addr[7:0]<=abs_addr_inc_low;
			IND_Y_ADDR1:	abs_addr<={data_in,alu_result};
			IND_Y_C:		abs_addr[15:8]<=alu_result;
			ABS_XY0_C:		abs_addr[15:8]<=alu_result;
			RD_ADDR_ABS_XY0:abs_addr[7:0]<=data_in;
			RD_ADDR_ABS_XY1:begin
				abs_addr[7:0]<=alu_result;
				abs_addr[15:8]<=data_in;
			end
		endcase
	end
end		
//--------------------------------------------------------------------------------
//control address bus
reg [15:0]addr_bus;
always@* begin
	case(sm_decode)
		INT0,
		INT1,
		INT2,
		ABS_JSR0,
		ABS_JSR1,
		RTN_S0,
		RTN_S1,
		RTN_I0,
		RTN_I1,
		RTN_I2,
		PUSH0,
		PULL1:			addr_bus = {8'h01,REG_SP}; 
		ABS_IND0,
		ABS_IND1,
		ALU_WR0,
		ALU_WR1,
		ALU_SVMEM,
		ABS_RDATA,
		ZP_RDATA,
		IND_X_ADDR0,
		IND_X_ADDR1,
		IND_XY_RDDATA,
		ABS_XY0_RD_DATA,
		IND_Y_ADDR0,
		IND_Y_ADDR1,
		IND_Y_C:		addr_bus = abs_addr;
		default:		addr_bus = REG_PC;
	endcase
end
//--------------------------------------------------------------------------------
//control r/w
reg rw;
always@* begin
	case(sm_decode)
		INT0,
		INT1,
		INT2,
		ALU_WR1,
		ABS_JSR0,
		ABS_JSR1,
		PUSH0:  	rw = 1'b1;
		default:	rw = 0;
	endcase
end
//--------------------------------------------------------------------------------
//control data_out
reg [7:0]data_out;
always@* begin
	case(sm_decode)
		INT0,
		ABS_JSR0:  		data_out = REG_PC[15:8];
		INT1,
		ABS_JSR1:  		data_out = REG_PC[7:0];	
		INT2:			data_out = {n_flag,v_flag,1'b0,b_flag,d_flag,i_flag,z_flag,c_flag};
		ALU_WR1: begin
			if(hold_opcode[7:4] == 4'h8 || hold_opcode[7:4] == 4'h9 ) begin  //sta,stx,sty
				if( hold_opcode[3:0] == 4'hC || hold_opcode[3:0] == 4'h4 ) 		data_out = REG_Y;
				else if( hold_opcode[3:0] == 4'hE || hold_opcode[3:0] == 4'h6 )	data_out = REG_X;
				else 	data_out = REG_A;
			end
			else		data_out = hold_alu_result;
		end
		PUSH0: 	   		data_out = ( hold_opcode[7:4] == 4'h4 ) ? REG_A : {n_flag,v_flag,1'b1,1'b1,d_flag,i_flag,z_flag,c_flag};//flags  nv11dizc
		default:		data_out = 0;
	endcase
end
//--------------------------------------------------------------------------------
//control programm counter
wire [15:0]PC_INC  = REG_PC+1'd1;
reg [15:0]REG_PC = 0;  //for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			DECODE:if(!cond_some_int)				REG_PC<=PC_INC;
			INT2:begin
				if(int_sel == 0)					REG_PC<=16'hFFFC;	   		//reset
				else if(int_sel == 2'd1)			REG_PC<=16'hFFFA;   		//nmi
				else 								REG_PC<=16'hFFFE;			//irq
			end
			INT3:									REG_PC<=PC_INC;
			INT5:									REG_PC<=abs_addr;
			ALU_IMM:								REG_PC<=PC_INC;	
			ABS_ADDR0:								REG_PC<=PC_INC;	
			ABS_ADDR1:begin
				if( hold_opcode == 8'h4C ) 			REG_PC<={data_in,abs_addr[7:0]};
				else if( hold_opcode[3:0] != 0 )	REG_PC<=PC_INC;				//no jsr
			end
			ABS_IND0:								REG_PC[7:0]<=data_in;
			ABS_IND1:								REG_PC[15:8]<=data_in;
			ABS_JSR2:								REG_PC<=abs_addr;
			ZP_XY_ADDR0,
			ZP_ADDR0:								REG_PC<=PC_INC;		
			RTN_COMMON1:							REG_PC<=abs_addr;		
			JXX0:									REG_PC<=PC_INC;	
			JXX1:									REG_PC[7:0]<=alu_result;
			JXX2:									REG_PC[15:8]<=alu_result;
			IND_X_RDBYTE:							REG_PC<=PC_INC;
			IND_Y_RDBYTE:							REG_PC<=PC_INC;
			RD_ADDR_ABS_XY0:						REG_PC<=PC_INC;
			RD_ADDR_ABS_XY1:						REG_PC<=PC_INC;
		endcase
	end
end
//--------------------------------------------------------------------------------
//control stack pointer
wire 	[7:0]SP_INC = reset ? REG_SP+1'd1 : REG_SP;
wire 	[7:0]SP_DEC = reset ? REG_SP-1'd1 : REG_SP;  
reg 	[7:0]REG_SP = 8'hFF;
always@(posedge sysclk) begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			INT0,
			INT1,
			INT2,
			ABS_JSR0,
			ABS_JSR1:						REG_SP <= SP_DEC;
			IMPL_REGS:begin
				if(hold_opcode == 8'h9A)	REG_SP <= REG_X;   	 				//txs
			end
			RTN_COMMON0:					REG_SP <= SP_INC;
			RTN_S0:							REG_SP <= SP_INC;
			RTN_I0,
			RTN_I1:							REG_SP <= SP_INC;	
			PUSH1:							REG_SP <= SP_DEC;
			PULL0:							REG_SP <= SP_INC;	
		endcase
	end
end
//--------------------------------------------------------------------------------
reg 	[7:0]REG_A = 0; //for debug
always@(posedge sysclk)begin
	if( cpu_clock && rdy )begin
		case(sm_decode)
			ALU_IMM:begin
				if( hold_opcode[7:4] != 4'hC && 
					hold_opcode[3:0] == 4'h9 )							REG_A<=alu_result;
			end
			ABS_RDATA:begin
				if( hold_opcode[3:0] == 4'hD && 
					hold_opcode[7:4] != 4'hC )							REG_A<=alu_result;
			end
			ZP_RDATA:begin
				if( hold_opcode[3:0] == 4'h5 && 
					hold_opcode[7:4] != 4'hC && 
					hold_opcode[7:4] != 4'hD )							REG_A<=alu_result;
			end
			ACCUM: 														REG_A<=alu_result;
			IMPL_REGS:begin
				if( hold_opcode == 8'h8A ||		//txa
					hold_opcode == 8'h98 )		//tya
																		REG_A<=alu_result; 
			end
			PULL1:if( hold_opcode[7:4] == 4'h6 )						REG_A<=data_in;				//pull A
			IND_XY_RDDATA:begin
				if( hold_opcode[7:4] != 4'hC &&  //cmp
					hold_opcode[7:4] != 4'hD )   //cmp
																		REG_A<=alu_result;
			end
			ABS_XY0_RD_DATA:begin
				if( (hold_opcode[3:0] == 4'hD || hold_opcode[3:0] == 4'h9 ) && 
					hold_opcode[7:4] != 4'hD  )							REG_A<=alu_result;
			end															
		endcase
	end
end
//--------------------------------------------------------------------------------
reg 	[7:0]REG_X = 0;// for debug
always@(posedge sysclk)begin
	if( cpu_clock && rdy )begin
		case(sm_decode)
			ALU_IMM:if( hold_opcode == 8'hA2 )							REG_X<=alu_result;
			ABS_RDATA:if( hold_opcode == 8'hAE )						REG_X<=alu_result;
			ZP_RDATA:if( hold_opcode == 8'hA6 || hold_opcode == 8'hB6 )	REG_X<=alu_result;
			IMPL_REGS:begin
				if( hold_opcode == 8'hBA || 	//tsx
					hold_opcode == 8'hAA ||		//tax
					hold_opcode == 8'hCA ||		//dex
					hold_opcode == 8'hE8 )		//inx
																		REG_X<=alu_result;
			end
			ABS_XY0_RD_DATA:if( hold_opcode[3:0] == 4'hE )				REG_X<=alu_result;
		endcase
	end
end
//--------------------------------------------------------------------------------
reg 	[7:0]REG_Y = 0; //for debug
always@(posedge sysclk)begin
	if( cpu_clock && rdy )begin
		case(sm_decode)
			ALU_IMM:if( hold_opcode == 8'hA0 )							REG_Y<=alu_result;
			ABS_RDATA:if( hold_opcode == 8'hAC )						REG_Y<=alu_result;
			ZP_RDATA:if( hold_opcode == 8'hA4 || hold_opcode == 8'hB4 )	REG_Y<=alu_result;
			IMPL_REGS:begin
				if(	hold_opcode == 8'hA8 ||		//tay
					hold_opcode == 8'h88 ||		//dey
					hold_opcode == 8'hC8)		//iny
																		REG_Y<=alu_result;
			end
			ABS_XY0_RD_DATA:if( hold_opcode[3:0] == 4'hC )				REG_Y<=alu_result;
		endcase
	end
end
//--------------------------------------------------------------------------------
//n flag
reg	n_flag = 0;	//for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			ALU_IMM:							n_flag<=alu_no;
			ABS_RDATA:begin
				if( hold_opcode == 8'h2C )		n_flag<=hold_data_in[7]; //bit
				else 							n_flag<=alu_no;
			end
			ALU_WR0,
			ACCUM:								n_flag<=alu_no;
			ZP_RDATA:begin
				if( hold_opcode == 8'h24 )		n_flag<=hold_data_in[7]; //bit
				else 							n_flag<=alu_no;
			end
			IMPL_REGS:if( hold_opcode != 8'h9A )n_flag<=alu_no;
			RTN_I0:								n_flag<=data_in[7];	
			PULL1:								n_flag<=data_in[7];	
			IND_XY_RDDATA:						n_flag<=alu_no;
			ABS_XY0_RD_DATA:					n_flag<=alu_no;
		endcase
	end
end
//--------------------------------------------------------------------------------
//v  flag 
reg v_flag = 0;  //for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			ALU_IMM:if( hold_opcode == 8'hE9 || hold_opcode == 8'h69)		v_flag<=alu_vo;  //only for adc/sbc
			ABS_RDATA:begin
				if(hold_opcode == 8'h6D || hold_opcode == 8'hED)			v_flag<=alu_vo;  //only for adc/sbc
				else if( hold_opcode == 8'h2C )								v_flag<=hold_data_in[6]; //bit
			end
			ZP_RDATA:begin
				if( ((hold_opcode[7:4] == 4'h6 || hold_opcode[7:4] == 4'hE) && hold_opcode[3:0] == 4'h5) || //adc/sbc zero page
					  hold_opcode[7:4] == 4'h7 || hold_opcode[7:4] == 4'hF )								//adc/sbc zero page x
																			v_flag<=alu_vo; 		 //only for adc/sbc
				else if( hold_opcode == 8'h24 )								v_flag<=hold_data_in[6]; //bit
			end
			IMPL_FLAGS:begin
				if(hold_opcode[7:4] == 4'hB)								v_flag<=0;	//clv
			end
			RTN_I0:															v_flag<=data_in[6];
			PULL1:if( hold_opcode[7:4] == 4'h2 )							v_flag<=data_in[6];	
			IND_XY_RDDATA:begin
				if( hold_opcode[7:4] == 4'hE || hold_opcode[7:4] == 4'hF ||
					hold_opcode[7:4] == 4'h6 || hold_opcode[7:4] == 4'h7 )	v_flag<=alu_vo;  //only for adc/sbc
			end
			ABS_XY0_RD_DATA:begin
				if(	hold_opcode == 8'h7D || hold_opcode == 8'h79 ||
					hold_opcode == 8'hFD || hold_opcode == 8'hF9 )			v_flag<=alu_vo;  //only for adc/sbc
				end
		endcase
	end
end	
//--------------------------------------------------------------------------------
//b  flag
wire b_flag = (hold_opcode == 8'h00);
//--------------------------------------------------------------------------------
//d  flag
reg d_flag = 0;  //for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			IMPL_FLAGS:begin
				if(hold_opcode[7:4] == 4'hF)		d_flag<=1;					//sed
				else if(hold_opcode[7:4] == 4'hD)	d_flag<=0;					//cld
			end
			RTN_I0:									d_flag<=data_in[3];
			PULL1:if( hold_opcode[7:4] == 4'h2 )	d_flag<=data_in[3];			//pull flags
		endcase
	end
end

//--------------------------------------------------------------------------------
//i  flag
reg i_flag = 0; //for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			IMPL_FLAGS:begin
				if(hold_opcode[7:4] == 4'h7)		i_flag<=1;						//sei
				else if(hold_opcode[7:4] == 4'h5)	i_flag<=0;						//cli
			end
			RTN_I0:									i_flag<=data_in[2];
			PULL1:if( hold_opcode[7:4] == 4'h2 )	i_flag<=data_in[2];   			//pull flags
		endcase
	end
end
//--------------------------------------------------------------------------------
//z  flag
reg z_flag = 0; //for debug
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			ALU_IMM:								z_flag<=alu_zo;
			ABS_RDATA:								z_flag<=alu_zo;
			ALU_WR0,
			ACCUM:									z_flag<=alu_zo;
			ZP_RDATA:								z_flag<=alu_zo;
			IMPL_REGS:if( hold_opcode != 8'h9A )	z_flag<=alu_zo;
			RTN_I0:									z_flag<=data_in[1];
			
			PULL1:begin
				if( hold_opcode[7:4] == 4'h6 )		z_flag<=(~|data_in); 		//pull A 
				else 								z_flag<=data_in[1]; 		//pull flags
			end
			IND_XY_RDDATA:							z_flag<=alu_zo; 
			ABS_XY0_RD_DATA:						z_flag<=alu_zo;	
		endcase
	end
	
end
//--------------------------------------------------------------------------------
//c  flag
reg c_flag = 0;
always@(posedge sysclk)begin
	if(cpu_clock && rdy)begin
		case(sm_decode)
			ALU_IMM:begin
				if( hold_opcode[7:4] == 4'hE || hold_opcode[7:4] == 4'hC )		c_flag<=~alu_co;					//only for sbc + cmp
				else if( hold_opcode[7:4] == 4'h6 )								c_flag<=alu_co;		
			end
			ABS_RDATA:begin
				if( hold_opcode[7:4] == 4'hE || hold_opcode[7:4] == 4'hC )		c_flag<=~alu_co;					//only for sbc + cmp
				else if( hold_opcode[7:4] == 4'h6)								c_flag<=alu_co;
			end
			ALU_WR0:begin
				if( hold_opcode[7:4] != 4'hC && hold_opcode[7:4] != 4'hE &&
					hold_opcode[7:4] != 4'hF && hold_opcode[7:4] != 4'hD )		c_flag<=alu_co;   					//inc/dec without c
			end
			ACCUM:																c_flag<=alu_co; 
			ZP_RDATA:begin
				if( hold_opcode[7:4] == 4'hE || hold_opcode[7:4] == 4'hC || 
					hold_opcode[7:4] == 4'hD || hold_opcode[7:4] == 4'hF )		c_flag<=~alu_co;   					//only for sbc + cmp			
				else if( hold_opcode[7:4] == 4'h6 ||  hold_opcode[7:4] == 4'h7)	c_flag<=alu_co; 	
			end
			IMPL_FLAGS:begin
				if( hold_opcode[7:4] == 4'h3 )									c_flag<=1;  						//sec
				else if( hold_opcode[7:4] == 4'h1 )								c_flag<=0; 							//clc
			end
			RTN_I0:																c_flag<=data_in[0];
			PULL1:if( hold_opcode[7:4] == 4'h2 )								c_flag<=data_in[0];					//pull flags
			IND_XY_RDDATA:begin
				if( hold_opcode[7:4] == 4'hE || hold_opcode[7:4] == 4'hF || 
					hold_opcode[7:4] == 4'hC || hold_opcode[7:4] == 4'hD )		c_flag<=~alu_co;					//only for sbc + cmp			
				else if( hold_opcode[7:4] == 4'h6 ||  hold_opcode[7:4] == 4'h7)	c_flag<=alu_co; 	
			end
			ABS_XY0_RD_DATA:begin
				if( hold_opcode[7:4] == 8'hF || hold_opcode[7:4] == 4'hD )		c_flag<=~alu_co;					//only for sbc + cmp			
				else if( hold_opcode[7:4] == 4'h7 )								c_flag<=alu_co; 				
			end
		endcase
	end
end
//--------------------------------------------------------------------------------
reg [7:0]hold_opcode;
always@(posedge sysclk)begin
	if(sm_decode == DECODE && rdy)	hold_opcode<=data_in;
end
//--------------------------------------------------------------------------------
reg [7:0]hold_data_in;
always@(posedge sysclk)begin
	if( rdy && 
		(	sm_decode == ALU_IMM || sm_decode == IND_XY_RDDATA ||
			sm_decode == ABS_RDATA || sm_decode == ZP_RDATA || 
			sm_decode == ABS_XY0_RD_DATA || sm_decode == JXX0 ||
			sm_decode == IND_X_ADDR0 || sm_decode == IND_Y_ADDR0 ||
			sm_decode == ALU_SVMEM ))	hold_data_in<=data_in;
		  
		
end
//--------------------------------------------------------------------------------
reg [1:0]int_sel;
always@(posedge sysclk or negedge reset)begin
	if(!reset)int_sel<=2'd0;
	else if(sm_decode == DECODE && rdy && cpu_clock)begin
		if(hold_nmi || hold_opcode == 8'h00)int_sel<=2'd1;
		else if(hold_irq)int_sel<=2'd2;
	end
end
//--------------------------------------------------------------------------------
reg old_nmi;
always@(posedge sysclk)old_nmi<=~nmi;
//--------------------------------------------------------------------------------
reg hold_nmi;
always@(posedge sysclk or negedge reset)begin
	if(!reset)hold_nmi<=0;
	else if(!hold_nmi)hold_nmi<=!old_nmi & !nmi;
	else if(sm_decode == DECODE && rdy && cpu_clock)hold_nmi<=0;
end
//--------------------------------------------------------------------------------
reg old_irq;
always@(posedge sysclk)old_irq<=~irq;
//--------------------------------------------------------------------------------
reg hold_irq;
always@(posedge sysclk or negedge reset)begin
	if(!reset)hold_irq<=0;
	else if(!hold_irq)hold_irq<=!old_irq & !irq;
	else if(sm_decode == DECODE && rdy && cpu_clock)hold_irq<=0;
end
endmodule