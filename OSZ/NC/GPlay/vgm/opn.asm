opniscontrolregister
;a = register
;out: zf=1 if it's control register, zf=0 otherwise
	cp 0x0e ;IO port
	ret z
	cp 0x0f ;IO port 
	ret z
	cp 0x2d ;prescaler
	ret z
	cp 0x2e ;prescaler
	ret z
	cp 0x2f ;prescaler
	ret

opnwritemusiconlyfm1
;skips writes to control registers
;e = register
;d = value
	ld a,e
	call opniscontrolregister
	ret z
	cp 0x27 ;timers control
	jp nz,opnwritefm1
	ld a,d
	ld (opntimerctrl),a
	or %00001010 ;avoid altering timer B
	ld d,a
	jp opnwritefm1

opnwritemusiconlyfm2
;skips writes to control registers
;e = register
;d = value
	ld a,e
	call opniscontrolregister
	ret z
	jp opnwritefm2

opninittimer60hz
;	ld de,0xc626
;	ld de,0xca26
	ld de,0xcd26
	call opnwritefm1
	ld de,0x2a27
	jp opnwritefm1

opnwaittimer60hz
	ld bc,OPN_REG
	ld a,%11111000
	out (c),a
.waitloop
	in a,(c)
	and 2
	jr z,.waitloop
	ld de,0x2a27
opntimerctrl=$+1
	ld a,0
	or d
	ld d,a
	jp opnwritefm1
