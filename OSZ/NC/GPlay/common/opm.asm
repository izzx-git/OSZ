;Having chip 0 is mandatory for the player to detect YM2151,
;chip 1 is an optional second chip.

OPM0_REG = 0xf0c1 ;write: chip 0 address
OPM0_DAT = 0xf1c1 ;write: chip 0 value, read: chip 0 status
OPM1_REG = 0xf2c1 ;write: chip 1 address
OPM1_DAT = 0xf3c1 ;write: chip 1 value, read: chip 1 status

	macro opm_write_reg reg,dat
;bc = data port
;e = register
;d = value
	ld bc,dat
	in f,(c)
	jp m,$-2
	ld bc,reg
	out (c),e
	ld bc,dat
	in f,(c)
	jp m,$-2
	out (c),d
	endm

opmwriteall
;e = register
;d = value
	call opmwritechip1
opmwritechip0
;e = register
;d = value
	opm_write_reg OPM0_REG,OPM0_DAT
	ret

opmwritechip1
;e = register
;d = value
	opm_write_reg OPM1_REG,OPM1_DAT
	ret

opmdisablechip1
	ld a,0xc9 ;ret opcode
	ld (opmwritechip1),a
	ret

	macro opm_write_regs incr,incd
;e = base register
;d = value
;l = count
.loop	call opmwriteall
	IF incr
	inc e
	ENDIF
	IF incd
	inc d
	ENDIF
	dec l
	jr nz,.loop
	endm

opminit
	ld l,0
	ld de,0
	opm_write_regs 1,0
	ret

opmstoptimers
	ld de,0x3014
	call opmwriteall
	ld de,0x0014
	jp opmwriteall

opmmute
	call opmstoptimers
;max release rate
	ld l,0x20
	ld de,0x0fe0
	opm_write_regs 1,0
;min total level
	ld l,0x20
	ld de,0x7f60
	opm_write_regs 1,0
;key off
	ld l,0x08
	ld de,0x0008
	opm_write_regs 0,1
	ret
