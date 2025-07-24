;Define ENABLE_FM to enable FM DACs

OPN_REG = 0xfffd
OPN_DAT = 0xbffd


        ifdef ENABLE_FM
CHIP0 = %11111000
CHIP1 = %11111001
        else
CHIP0 = %11111100
CHIP1 = %11111101
        endif


;------------------------------------
opnwriteall
	call opnwritefm2
;------------------------------------
opnwritefm1:
	;opn_write_fm_reg 0
      	ld a,CHIP0
opnwritefmx:
;a = chipselect
;e = register
;d = value
	ld bc,OPN_REG
	out (c),a

1
	nop:nop
;        nop:nop:nop
	in f,(c)
	jp m, 1b ;$-6

	out (c),e

2
  	nop:nop
;        nop:nop:nop
	in f,(c)
	jp m,2b   ;$-6

	ld b,HIGH OPN_DAT
	out (c),d

.extradelay ;additional delay for FPGA systems
	ld b,8
	djnz $
	ret
;------------------------------------
opnwritefm2:
       	ld a,CHIP1
        jp opnwritefmx
;------------------------------------


opndisableextradelay
	ld a,0xc9 ;ret opcode
	ld (opnwritefmx.extradelay),a
	ret


	macro opn_write_fm_regs incr,incd
;e = base register
;d = value
;l = count
.loop	call opnwriteall
	IF incr
	inc e
	ENDIF
	IF incd
	inc d
	ENDIF
	dec l
	jr nz,.loop
	endm



opninit
	ld l,0xb4
	ld de,0x0000
	opn_write_fm_regs 1,0
;configure prescaler
	ld de,0x002f
	call opnwriteall
	ld de,0x002d
	jp opnwriteall

opnstoptimers
	ld de,0x3027
	call opnwriteall
	ld de,0x0027
	jp opnwriteall

opnmute
	call opnstoptimers
;mute SSG
	ld l,3
	ld de,0x0008
	opn_write_fm_regs 1,0
	ld l,14
	ld de,0x0000
	opn_write_fm_regs 1,0
;max release rate
	ld l,0x10
	ld de,0x0f80
	opn_write_fm_regs 1,0
;min total level
	ld l,0x10
	ld de,0x7f40
	opn_write_fm_regs 1,0
;key off
	ld l,0x04
	ld de,0x0028
	opn_write_fm_regs 0,1
;default tfm state
	ld bc,OPN_REG
	ld a,%11111111
	out (c),a
	ret
