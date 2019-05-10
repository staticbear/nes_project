; Startup code for cc65 and Shiru's NES library
; based on code by Groepaz/Hitmen <groepaz@gmx.net>, Ullrich von Bassewitz <uz@cc65.org>


FT_DPCM_OFF				= $c000		;$c000..$ffc0, 64-byte steps
FT_SFX_STREAMS			= 4			;number of sound effects played at once, 1..4

.define FT_DPCM_ENABLE  0			;undefine to exclude all DMC code
.define FT_SFX_ENABLE   1			;undefine to exclude all sound effects code



    .export __STARTUP__:absolute=1
	;.export _gl_position
	.import initlib,push0,popa,popax,_main,zerobss,copydata
	.import _my_nmi
; Linker generated symbols
	.import __RAM_START__   ,__RAM_SIZE__
	.import __ROM0_START__  ,__ROM0_SIZE__
	.import __STARTUP_LOAD__,__STARTUP_RUN__,__STARTUP_SIZE__
	.import	__CODE_LOAD__   ,__CODE_RUN__   ,__CODE_SIZE__
	.import	__RODATA_LOAD__ ,__RODATA_RUN__ ,__RODATA_SIZE__
	.import NES_MAPPER,NES_PRG_BANKS,NES_CHR_BANKS,NES_MIRRORING
    .include "zeropage.inc"



FT_BASE_ADR		=$0100	;page in RAM, should be $xx00

.define FT_THREAD       1	;undefine if you call sound effects in the same thread as sound update
.define FT_PAL_SUPPORT	1   ;undefine to exclude PAL support
.define FT_NTSC_SUPPORT	1   ;undefine to exclude NTSC support


PPU_CTRL	=$2000
PPU_MASK	=$2001
PPU_STATUS	=$2002
PPU_OAM_ADDR=$2003
PPU_OAM_DATA=$2004
PPU_SCROLL	=$2005
PPU_ADDR	=$2006
PPU_DATA	=$2007
PPU_OAM_DMA	=$4014
DMC_FREQ	=$4010
CTRL_PORT1	=$4016
CTRL_PORT2	=$4017

OAM_BUF		=$0200
PAL_BUF		=$01c0



.segment "ZEROPAGE"





.segment "HEADER"

    .byte $4e,$45,$53,$1a
	.byte <NES_PRG_BANKS
	.byte <NES_CHR_BANKS
	.byte <NES_MIRRORING|(<NES_MAPPER<<4)
	.byte <NES_MAPPER&$f0
	.res 8,0



.segment "CODE"

start:
	jmp _main			;no parameters
	
nmi:
	php
	pha
	txa
	pha
	tya
	pha
	jsr _my_nmi
	pla
	tay
	pla
	tax
	pla
	plp
irq:
    rti

.segment "CARTRIGE"

	.incbin	"game_list.bin"

.segment "SAMPLES"
	

.segment "VECTORS"

    .word nmi	;$fffa vblank nmi
    .word start	;$fffc reset
   	.word irq	;$fffe irq / brk


.segment "CHARS"

	.incbin "tileset.chr"
