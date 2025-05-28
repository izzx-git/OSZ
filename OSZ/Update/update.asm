;OS Update - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROGSTART	
	
start_update
	; ld a,13 ;новая строка
	; OS_PRINT_CHARF	
	ld hl,msg_title_update ;имя приложения
	OS_PRINTZ ;печать

;запрос подтверждения
	ld hl,msg_update_confim ;
	OS_PRINTZ ;печать
	;jr start_loop
loop_confim
	OS_WAIT
	OS_GET_CHAR
	cp "y"
	jp z,start_loop
	cp "Y"
	jp z,start_loop

	cp 'n' ;n
	jp z,exit	
	cp 'N' ;n
	jp z,exit	
	cp 24 ;break
	jp z,exit	
	
	jr loop_confim


	
exit ;выход в ДОС
	ld hl,msg_exit
	OS_PRINTZ ;печать	
exit_wait
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z,exit_wait
	xor a ;закрыть себя
	OS_PROC_CLOSE 
	
	
	
	
start_loop ;начало
	;загрузить адрес сайта обновлений из файла
	ld hl,file_list_name
	ld de,list_buffer ;место для списка
	call load_file
	jp c,exit
	
	ld bc,3 ;в 3 строке имя списка файлов
	call make_request_string ;подготовить запрос
	jp c,exit



start_loop_list
	OS_WAIT
	cp 24 ;break
	jp z,exit
	call request_file ;загрузка списка файлов с сервера
	jr nc,request_file_ok
	call print_main_error
	jr start_loop_list ;повторить, если ошибка
	
	
request_file_ok	
	call download_file
	jr nc,download_file_ok
	call print_main_error	
	jr start_loop_list ;повторить, если ошибка
	
download_file_ok	
	;Проверить сигнатуру (в первой строке слово Update)
	ld hl,(data_start)	
	ld a,"U"
	cp (hl)
	jr z,download_file_sign_ok
	ld hl,msg_bad_list_file
	OS_PRINTZ
	jr exit
	
	
download_file_sign_ok	
	;скопировать файл список в его буфер
	ld de,list_buffer
	ld bc,max_list_size
	ldir
	xor a
	ld (de),a ;в конце 0
	
	;call rename_folder	;переименовать текущую папку ОС и создать новую
	
	
	;сейчас качаем и записываем файлы
	ld bc,3 ;цикл все файлы с этой строки
	ld (make_request_string_num),bc
start_loop_general_cl
	call make_request_string ;подготовить запрос
	jp c,exit_ok

	;получить имя файла без пути
	ld bc,(make_request_string_num)
	ld hl,list_buffer
	call split_text_on_string ;получить строку N
	jp c,exit_err
	call format_name_delete_path ;убрать пути
	push hl
	ld hl,msg_open_file
	OS_PRINTZ ;печать
	
	ld a,4;цвет
	ld b,#c
	OS_SET_COLOR
	
	pop hl
	push hl
	OS_PRINTZ ;печать имени файла
	ld a,13
	OS_PRINT_CHARF
	
	ld a,7 ;цвет
	ld b,#c
	OS_SET_COLOR
	
	pop hl
	OS_FILE_OPEN ;открыть файл
	ld (download_write_file_id),a
	jr nc,start_loop_general_file_ok
	
	OS_FILE_CREATE ;создать, если нет
	ld (download_write_file_id),a
	jp c,exit_err
start_loop_general_file_ok
	;тут файл успешно создали или открыли тот, что есть

start_loop_general
	OS_WAIT
	cp 24 ;break
	jp z,exit
	call request_file ;загрузка файлов с сервера
	jr nc,request_file_general_ok
	call print_main_error
	jr start_loop_general ;повторить, если ошибка
	
	
request_file_general_ok	
	call download_file
	jr nc,download_file_general_ok
	jr exit_err

download_file_general_ok
	;записать файл
	ex de,hl
	call print_download_size	;печать инфы размер
	ld hl,msg_write_file
	OS_PRINTZ
	ld hl,(data_start) ;начало данных
	ld de,(data_length) ;длина
	ld a,(download_write_file_id)
	OS_FILE_WRITE
	jp c,exit_err
	ld a,(download_write_file_id)
	OS_FILE_CLOSE
	ld bc,(make_request_string_num)
	inc bc
	ld (make_request_string_num),bc
	jp start_loop_general_cl
	
	
exit_ok
	;всё успешно, выход
	ld hl,msg_ok
	OS_PRINTZ
	jp exit
	
exit_err
	;какая-то ошибка
	call print_main_error
	jp exit



; HL - name (path/name.ext)
; Returns:
; HL - name (name.ext)	
format_name_delete_path ;убирает пути из имени файла

	;сначала попробуем убрать из пути подпапку, если она есть
	ld (temp_hl),hl ;сохраним адрес исходного имени
	ld b,#00 ;не больше 255 символов	
format_name5	
	ld a,(hl)
	cp "/" ;если есть подпапка
	jr z,format_name_path_yep
	ld a,(hl)
	cp "." ;если ещё не дошли до расширения
	jr nz,format_name6
	ld hl,(temp_hl) ;если дошли до расширения, вернёмся на начало имени
	jr format_name_7 ;на выход
format_name6
	inc hl
	djnz format_name5
	
format_name_path_yep ;нашли
	inc hl ;пропустим знак "/"
	ld (temp_hl),hl ;сохраним адрес 
	jr format_name5
	
format_name_7	
	ld bc,#0cff ;длина имени макс 12 символов
	ld de,f_name ;куда
format_name2	
	ld a,(hl)
	cp " "
	jr c,format_name_e
	ldi
	djnz format_name2

format_name_e		
	xor a
	ld (de),a
	ld hl,f_name ;вернём результат
	ret

f_name ds 8+3+1+1
temp_hl dw 0;




	
	
; rename_folder	
	; ;переименовать папку ОС 
	; ld hl,msg_rename_folder
	; OS_PRINTZ
	
	
	; ret
	
	
	
	
make_request_string ;подготовить запрос
;вх: hl - адрес строки имени файла
	ld (make_request_string_num),bc
	ld hl,request_string1
	ld de,request_buffer
	call copyZ ;отправить в строку запроса

	push de
	ld bc,(make_request_string_num)
	ld hl,list_buffer
	call split_text_on_string ;получить строку N (2я -имя файла списка)
	pop de	
	
	jr c,make_request_string_err
	; push hl
	; OS_PRINTZ ;напечатать имя файла
	; ld a,13
	; OS_PRINT_CHARF
	; pop hl

	call copyZ ;отправить в строку запроса
	
	ld hl,request_string2
	call copyZ ;отправить в строку запроса	

	push de
	ld bc,2
	ld hl,list_buffer
	call split_text_on_string ;получить строку (адрес сайта)
	pop de	
	
	jr c,make_request_string_err

	call copyZ ;отправить в строку запроса


	ld hl,request_string3
	call copyZ ;отправить в строку запроса		
	
	
	xor a
	ld (de),a ;в конце 0
	ret
	
make_request_string_err
	scf
	ret
	
make_request_string_num dw 0 ;номер строки текущей


request_file ;запрос инфы
	call open_site ;открыть сайт
	ret c

	ld hl,msg_request_file ;
	OS_PRINTZ	
	ld de,request_buffer	
	call strLen ;узнать длину
	ex de,hl
	ld hl,request_buffer	
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
	
	
	
open_site ;открыть сайт
	OS_ESP_CLOSE ;на всякий случай сначала закрыть
	ld hl,msg_open ;печать инфы
	OS_PRINTZ	
	ld hl,list_buffer
	ld bc,2
	call split_text_on_string
	ret c ;если не мог распознать строку в файле
	push hl ;имя сайта
	OS_PRINTZ
	ld a,13 ;новая строка
	OS_PRINT_CHARF	
	pop hl ;имя сайта
	ld de,port_number
	xor a ;открыть TCP
	OS_ESP_OPEN
	ret c ;сразу не удалось (может, очередь)
	;или подождём открытия
	ld b,wait_count ;
open_site_wait
	OS_WAIT
	ld a,(ix+2) ;флаг
	rlca
	ret c ;если ошибка (=255)
	or a ;если флаг !=0
	ret nz
	djnz open_site_wait
	scf ;ощибка
	ret







	
	
download_file ;загрузить файл
	ld hl,msg_download_file
	OS_PRINTZ	
	
	call clear_input_Buffer ;очистить
	
	ld hl,input_Buffer ;буфер для загрузки
	ld (buffer_pointer),hl 
	;call Wifi.getPacket ;получить ответ
	OS_ESP_GET
	ret c ;сразу не удалось (может, очередь)
	ld b,wait_count ;
download_file_wait1
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,download_file_wait1_skip	
	djnz download_file_wait1
	scf
	ret

download_file_wait1_skip
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
download_file1

	ld a,(ix+2) ;!!! closed
	or a
	jr z,download_file1_skip ;если закрыто, больше не грузим
	
	ld hl,(buffer_pointer)
	ld de,(data_end)
	and a
	sbc hl,de
	jr z,download_file1_skip ;если уже всё загружено


	;ещё не всё
	ld hl,(buffer_pointer)	
	ld a,h
	cp buffer_top ;ограничение
	jr nc,download_file1_skip
	
	;call Wifi.getPacket 
	OS_ESP_GET
	ld b,wait_count ;
download_file_wait2
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,download_file_wait2_skip
	djnz download_file_wait2
	scf
	ret
	
download_file_wait2_skip
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места	
	
	jr download_file1 ;получить ещё части до конца
	
download_file1_skip
	OS_ESP_CLOSE ;закрыть!

	ld hl,(data_start) ;начало данных
	ld de,(data_length) ;длина
	or a
	ret




clear_input_Buffer ;почистить буфер приёма
	ld hl,input_Buffer
	ld de,input_Buffer+1
	ld bc,#ffff-input_Buffer-1
	ld (hl),0
	ldir
	ret	
	


download_write_file_id db 0;

	
	
	
print_download_size
	;вх: hl - число для печати
	push ix
	call toDecimal
	OS_PRINTZ
	ld hl,msg_B
	OS_PRINTZ
	pop ix
	ret
	

load_file 
;загрузка файла
;вх: hl - адрес имени
;вх: de - адрес куда
	ld (load_file_name),hl
	ld (load_file_address),de
	ld hl,msg_load_file ;печать инфы
	OS_PRINTZ	
	ld hl,(load_file_name)
	OS_PRINTZ
	ld a,13
	OS_PRINT_CHARF
	ld hl,(load_file_name) ;имя списка
	OS_FILE_OPEN ;откроем файл для чтения
	jp c,print_main_error
	ld (load_file_id),a ;запомнить id
	
	;проверка длины файла не больше #4000
	ld	a,d ;самые старшие байты длины
	or e
	jr z,load_file_size_ok ;если не слищком большой
load_file_too_big
	;слишком большой
	ld hl,msg_file_too_big
	OS_PRINTZ
	scf
	jp print_main_error
	

load_file_size_ok	
	ld	a,b ;младший старший байт длины
	cp #40 ;ограничение
	jr nc,load_file_too_big
	;размер нормальный, прочитаем
	ld (load_file_lenght),bc
	ld hl,(load_file_address)
	ld a,(load_file_id)
	ld d,b ;размер
	ld e,c
	OS_FILE_READ
	jr nc,load_file_size_ok2
	;если ошибка
	call print_main_error
	ld a,(load_file_id)	
	OS_FILE_CLOSE ;закрыть файл	
	scf ;ошибка
	ret
load_file_size_ok2
	ld a,(load_file_id)	
	OS_FILE_CLOSE ;закрыть файл	
	or a ;ok
	ret
load_file_id db 0 ;временно
load_file_lenght dw 0 ;
load_file_name dw 0;
load_file_address dw 0;



split_text_on_string
	;разбор текста на строки, текст заканчивается числом 0
	;всё, что меньше кода пробела, считается концом строки
	;вх: hl - адрес текста
	;вх: bc - номер строки (от 1 до ...), которую надо вернуть
	;вых: hl - адрес строки
	
	;цикл до 0
	ld a,(hl)
	or a
	jr z,split_text_on_string_not_found
	cp " "
	jr nc,split_text_on_string_found
	inc hl
	jr split_text_on_string

split_text_on_string_found	
	;тут нашли первое имя
	push bc
	ld de,split_text_on_string_out ;куда
	ld bc,#0000 ;макс длина 255
split_text_on_string_cl2
	ld a,(hl)
	cp " "
	jr c,split_text_on_string_cl2_ex
	ldi
	djnz split_text_on_string_cl2
	
split_text_on_string_cl2_ex
	xor a
	ld (de),a  ;в конце 0 
	;какая строка нужна
	pop bc
	dec bc
	ld a,b
	or c
	jr nz, split_text_on_string
	
	ld hl,split_text_on_string_out
	xor a ;ОК
	ret
	
	
split_text_on_string_not_found
	ld hl,split_text_on_string_out
	scf ;ошибка
	ret
split_text_on_string_out ds 256 ;здесь строка на выходе	
	
	
	
	
;вх: hl - откуда de - куда
copyZ ;копировать данные до кода 0
	ld a,(hl)
	or a
	jr z,copyZ_ex
	ldi
	jr copyZ
copyZ_ex
	xor a
	ld (de),a  ;в конце 0 
	ret
	
	
	
print_main_error ;печать ошибка
	;какая-то ошибка
	push af
	ld a,2 ;цвет
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_error
	OS_PRINTZ	
	ld a,7 ;цвет
	ld b,#c
	OS_SET_COLOR
	call delay ;задержка
	pop af
	ret
	
	
	
	
delay ;задержка между запросами
	ld b,50*1 ;
delay1
	OS_WAIT
	djnz delay1
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
	ld hl,input_Buffer
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
	
	
toDecimal		;конвертирует 2 байта в 5 десятичных цифр
				;на входе в HL число
				;на выходе в HL число
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
decimalS ds 6 ;здесь будет цифра	
	
max_list_size equ 2048


file_list_name db "update.txt",0	;имя файла, в первой строке адрес сервера
wait_count equ 2*50 ;задержка в кадрах
buffer_top equ #fa;ограничение буфера сверху #ffff - 1500
data_start dw 0 ;начало данных
data_end dw 0 ;конец данных
data_length dw 0 ;конец данных
buffer_pointer dw 0 ;указатель на буфер
rnrn db 13,10,13,10,0 ;окончание заголовка
;site_name db "w909591u.beget.tech",0 ;имя сайта
port_number db "80" ,0;
Content_Length db "Content-Length: ",0


;строки для составления запроса
request_string1 ;
	db "GET ",0
	;db /OSZ/update.txt ;тут имя файла
request_string2
	db " HTTP/1.1\r\nHost: ",0
request_string3
	;db "Host: w909591u.beget.tech\r\n" ;тут хост
	db "\r\nUser-Agent: Mozilla/5.0" ; (Macintosh; Intel Mac OS X 10.8; rv:21.0)"
	db "\r\n\r\n",0

msg_open db "Open: ",0
msg_error db "Error",13,0
msg_download_file db "Download file... ",13,0
msg_request_file db "Request file...",13,0
msg_load_file db "Load file... ",0
msg_file_too_big db "File too big!",13,0
msg_exit db "Press a key to Exit",13,0
;msg_rename_folder db "Rename OS folder...",13,0
msg_ok db 13,"OK! The system is now updated.",13,0
msg_bad_list_file db "Bad list file!",13,0
msg_B db "B",13,0
msg_write_file db "Write file...",13,0
msg_open_file db "Open file...",0

msg_update_confim
	db "Please close all apps, make backup.",13
	db "Update OS from net? Y/N",13,0
	
msg_title_update
	db "OS Update ver 2025.05.23",13,13,0

request_buffer_title db "Request:",13

end_udate_code
;ниже не включается в файл

request_buffer ds 1024 ;буфер для запросов
	align 8
list_buffer ds max_list_size ;буфер для списка

input_Buffer_title db "Response:",13
input_Buffer equ $  ;буфер для загрузки

end_update
	savebin "update.apg",start_update,end_udate_code-start_update