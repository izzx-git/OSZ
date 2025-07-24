opmwritemusiconlychip0
;e = register
;d = value
	ld a,e
	cp 8
	ret c
	jp opmwritechip0

opmwritemusiconlychip1
;e = register
;d = value
	ld a,e
	cp 8
	ret c
	jp opmwritechip1

vgmopminit
	ld a,2
	ld (opmwaittimer100hz.counter),a
	jp opminit

opmwaittimer100hz
.counter=$+1
	ld a,0
	dec a
	jr nz,$+4
	ld a,2
	ld (.counter),a
	ret z
	;YIELD
	OS_WAIT
	ret
