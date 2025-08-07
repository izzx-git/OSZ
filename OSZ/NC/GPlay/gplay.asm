;GPlay - приложение для OS GMX
   ; device ZXSPECTRUM128
	; include "../os_defs.asm"  
	; org PROG_START	
	

start_gplay	
	push af
	
	call clear_left_panel ;почистить часть экрана
	
	;call release_key
	
	ld hl,memorystreampages+$FF
	ld (hl),0 ;количество занятых страниц
	
	ld a,(page_ext01) ;доп страница для данных плеера
	OS_SET_PAGE_SLOT3
	
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
	
	pop af
	
	cp "m"
	jr nz,start_gplay_vgz
	;если MOD
	call load_mod
	jp exit_gplay

	
start_gplay_vgz	
	cp "z"
	jr nz,start_gplay_vgm
	;если VGZ
	call load_vgz
	jp c,exit_gplay
	jr start_gplay_ok
	
start_gplay_vgm	
	;если vgm
	call load_mus ;инициализация VGM
	jp c,exit_gplay
	
start_gplay_ok
	;играет
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

	ld hl,txt_stop
	OS_PRINTZ
	
	ld hl,0 ;отключить обработчик прерываний
	OS_SET_INTER
	call PLR_MUTE ;выключить звук
	
	
	;освободить страницы памяти
	ld hl,memorystreampages+$FF
    ld l,(hl)
	inc l ;проверка на 0
	dec l
	jr z,free_s98_loop_skip
	
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
	
free_s98_loop_skip                           
	; call delay ;задержка	
	; xor a
	; OS_PROC_CLOSE
	
	ld a,(page_main) ;основная страница
	OS_SET_PAGE_SLOT3
	
	pop af ;a - код клавиши
	ret
	
; delay ;задержка между запросами
	; ld b,50*1 ;
; delay1
	; OS_WAIT
	; djnz delay1
	; ret









load_vgz 
;тут запуск VGZ
	;тут надо сначала распаковать файл
	xor a
	OS_SET_MONO_MODE ;запросить моно режим
	jr nc,load_vgz1
	
load_vgz_err
	;выход с ошибкой

	;напечатать ошибку, если не дали режима моно
	ld hl,msg_mono_err
	OS_PRINTZ
	
	scf ;ошибка
	ret
	
load_vgz1
	;перенести модуль распаковки на рабочий адрес
	ld hl,start_gp_gzip_tmp
	ld de,start_gp_gzip
	ld bc,end_gp_gzip_tmp-start_gp_gzip_tmp
	ldir
	

	;распаковать
	ld hl,file_name_cur ;имя файла
	call start_gp_gzip ;decompressfiletomemorystream
	
	;перенести таблицу страниц
	ld de,memorystreampages
	ld bc,256
	ldir

	ld bc,memorystreampages+$ff
    ld (bc),a  ;количество страниц		
	
	push af
	ld a,255
	OS_SET_MONO_MODE ;выключить моно режим
	pop af
	
	jr nc,load_vgz_ok 
	;если не распаковалос
	scf ;ошибка
	ret
	
load_vgz_ok
	;нормально распаковалось
	
	call read_file_ok ;играть
	;call start_gplay ;играть
	
	xor a
	ret






load_mod
;загрузка и игра mod

	;определение наличия GS
	; xor a ;флаг что не нашли
	; ld (gs_yep),a
	; ld (gs_on),a
	LD A,#23
	OUT (CMD), A 
	ld b,50
WAITCOM2: ;это WC
	OS_WAIT
	IN A,(CMD)
	RRCA
	JR NC,WAITCOM3
	djnz WAITCOM2
gs_no
	ld hl,txt_no_GS
	OS_PRINTZ
	scf ;ошибка
	ret
	;jr gs_no
WAITCOM3	
	in a,(DATA) ;количество страниц памяти?
	cp 255 
	jr nz,gs_yes
	; ld hl,txt_err_GS
	; call loader_print
	jr gs_no
gs_yes	



    xor a : call GeneralSound.init
    ; ld hl, .progress : call DialogBox.msgNoWait
    ; call makeRequest : jp c, Fetcher.fetchFromNet.error
    call GeneralSound.loadModule
	
	ld hl,file_name_cur
	OS_FILE_OPEN ;HL - File name (out: A - id file, bc, de - size, IX - fcb)

	jp c,loadMod_fileopenerror	
	ld (file_id_cur_r),a
	
loadMod_loop
    ;ld hl, buffer_cat, ;(buffer_pointer), hl
    ; call Wifi.getPacket
    ; ld a, (Wifi.closed) : and a : jr nz, .exit
    ; ld hl, buffer_cat, bc, (Wifi.bytes_avail)
	
		ld a,(file_id_cur_r)			
		ld hl,buffer_cat
        ld de,$4000
		OS_FILE_READ ;HL - address, A - id file, DE - length (out: hl - следующий адрес дл¤ чтени¤)
		jp c,loadMod_fileopenerror	
		
        ld a,h
		cp $c0
        jr c,loadLoop_4000    ;>= $c0, значит остаток файла	
		;остаток
		ld bc,#c000
		and a
		sbc hl,bc
		ld bc,hl
		ld hl,buffer_cat
.loadLoop2
    ld a, b : or c : and a : jr z, loadMod_exit
    ld a, (hl) : call GeneralSound.sendByte
    dec bc
    inc hl
    jr .loadLoop2
	jp loadMod_exit
	
	
loadLoop_4000
	ld hl,buffer_cat
	ld bc,$4000 ;большой кусок для загрузки
	
.loadLoop
    ld a, b : or c : and a : jp z, .nextFrame
    ld a, (hl) : call GeneralSound.sendByte
    dec bc
    inc hl
    jr .loadLoop
.nextFrame
    ;call Wifi.continue
    jp loadMod_loop
loadMod_exit
    call GeneralSound.finishLoadingModule
	
	ld a,(file_id_cur_r)
	OS_FILE_CLOSE ;A - id file
    ;jp History.back
	jp play ;MediaProcessor.processResource
;.progress db "MOD downloading directly to GS!", 0
	
    macro GS_WaitCommand2
.wait
    in a, (CMD)
    rrca
    jr c, .wait
    endm

    macro GS_SendCommand2 nn
    ld a, nn : out (CMD), a
    endm
	
play:

	ld hl,txt_play
	OS_PRINTZ
	
    ld hl,txt_gplay_menu
	OS_PRINTZ
	
    ; call Console.waitForKeyUp

    ; ld hl, Gopher.requestbuffer : call DialogBox.msgNoWait

    ; ;ld a, 1, (Render.play_next), a 
	xor a
	ld (last_song_position),a

.loop
    OS_WAIT : 
    OS_GET_CHAR
	cp " " ;пробел
	jp z, .stopKey
	cp "s" ;стоп
	jp z, .stopKey
	cp "S" ;чтоп
	jp z, .stopKey
	;call printRTC
    ;проверка что MOD начал играть сначала
    GS_SendCommand2 CMD_GET_SONG_POSITION
    GS_WaitCommand2
	ld a,(last_song_position) ;предыдущая позиция
	ld c,a
	in a,(DATA) ;текущая позиция
	ld (last_song_position),a
	cp c
	jr nc, .loop ;если не меньше, продолжаем играть
    ;ld a, 1, (Render.play_next), a ;флаг что надо будет играть следующий файл
.stop
	push af
    call GeneralSound.stopModule
	pop af
    ;call Console.waitForKeyUp
    ret
.stopKey
    ;xor a : ld (Render.play_next), a ;флаг что не надо играть следующий файл
    jr .stop


;message db "Press key to stop...", 0


CMD_GET_SONG_POSITION     = #60	
last_song_position db 0

;; Control ports
CMD  = 187
DATA = 179

buffer_pointer dw 0;


loadMod_fileopenerror
		ld hl,txt_fopenerror
		OS_PRINTZ
		
		ld a,(file_id_cur_r)
		cp 255
		jr z,loadMod_fileopenerror1
		OS_FILE_CLOSE ;A - id file
loadMod_fileopenerror1
		scf ;ошибка
		ret



	
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
txt_stop db 13,"Stop",0
txt_load db 13,"Load...",0
txt_no_GS db 13,"GS not found!",0
txt_memoryerror:    db 13,"Memory allocation error!",0
txt_fopenerror:     db 13,"Cannot open file: ",0
	
msg_title
	db "GPlay ver 2025.08.07",10,13,0
	
vgm_plr

;module equ 0xc000
;player_load = 0x8000 ;0x4000

;ovl_start = 0x8000 ;0x4000

PLR_INIT  = vgm_plr ;0x4000
PLR_PLAY  = vgm_plr+5 ;0x4005
PLR_MUTE  = vgm_plr+8 ;0x4008

	include vgm.asm
	include sub_func.asm
	include common/general-sound.asm
	;include common/muldiv.asm
	
end_gplay

	
	
;ниже не включается в файл
;waveheaderbuffer equ 0xc000-2048=0xb800 ;


	;savebin "gplay.apg",start_gplay,$-start_gplay