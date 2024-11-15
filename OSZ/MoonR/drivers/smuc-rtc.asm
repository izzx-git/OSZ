;clock driver SMUC
	module Clock
; вых.:	CY=1, если микросхемы CMOS нет
	; C — секунды/число; (удалено)
	; B - минуты/месяц;
	; E - часы/год;

readTime
	ld bc,#DFBA
	ld a,4 ;часы
	call out3d2f
	ld a,10 ;пауза
readTimeCL
	dec a
	jr nz,readTimeCL
	call in3d2f
	cp 255 ;проверка наличия микросхемы
	scf
	ret z
	ld e,a
	ld a,2 ;минуты
	call out3d2f
	ld a,10 ;пауза
readTimeCL2
	dec a
	jr nz,readTimeCL2
	call in3d2f
	ld b,a
	or a
    ret
	
in3d2f
	ld hl,#3ff3
	push hl
	jp #3d2f
	
out3d2f
	ld hl,#2A53
	push hl
	jp #3d2f

	
    endmodule
