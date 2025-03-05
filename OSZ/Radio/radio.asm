;Radio - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROGSTART	
	
;порядок работы:
;открытие соединения
;проверка результата
;отправка запроса
;проверка результата
;принять ответ
;проверка результата
;принять ещё пакеты, если есть, до закрытия соединения, или до получения ожидаемой длины
;закрыть соединение
;при каждой возможности (в паузах) закрывать соединение, чтобы уступить очередь другим приложениям.
	
start_radio
	; ld a,13 ;новая строка
	; OS_PRINT_CHARF	
	ld hl,msg_title_radio ;имя приложения
	OS_PRINTZ ;печать


; radio_get_link	
	; ld hl,msg_get_link_id
	; OS_PRINTZ ;печать

	; xor a ;CY=0
	; OS_ESP_LINK_ID ;получить номер соединения
	; jr nc,radio_get_link_ok
	
	; call radio_main_error
	; jr radio_get_link
	
; radio_get_link_ok ;ID получили
	; ld (link_id),a 
	
start_radio_warm		
	ld hl,start_request ;очистить номер первого трека
	ld de,start_request+1
	ld bc,5-1
	ld (hl),"0"
	ldir
	
	ld hl,format_pt3 ;формат 
	ld de,request_format
	ld bc,3
	ldir
	
	;настроить плеер
	ld a,%00100001 ;pt3 auto
	ld (player_setup),a
	
	ld a,r
	ld (seed+1),a ;элемент случайности
	
radio_main
;основной цикл
	; OS_GET_CHAR
	; cp "r"
	; jp z,start_radio ;всё сначала
	; cp "R"
	; jp z,start_radio ;всё сначала
	
	; call radio_open_site ;открыть сайт
	
	; jr nc,radio_main_open_ok
	; call radio_main_error
	; jr radio_main
	
radio_main_open_ok
;открыли нормально
	OS_GET_CHAR
	cp "r"
	jp z,start_radio ;всё сначала
	cp "R"
	jp z,start_radio ;всё сначала
	cp 24 ;break
	jp z,exit
	

	call radio_request_info ;запрос информации
	
	jr nc,radio_request_info_ok
	call radio_main_error
	jr radio_main_open_ok
	

	
	
radio_request_info_ok
;запрос прошёл
	OS_GET_CHAR
	cp "r"
	jp z,start_radio ;всё сначала
	cp "R"
	jp z,start_radio ;всё сначала
	cp 24 ;break
	jp z,exit
	
	call radio_download_info ;загрузка информации
	
	jr nc,radio_download_info_ok
	call radio_main_error
	jr radio_main_open_ok




radio_download_info_ok
;загрузка инфы прошла



;теперь выбранный трек

	OS_GET_CHAR
	cp "r"
	jp z,start_radio ;всё сначала
	cp "R"
	jp z,start_radio ;всё сначала
	cp 24 ;break
	jp z,exit
	
	call radio_request_track ;запрос трека
	
	jr nc,radio_request_track_ok
	call radio_main_error
	jr radio_download_info_ok

radio_request_track_ok
;загрузка инфы о треке прошла
	OS_GET_CHAR
	cp "r"
	jp z,start_radio ;всё сначала
	cp "R"
	jp z,start_radio ;всё сначала
	cp 24 ;break
	jp z,exit
	
	call radio_download_track ;загрузка трека
	
	jr nc,radio_download_track_ok
	call radio_main_error
	jr radio_download_info_ok

radio_download_track_ok

	
	;начать игру
	ld (start_track),hl
	;ld hl, outputBuffer  : 
	OS_GET_VTPL_SETUP
	ld a,(player_setup)
	ld (hl),a ;настройки
	
	ld hl,(start_track)
	OS_VTPL_INIT
	OS_VTPL_PLAY
	
	ld hl,msg_play_track
	OS_PRINTZ
	call print_sys_info ;печать менюшки
	
	
loop_radio
	OS_WAIT
	OS_GET_CHAR
	cp "r"
	jp z,restart ;всё сначала
	cp "R"
	jp z,restart ;всё сначала
	cp "s" ;останов
	jp z, .stopKey
	cp "S" ;останов
	jp z, .stopKey
	; cp "n" ;следующий случайный
	; jp z, next_track_rnd
	cp " " ;слудующий случайный
	jp z, next_track_rnd
	cp "1" ;формат
	jp z, select_pt2
	cp "2" ;формат
	jp z, select_pt3
	; cp "3" ;формат
	; jp z, select_ts
	; cp "4" ;формат
	; jp z, select_tfc
	cp 24 ;break
	jp z,exit
	OS_GET_VTPL_SETUP
    ld a, (hl) : 
	rla : jr nc, loop_radio
	jp next_track_rnd
.stopKey
	OS_VTPL_MUTE
	ld hl,msg_stop
	OS_PRINTZ
	jr loop_radio
; loop_radio2
	; jr loop_radio2	

restart
	OS_VTPL_MUTE
	ld hl,msg_restart
	OS_PRINTZ
	jp start_radio_warm
	
exit ;выход в ДОС
	xor a
	OS_PROC_CLOSE

	
;следующий трек
next_track_rnd
	;получить случайный номер трека 
	; nop
	; nop
	OS_VTPL_MUTE
	ld hl,(total_track)
	call rnd
	;подставить номер
	call toDecimal
	;ld (start_track),hl
	ld hl,decimalS
	ld de,start_request
	ld bc,5
	ldir
	jp radio_main ;на загрузку нового трека
	
select_pt2 ;выбор типа 
	OS_VTPL_MUTE
	ld hl,format_pt2
	call select_format_print
	ld de,request_format
	ld bc,3
	ldir
	;настроить плеер
	ld a,%00000011 ;pt2
	ld (player_setup),a
	jp loop_radio
	
select_pt3 ;выбор типа 
	OS_VTPL_MUTE
	ld hl,format_pt3
	call select_format_print
	ld de,request_format
	ld bc,3
	ldir
	;настроить плеер
	ld a,%00100001 ;pt3
	ld (player_setup),a
	jp loop_radio
	
; select_ts ;выбор типа 
	; OS_VTPL_MUTE
	; ld hl,format_ts
	; call select_format_print
	; ld de,request_format
	; ld bc,3
	; ldir
	; OS_GET_VTPL_SETUP ;настроить плеер
	; ld a,%00100001 ;%00010001 ;2xPT3
	; ld (hl),a
	; jp loop_radio
	
; select_tfc ;выбор типа 
	; OS_VTPL_MUTE
	; ld hl,format_tfc
	; call select_format_print
	; ld de,request_format
	; ld bc,3
	; ldir
	; jp loop_radio
	
select_format_print
	push hl
	ld hl,msg_format
	OS_PRINTZ
	pop hl
	push hl
	OS_PRINTZ
	ld a,13
	OS_PRINT_CHARF
	pop hl
	ret
	
	
radio_main_error ;печать ошибка
	;какая-то ошибка
	ld a,2 ;цвет
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_error
	OS_PRINTZ	
	ld a,7 ;цвет
	ld b,#c
	OS_SET_COLOR
	call delay ;задержка	
	ret
	
radio_open_site ;открыть сайт
	OS_ESP_CLOSE ;на всякий случай сначала закрыть
	ld hl,msg_open ;печать инфы
	OS_PRINTZ	
	ld hl,site_name
	OS_PRINTZ
	ld a,13 ;новая строка
	OS_PRINT_CHARF	
	ld hl,site_name ;сайт
	ld de,port_number
	;call Wifi.openTCP ;открыть сайт
	xor a ;открыть TCP
	OS_ESP_OPEN
	ret c ;сразу не удалось (может, очередь)
	;или подождём открытия
	ld b,wait_count ;
radio_open_site_wait
	OS_WAIT
	ld a,(ix+2) ;флаг
	rlca
	ret c ;если ошибка (=255)
	or a ;если флаг !=0
	ret nz
	djnz radio_open_site_wait
	scf ;ощибка
	ret


	


radio_request_info ;запрос инфы
	call radio_open_site ;открыть сайт
	ret c

	ld hl,msg_request_info ;
	OS_PRINTZ	
	ld de,requestbuffer	
	call strLen ;узнать длину
	ex de,hl
	ld hl,requestbuffer	
	;call Wifi.tcpSendZ ;послать запрос
	OS_ESP_SEND 
	ret c;сразу не удалось (может, очередь)
	;ждём когда запрос пройдёт
	ld b,wait_count ;
radio_request_info_wait2
	OS_WAIT
	ld a,(ix+4) ;флаг
	rlca
	ret c ;если ошибка (=255)
	or a
	ret nz
	djnz radio_request_info_wait2
	scf ;ощибка
	ret


radio_download_info ;загрузить инфо

	ld hl,msg_download_info ;
	OS_PRINTZ
	
	call clear_outputBuffer ;очистить
	
	ld hl,outputBuffer ;буфер для загрузки
	ld (buffer_pointer),hl 
	;call Wifi.getPacket ;получить ответ
	OS_ESP_GET
	ret c ;сразу не удалось (может, очередь)
	ld b,wait_count ;
radio_download_info_wait1
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,radio_download_info_wait1_skip
	djnz radio_download_info_wait1
	scf ;ощибка
	ret
	
radio_download_info_wait1_skip
	;подготовка к приёму дальше
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места

	;попробуем найти начало данных
	ld de,Content_Length ;найти запись о длине данных
	call search_str
	ret c
	
	ex de,hl
	call text_to_digit ;преобразовать в число
	ld (data_length),hl ;длина данных
	
	ld de,rnrn ;найти конец заголовка
	call search_str
	ret c
	ld (data_start),hl ;начало данных
	
	ld de,(data_length)
	add hl,de ;узнали ожидаемый конец данных
	ld (data_end),hl

;загрузка остальных частей, если есть	
radio_download_info1
	ld a,(ix+2) ;!!! closed
	or a
	jr z,radio_download_info1_skip ;если закрыто, больше не грузим

	ld hl,(buffer_pointer)
	ld de,(data_end)
	and a
	sbc hl,de
	jr z,radio_download_info1_skip ;если уже всё загружено


	;ещё не всё
	ld hl,(buffer_pointer)	
	ld a,h
	cp buffer_top ;ограничение
	jr nc,radio_download_info1_skip

	;call Wifi.getPacket 
	OS_ESP_GET
	ld b,wait_count ;
radio_download_info_wait2
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,radio_download_info_wait2_skip
	djnz radio_download_info_wait2
	scf 
	ret

radio_download_info_wait2_skip	
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места	
	
	jr radio_download_info1 ;получить ещё части до конца
	
radio_download_info1_skip

	OS_ESP_CLOSE ;закрыть соединение!


	ld de,Content_Sucesfully ;найти запись об успешном запросе
	call search_str
	ret c	

	; ld de,Content_Length ;найти запись о длине
	; call search_str
	; ret c
	
	; ex de,hl
	; call text_to_digit ;преобразовать в число
	
	; ex de,hl
	; ld hl,(buffer_pointer) ;
	; and a
	; sbc hl,de
	; ;узнали начало пакета
	
	ld hl,(data_start)
	
	ld de,Content_ID ;найти запись об ID файла
	call search_str
	ret c
	

	;инфа получена
	
	push hl
	call print_info_track ;инфо
	ld a,13
	OS_PRINT_CHARF
	pop hl
	ld de,requestbuffer2_file_id
	
;WAITKEY	XOR A:IN A,(#FE):CPL:AND #1F:JR Z,WAITKEY

	call id_copy ;скопировать в запрос id трека
	
	;запомнить сколько всего
	ld de,Content_Total_Amount ;всего таких треков
	call search_str
	ret c
	ex de,hl
	call text_to_digit
	ld (total_track),hl
	or a
	ret


	
	

	
radio_request_track	;запрос трека
	call radio_open_site ;открыть сайт
	ret c

	ld hl,msg_request_track
	OS_PRINTZ	
	
	;ld hl,requestbuffer2_title
	;OS_PRINTZ
	ld de,requestbuffer2	
	call strLen ;узнать длину
	ex de,hl
	ld hl,requestbuffer2
	OS_ESP_SEND 
	ret c ;сразу не удалось (может, очередь)
	;ждём когда запрос пройдёт
	ld b,wait_count ;
radio_request_track_wait2
	OS_WAIT
	ld a,(ix+4) ;флаг
	rlca
	ret c ;если ошибка (=255)
	or a
	ret nz
	djnz radio_request_track_wait2
	scf
	ret




radio_download_track ;загрузить трек
	ld hl,msg_download_track
	OS_PRINTZ	
	
	call clear_outputBuffer ;очистить
	
	ld hl,outputBuffer ;буфер для загрузки
	ld (buffer_pointer),hl 
	;call Wifi.getPacket ;получить ответ
	OS_ESP_GET
	ret c ;сразу не удалось (может, очередь)
	ld b,wait_count ;
radio_download_track_wait1
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,radio_download_track_wait1_skip	
	djnz radio_download_track_wait1
	scf
	ret

radio_download_track_wait1_skip
	;подготовка к приёму дальше
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места

	;попробуем найти начало данных
	ld de,Content_Length ;найти запись о длине данных
	call search_str
	ret c
	
	ex de,hl
	call text_to_digit ;преобразовать в число
	ld (data_length),hl ;длина данных
	
	ld de,rnrn ;найти конец заголовка
	call search_str
	ret c
	ld (data_start),hl ;начало данных
	
	ld de,(data_length)
	add hl,de ;узнали ожидаемый конец данных
	ld (data_end),hl	
	
	;загрузка остатка
radio_download_track1

	ld a,(ix+2) ;!!! closed
	or a
	jr z,radio_download_track1_skip ;если закрыто, больше не грузим
	
	ld hl,(buffer_pointer)
	ld de,(data_end)
	and a
	sbc hl,de
	jr z,radio_download_track1_skip ;если уже всё загружено


	;ещё не всё
	ld hl,(buffer_pointer)	
	ld a,h
	cp buffer_top ;ограничение
	jr nc,radio_download_track1_skip
	
	;call Wifi.getPacket 
	OS_ESP_GET
	ld b,wait_count ;
radio_download_track_wait2
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,radio_download_track_wait2_skip
	djnz radio_download_track_wait2
	scf
	ret
	
radio_download_track_wait2_skip
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места	
	
	jr radio_download_track1 ;получить ещё части до конца
	
radio_download_track1_skip
	OS_ESP_CLOSE ;закрыть!


	; ;определить длину
	; ld de,Content_Length ;найти запись о длине
	; call search_str
	; ret c
	; ex de,hl
	; call text_to_digit ;преобразовать в число
	
	; ex de,hl
	; ld hl,(buffer_pointer) ;
	; and a
	; sbc hl,de
	; ;узнали начало пакета

	ld hl,(data_start) ;начало данных
	or a
	ret

	




print_sys_info ;печать меню управления
	ld a,7+64 ;цвет
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_sys_info
	OS_PRINTZ
	ld a,7 ;цвет
	ld b,#c
	OS_SET_COLOR
	ret


print_info_track ;печать инфо о треке
	ld hl,Content_Total_Amount ;всего таких треков
	call print_info_track_one
	ret c
	
	ld hl,Content_ID ;id трека
	call print_info_track_one
	ret c

	ld hl,Content_Type ;формат трека
	call print_info_track_one
	ret c
	
	ld a,4 ;цвет
	ld b,#c
	OS_SET_COLOR
	ld hl,Content_Title ;название трека
	call print_info_track_one
	push af
	ld a,7 ;цвет
	ld b,#c
	OS_SET_COLOR
	pop af
	ret c

	ld hl,Content_Year ;год трека
	call print_info_track_one
	ret c

	ld hl,Content_Time ;длина трека
	call print_info_track_one
	ret c

	ld hl,Content_Rating ;рейтинг трека
	call print_info_track_one
	ret c
	
	ld hl,Content_AuthorIDs ;id автора трека
	call print_info_track_one
	ret c
	
	ld a,13
	OS_PRINT_CHARF	
	ret
	
	
print_info_track_one
	push hl
	ld a,13
	OS_PRINT_CHARF
	pop hl
	push hl
	OS_PRINTZ
	pop de
	call search_str
	ret c
	call print_to_sym ;печать значения
	or a
	ret

print_to_sym ;печать до символа "," или 0
	ld a,(hl)
	cp ","
	ret z
	or a
	ret z
	push hl
	OS_PRINT_CHARF
	pop hl
	inc hl
	jr print_to_sym
	

delay ;задержка между запросами
	ld b,50*1 ;
delay1
	OS_WAIT
	djnz delay1
	ret

;hl - from
;de - to
id_copy ;скопировать текст id 
	ld a,(hl)
	cp "0"
	jr c,id_copy2
	cp "9"+1
	jr nc,id_copy2
	ld (de),a
	inc de
	inc hl
	jr id_copy
	
id_copy2
	;скопировать остаток строки запроса
	ld hl,requestbuffer2_end
id_copy3	
	ld a,(hl)
	or a
	jr z,id_copy_ex
	ld (de),a
	inc de
	inc hl
	jr id_copy3
id_copy_ex
	xor a
	ld (de),a  ;в конце 0 
	ret

strLen: ;посчитать длину строки до 0
    ld hl, 0
.loop
    ld a, (de) : and a : ret z
    inc de, hl
    jr .loop

text_to_digit ;тест в цифру
;de - текст
;вых: hl - цифра
		ld hl,0			; count lenght
.cil1	ld a,(de)
		inc de
		cp "0" : ret c
		cp "9"+1 : ret nc
		sub 0x30 : ld c,l : ld b,h : add hl,hl : add hl,hl : add hl,bc : add hl,hl : ld c,a : ld b,0 : add hl,bc
		jr .cil1

;поиск строки
;de - образец, в конце 0 
;вых: hl - адрес после найденного
search_str
	ld hl,outputBuffer
	ld b,d
	ld c,e
search_str2
	ld a,(de)
	cp (hl)
	jr nz,search_str1
	;нашли одну букву
search_str3	
	inc hl
	inc de
	ld a,(de)
	or a
	ret z ;нашли всю строку
	cp (hl)
	jr z,search_str3
	;не вся строка совпала
	ld d,b ;в начало образца
	ld e,c	
search_str1
	inc hl ;дальше
	inc h
	dec h
	jr nz,search_str2
	scf ;не нашли
	ret
	

clear_outputBuffer ;почистить буфер приёма
	ld hl,outputBuffer
	ld de,outputBuffer+1
	ld bc,#ffff-outputBuffer-1
	ld (hl),0
	ldir
	ret
	

;вх: HL - диапазон
;вых: HL - результат
rnd ;генератор случайного числа в заданном диапазоне
	ld a,h
	or l
	ret z
	xor a ;очистить переменную
	ld (rnd_out),a
	ld (rnd_out+1),a
	push hl
	call random ;получить случайное
	;умножить диапазон на случайное число и взять старшие два байта
	pop bc ;счётчик
	ex de,hl
	ld hl,0
rnd_cl	
	add hl,de
	jr nc,rnd_cl1 ;если нет переполения
	exx
	ld de,(rnd_out) ;увеличить старшие байты
	inc de
	ld (rnd_out),de
	exx
rnd_cl1
	dec bc
	ld a,b
	or c
	jr nz,rnd_cl
	ld hl,(rnd_out)	
	ret
rnd_out dw 0 ;ответ случайное число	
	
	
random ;Переписанный генератор из ПЗУ бейсика
	ld	de,0
seed	equ	$-2
	xor	a
	ld	h,a,l,a,b,a
	add	hl,de
	adc	a,b
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	add	hl,de
	adc	a,b
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	add	hl,de
	adc	a,b
	add	hl,hl
	adc	a,a
	add	hl,de
	adc	a,b
	sub	#4a
	neg
	ld	c,a
	add	hl,bc
	ld	(seed),hl
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

	
    ; include "drivers/utils.asm"
    ; include "drivers/wifi.asm"
	; include "drivers/zx-wifi.asm"


id_lenght equ 6 ;длина кода файла
wait_count equ 2*50 ;задержка в кадрах
buffer_top equ #fa;ограничение буфера сверху #ffff - 1500

; ;ответы ESP
; sendOk[] = "SEND OK";
; const unsigned char gotWiFi[] = "WIFI GOT IP";
; "CONNECT"
	
; ;команды
; ;<link ID> – ID соединения (0–4), используется при нескольких соединениях;
; at_cipmux db "AT+CIPMUX=1",0 ;несколько соединений
;at_cipstart db "AT+CIPSTART=1,\"TCP\",\"zxart.ee\",80",0
; "AT+CIPSEND="
; "AT+CIPCLOSE"
;link_id db 0; номер соединения
data_start dw 0 ;начало данных
data_end dw 0 ;конец данных
data_length dw 0 ;конец данных
buffer_pointer dw 0 ;указатель на буфер
rnrn db 13,10,13,10,0 ;окончание заголовка
site_name db "zxart.ee",0 ;имя сайта
port_number db "80" ,0;
Content_Length db "Content-Length: ",0
Content_Sucesfully db "succes",0
Content_Total_Amount db "\"totalAmount\":",0
Content_Title db "\"title\":",0
Content_AuthorIDs db "\"authorIds\":",0
Content_Rating db "\"rating\":",0
Content_Year db "\"year\":",0
Content_Time db "\"time\":",0
Content_ID db "\"id\":",0
Content_Type db "\"type\":",0
;file_id db "000000",0 ;id файла
msg_open db "Open: ",0
msg_error db "Error",13,0
msg_format db "Format: ",0
msg_download_info db "Download info...",13,0
msg_request_info db "Request info...",13,0
msg_request_track db "Request track...",13,0
msg_download_track db "Download track...",13,0
msg_play_track db "Play track...",13,0
msg_stop db "Stop",13,0
msg_restart db "Restart...",13,0
;msg_get_link_id db "Get link ID...",13,0
msg_sys_info db "S - stop, R - restart, 1-2 - Format (pt2, pt3)",13
	db "Sp - Next, Break - exit",13,0

total_track dw 0;
start_track dw 0;
format_pt2 db "pt2",0
format_pt3 db "pt3",0
format_ts db " ts",0
format_tfc db "tfc",0

player_setup db 0;настройки плеера

;запрос списка
requestbuffer_title db "Request:",13
requestbuffer ;
	db "GET /api/export:zxMusic/limit:1/start:"
start_request ;тут подстановка порядкового номера трека
	db "00000/filter:zxMusicFormat="
request_format	
	db "pt3/order:date,desc HTTP/1.1\r\n"
;request_agent
	db "Host: zxart.ee\r\n"
	db "User-Agent: User-Agent: Mozilla/4.0 (compatible; MSIE5.01; GMX OS)\r\n\r\n",0

;запрос закачки	
requestbuffer2_title db "Request:",13
requestbuffer2 ;
	db "GET /file/id:"
requestbuffer2_file_id ;тут подстановка id трека	
	;db "539319"
	ds #100 ;буфер для отправки	
requestbuffer2_end ;окончание строки запроса
	db " HTTP/1.1\r\n"
;request_agent
	db "Host: zxart.ee\r\n"
	db "User-Agent: User-Agent: Mozilla/4.0 (compatible; MSIE5.01; GMX OS)\r\n\r\n",0	
	

;примеры (может не правильные)	
	;db "http://zxart.ee/api/types:zxMusic/export:zxMusic/language:eng/start:0/limit:2/order:date,desc/filter:zxMusicAll=1;"
	;https://zxart.ee/api/types:zxMusic/export:zxMusic/language:eng/start:0/limit:2/order:date,desc/filter:zxMusicAll=1;
	
	;db "GET /file/id:44816",0
	;db "GET /api/export:zxMusic/limit:2/start:0/filter:zxMusicFormat=pt3/order:date,desc",0


;requestbuffer_end
	
msg_title_radio
	db "Radio ver 2025.01.16",10,13,0
	
outputBuffer_title db "Response:",13
outputBuffer equ $  ;буфер для загрузки

end_radio
	;SAVETRD "OS.TRD",|"radio.C",start_radio,$-start_radio
	savebin "radio.apg",start_radio,$-start_radio