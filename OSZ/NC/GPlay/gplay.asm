;GPlay - приложение для OS GMX
   ; device ZXSPECTRUM128
	; include "../os_defs.asm"  
	; org PROG_START	
	

start_gplay	
	ld de,0
	OS_SET_XY
	ld hl,msg_title ;имя приложения
	OS_PRINTZ ;печать
	
	ld a,13 ;оставим место для шкалы прогресса
	OS_PRINT_CHARF
	ld a,13
	OS_PRINT_CHARF
	ld hl,file_name_cur
	OS_PRINTZ	
	
	ld hl,txt_load
	OS_PRINTZ	
	
	ld a,255
	ld (file_id_cur_r),a
	
	call load_mus ;инициализация VGM
	jp c,exit_gplay
	
	ld hl,txt_play
	OS_PRINTZ
	
	ld hl,txt_gplay_menu
	OS_PRINTZ
	
wait_play 
	OS_WAIT
	
	call gplay_progress_print

	ld de,#0a00
	OS_SET_XY
	ld hl,(memorystreamcurrentaddr)
	call toDecimal
	OS_PRINTZ
	

	ld de,#0b00
	OS_SET_XY
	ld hl,(memorystreampageaddr)
	ld bc,memorystreampages
	and a
	sbc hl,bc
	call toDecimal
	OS_PRINTZ
	
	ld a,(vgm_play_var)
	or a
	jr nz,exit_gplay ; конец пенсни
	OS_GET_CHAR
	cp " " ;space
	jp z,exit_gplay
	cp "s" ;stop
	jp z,exit_gplay
	cp "S" ;stop
	jp z,exit_gplay
	cp 24 ;break
	jp z,exit_gplay
	jr wait_play
	
	
exit_gplay ;выход 
	push af ;сохранить нажатую клавишу

	ld hl,txt_exit
	OS_PRINTZ
	
	ld hl,0 ;отключить обработчик прерываний
	OS_SET_INTER
	call PLR_MUTE ;выключить звук
	
	
	;освободить страницы памяти
	ld hl,memorystreampages+$FF
    ld l,(hl)
free_s98_loop
    dec l
    ld a,(hl)

    push af
    push hl
    ;OS_DELPAGE
	OS_DEL_PAGE
    pop hl
    pop af
                
    jr nz,free_s98_loop
                                
	; call delay ;задержка	
	; xor a
	; OS_PROC_CLOSE
	pop af ;a - код клавиши
	ret
	
; delay ;задержка между запросами
	; ld b,50*1 ;
; delay1
	; OS_WAIT
	; djnz delay1
	; ret

	
	;печать шкалы прогресса
gplay_progress_print
	call gplay_progress_calc
	ld de,#0200 ;прогресс тут
	OS_SET_XY
	;печать закрашенных кубиков
	ld a,(gplay_progress_val)
	or a
	jr z,gplay_progress_print1
	ld b,a
gplay_progress_print1_cl
	push bc
	ld a,177 ;псевдографика
	OS_PRINT_CHARF	
	pop bc
	djnz gplay_progress_print1_cl
gplay_progress_print1
	;печать пустых кубиков
	ld a,(gplay_progress_val)
	ld c,a
	ld a,gplay_progress_lenght
	sub c
	jr z,gplay_progress_print2
	ld b,a
gplay_progress_print1_c2
	push bc
	ld a,176 ;псевдографика
	OS_PRINT_CHARF	
	pop bc
	djnz gplay_progress_print1_c2
	
gplay_progress_print2
	ret
	
	
gplay_progress_calc
	ld a,(memorystreampages+255) ;всего страниц памяти занято
	ld h,a
	ld l,0 ;всего страниц *256 
	
	;разделить
	srl h ; младший бит придёт на флаг C , на старший бит придёт 0
	rr l ; младший бит придёт на флаг C, на старший флаг C
	srl h ; /4
	rr l ; 
	srl h ; /8
	rr l ; 
	srl h ; /16
	rr l ; 
	; srl h ; /32
	; rr l ; 
	;узнали сколько страниц одно деление
	ex de,hl
	
	
	ld hl,(memorystreampageaddr)
	ld bc,memorystreampages
	and a
	sbc hl,bc ;какая по счёту страница сейчас
	
	ld h,l ;*256
	ld l,0
	
	;разделить на величину одного деления
	ld a,-1
divide16
	inc a
	and a
	sbc hl,de
	jr nc,divide16
	add hl,de
	ld (gplay_progress_val),a
	ret
	
gplay_progress_lenght equ 16 ;длина шкалы	
gplay_progress_val db 0;


	
	
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
			ld hl,decimalS
			ret
	
decimalS	ds 6 ;десятичные цифры
	
	
	

;file_id_cur db 0; временно

txt_gplay_menu db 13,13,"Break, S - stop ",13,"Sp - Next",0
txt_play db 13,"Play... ",0
txt_exit db 13,"Stop",0
txt_load db 13,"Load...",0
txt_memoryerror:    db 13,"Memory allocation error!",0
txt_fopenerror:     db 13,"Cannot open file: ",0
	
msg_title
	db "GPlay ver 2025.07.31",10,13,0
	
vgm_plr

;module equ 0xc000
;player_load = 0x8000 ;0x4000

;ovl_start = 0x8000 ;0x4000

PLR_INIT  = vgm_plr ;0x4000
PLR_PLAY  = vgm_plr+5 ;0x4005
PLR_MUTE  = vgm_plr+8 ;0x4008

	include vgm_plr.asm
	include sub_func.asm
	;include common/muldiv.asm
	
end_gplay

;ниже не включается в файл
;waveheaderbuffer equ 0xc000-2048=0xb800 ;


	;savebin "gplay.apg",start_gplay,$-start_gplay