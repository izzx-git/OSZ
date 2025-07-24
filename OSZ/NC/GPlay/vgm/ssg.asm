SSG_REG = 0xfffd
SSG_DAT = 0xbffd

	macro ssg_write_reg chip_n
;e = register
;d = value
	ld bc,SSG_REG
	ld a,chip_n+%11111110
	out (c),a
	out (c),e
	ld bc,SSG_DAT
	out (c),d
	endm

ssgwritemusiconlychip0
	ld a,e
	cp 0x0e
	ret nc
ssgwrite0
;e = register
;d = value
	ssg_write_reg 0
	ret

ssgwritemusiconlychip1
	ld a,e
	cp 0x0e
	ret nc
ssgwrite1
;e = register
;d = value
	ssg_write_reg 1
	ret

ssginit
	ret

	macro ssg_write_regs
;e = base register
;d = value
;l = count
.loop
	call ssgwrite0
	call ssgwrite1
	inc e
	dec l
	jr nz,.loop
	endm

ssgmute
	ld l,3
	ld de,8
	ssg_write_regs
	ld l,14
	ld de,0
	ssg_write_regs
	ret
