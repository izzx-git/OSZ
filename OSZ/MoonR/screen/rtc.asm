printRTC	
	ifndef SMUCRTC
	ret
	endif
	ifdef SMUCRTC
	;печать текущего времени
	call Clock.readTime
	jr nc,read_time_ok
	; ld hl,mes_no_RTC
	; call print_mes
	; scf
	ret ;выход	
read_time_ok
	push bc
	ld l,e ;часы
	ld h,0
	call toDecimal
	ld de,00 ;координаты
	call TextMode.gotoXY
	ld hl,decimalS+3
	call TextMode.printZ
	ld a,":"
	call TextMode.putC
	pop bc
	ld l,b ;минуты
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call TextMode.printZ
	; ld a,":"
	; call TextMode.putC
	; ld l,c ;секунды
	; ld h,0
	; call toDecimal
	; ld hl,decimalS+3
	; call TextMode.printZ
	; or a ;нет ошибки
	ret

	
toDecimal		;конвертирует 2 байта в 5 десятичных цифр
				;на входе в HL число
			ld de,10000 ;десятки тысяч
			ld a,255
toDecimal10k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal10k
			add hl,de
			add a,48
			ld (decimalS),a
			ld de,1000 ;тысячи
			ld a,255
toDecimal1k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal1k
			add hl,de
			add a,48
			ld (decimalS+1),a
			ld de,100 ;сотни
			ld a,255
toDecimal01k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal01k
			add hl,de
			add a,48
			ld (decimalS+2),a
			ld de,10 ;десятки
			ld a,255
toDecimal001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal001k
			add hl,de
			add a,48
			ld (decimalS+3),a
			ld de,1 ;единицы
			ld a,255
toDecimal0001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal0001k
			add hl,de
			add a,48
			ld (decimalS+4),a		
			
			ret
	
decimalS	ds 6 ;десятичные цифры
	
	endif