;OS GMX (izzx, 2024)


;sys - системный процесс для OS
   device ZXSPECTRUM128
	include "os_defs.asm"    
	org PROGSTART
	;bank 1
start_sys
	ei
	halt ;ожидание старта после прерывания
	halt
	ld hl,msg_ver_os
	;печать приветствия
	call drvgmx.printZ
	

;инициализация устройств
;uart #EF (wifi)
	xor a
	ld (uart_enable),a ;флаг порт отсутствует
	call Uart.check
	cp 255
	;jr z,init_uart_no ;отключена проверка
	;нашли uart
	ld a,1
	ld (uart_enable),a ;порт есть
	ld hl,msg_init_uart_found
	call drvgmx.printZ
	call Wifi.init 	
	jr init_uart_yes
init_uart_no
	;печать
	ld hl,msg_init_uart_not_found	
	call drvgmx.printZ
init_uart_yes
	
	call Dos.init_fs_fat ;выбор раздела (буквы диска)
	
	;call proc_run_cmd ;запустить консоль
	;call proc_run_cmd ;запустить консоль	
	; call proc_run_cmd ;запустить консоль
	; call proc_run_cmd ;запустить консоль
	; call proc_run_cmd ;запустить консоль
	;call proc_run_cmd ;запустить консоль
	;call proc_run_cmd ;запустить консоль

	ld hl,proc_name_01		;строка с именем
	call proc_run
	
	ld hl,proc_name_02		;строка с именем
	call proc_run
	
	
	ld a,(ix)
	call proc_set_focus ;на передний план
	
sys_loop
	halt
	call print_active
	ld a,(proc_switch_key_flag)
	or a
	jr z,sys_loop1
	call proc_focus_next
sys_loop_switch	
	halt
	OS_GET_CHAR ;ждать пока отпустят
	cp 255
	jr nz,sys_loop_switch
	xor a	
	ld (proc_switch_key_flag),a
sys_loop1
	ld a,(sys_timer) ;иногда печатаем системную информацию
	and %00011100
	call z,sys_print_info 
	; OS_GETCHAR ;получить нажатую клавишу
	; cp 255
	; jr z,sys_loop
	; OS_PRINT_CHARF ;печать символа
	
	call esp_check_open ;проверить соединения
	call esp_check_send ;проверить пакеты на отправку
	call esp_check_get ;проверить пакеты на приём
	ld a,(sys_timer) ;иногда печатаем сетевую информацию
	and %00001110
	call z,print_esp_link	
	
	jr sys_loop
	
	
sys_print_info
	;печать информации о памяти и процессах
	call get_proc_total ;печать и подсчёт процессов
	ld l,a
	ld h,0
	call toDecimal
	ld de,#0d00 ;координаты yx
	OS_SET_XY
	ld hl,msg_processes 
	call drvgmx.printZ	
	ld hl,decimalS+3
	call drvgmx.printZ
	
	ld de,#0c00 ;координаты yx
	OS_SET_XY
	ld hl,msg_free_ram
	call drvgmx.printZ
	call get_free_ram ;памяти
	ld l,a
	ld h,0
	call toDecimal
	ld hl,decimalS+2
	call drvgmx.printZ	
	ld de,#1800 ;координаты yx
	OS_SET_XY
	ld hl,msg_press_num_to_close
	OS_PRINTZ
	ret


print_esp_link
	ld h,#0b
	ld a," "
	OS_FILL_LINE ;почистить строку
	ld ix,esp_link_id_table
	ld a,(ix)
	or a
	ret z ;если нет соединений	
	ld de,#0b00 ;координаты yx
	OS_SET_XY
	ld hl,msg_esp_link
	OS_PRINTZ
	ld a,(ix)
	add '0'
	OS_PRINT_CHARF ;id
	ld a," "
	OS_PRINT_CHARF

	ld hl,msg_esp_transmit
	OS_PRINTZ
	ld a,(ix+4)
	or a
	jr z,print_esp_link2
	ld a,(ix+5) ;при этом не начался приём
	ld c,a
	ld a,(ix+6)
	or c
	jr nz,print_esp_link2	
	ld l,(ix+9)
	ld h,(ix+10)
	call toDecimal
	ld hl,decimalS
	OS_PRINTZ	;отправлено
	ld a," "
	OS_PRINT_CHARF	
print_esp_link2	

	ld hl,msg_esp_receive
	OS_PRINTZ
	ld a,(ix+6)
	or a
	jr z,print_esp_link3
	ld l,(ix+9)
	ld h,(ix+10)
	call toDecimal
	ld hl,decimalS
	OS_PRINTZ	;принято
	ld a," "
	OS_PRINT_CHARF	
print_esp_link3	

	ld hl,msg_esp_address
	OS_PRINTZ	
	ld a,(ix+2) ;соединение установлено
	or a
	jr z,print_esp_link4
	ld hl,esp_link_id_table+15 ;сервер
	OS_PRINTZ	
print_esp_link4	
	ret

get_proc_total
	;поиск и печать количества запущеных процессов
	;вых: a - количество активных
	ld de,#0e00 ;координаты yx
	OS_SET_XY
	ld ix,proc_table
	ld b,proc_max ;цикл по максимальному количеству процессов
	ld c,0 ;счётчик
get_proc_total_cl
	ld a,(ix)
	or a ;свободен?
	jr z,get_proc_total_cl1
	
	push bc
	add '0' ;печать id
	OS_PRINT_CHARF
	ld a," "
	OS_PRINT_CHARF	
	ld a,(ix+1)
	add '0' ;печать id родительского
	OS_PRINT_CHARF
	ld a," "
	OS_PRINT_CHARF	
	
	push ix
	pop hl
	ld bc,16
	add hl,bc
	OS_PRINTZ ;печать имени
	
	ld a,13
	OS_PRINT_CHARF

	pop bc
	
	inc c ;прибавить
get_proc_total_cl1	
	inc ixh
	djnz get_proc_total_cl
	ld a,c
	ret


get_free_ram
	;поиск количества свободных страниц памяти
	;вых: a - количество свободных
	ld hl,proc_page_table ;таблица памяти приложений с кодами процессов
	ld b,page_max ;всего страниц
	ld c,0 ;счётчик
get_free_ram_cl
	ld a,(hl)
	or a ;свободен?
	jr nz,get_free_ram_cl1
	inc c ;прибавить
get_free_ram_cl1
	inc hl
	djnz get_free_ram_cl
	ld a,c
	ret
	
	
	
print_active ;значёк активности
	ld de,#0a00 ;координаты yx
	OS_SET_XY	
	ld hl,msg_active
	OS_PRINTZ
	ld a,(msg_active_cur)
	inc a
	cp 4
	jr c,print_active1
	xor a
print_active1
	ld (msg_active_cur),a
	ld c,a
	ld b,0
	ld hl,msg_active1
	add hl,bc
	ld a,(hl)
	OS_PRINT_CHARF
	ret
	


	
esp_check_open ;проверка очереди соединений ESP
	ld ix,esp_link_id_table ;
	;push bc
	ld a,(ix+1)
	or a ;запрос есть?
	ret z 
	;есть запрос
	
	ld a,(ix+14) ;подставить тип соединения
	or a
	jr nz,esp_check_open_type1
	ld a,'T'
	ld (Wifi.cmd_CIPSTART2+0),a
	ld a,'C'
	ld (Wifi.cmd_CIPSTART2+1),a	
	ld a,'P'
	ld (Wifi.cmd_CIPSTART2+2),a
	jr esp_check_open_type_skip
esp_check_open_type1	
	cp 1
	jr nz,esp_check_open_type2
	ld a,'U'
	ld (Wifi.cmd_CIPSTART2+0),a
	ld a,'D'
	ld (Wifi.cmd_CIPSTART2+1),a	
	ld a,'P'
	ld (Wifi.cmd_CIPSTART2+2),a
	jr esp_check_open_type_skip
esp_check_open_type2
	cp 2
	jr nz,esp_check_open_type_skip
	ld a,'S'
	ld (Wifi.cmd_CIPSTART2+0),a
	ld a,'S'
	ld (Wifi.cmd_CIPSTART2+1),a	
	ld a,'L'
	ld (Wifi.cmd_CIPSTART2+2),a
	jr esp_check_open_type_skip

esp_check_open_type_skip
	ld de,esp_link_id_table+59 ;номер порта
	ld hl,esp_link_id_table+15 ;;адрес сервера
	call Wifi.openTCP
	jr nc,esp_check_open_res
	ld a,255 ;ошибка
	jr esp_check_open_err
esp_check_open_res
	;результат запишем
	ld a,(Wifi.closed)
	xor 1
esp_check_open_err
	ld (ix+2),a ;поставить флаг результата открытия
	ld (ix+1),0 ;сбросить флаг запроса
	ret




	
esp_check_send ;проверить пакеты на отправку	
	ld ix,esp_link_id_table ;
	ld a,(ix+3)
	or a ;запрос есть?
	ret z
	;есть запрос
	ld e,(ix+9) ;длина данных
	ld d,(ix+10)
	ld hl,esp_buffer ;адрес
	call Wifi.tcpSend
	ld a,1 ;успех
	jr nc,esp_check_send_res
	ld a,255 ;ошибка
esp_check_send_res
	ld (ix+4),a ;поставить флаг результата отправки
	ld (ix+3),0 ;сбросить флаг запроса
	ret




	
esp_check_get ;проверить пакеты на приём
	ld ix,esp_link_id_table ;
	ld a,(ix+5)
	or a ;запрос есть?
	ret z
	;есть запрос
	ld hl,0
	ld (Wifi.bytes_avail), hl ;длину сбросим
	ld hl,esp_buffer ;адрес
	ld (Wifi.buffer_pointer),hl ;
	call Wifi.getPacket
	jr nc,esp_check_get_res
	ld a,255 ;ошибка
	ld (ix+6),a ;поставить флаг результата приёма
	ld (ix+5),0 ;сбросить флаг запроса
	ret
esp_check_get_res
	;если что-то принято
	ld bc,(Wifi.bytes_avail) ;длина
	ld (ix+9),c ;длина принятых
	ld (ix+10),b	
	
	ld a,b
	or c
	jr z,esp_check_get_skip_copy2 ;защита от нулевой длины

	ld e,(ix+7) ;адрес назначения
	ld d,(ix+8)
	ld a,(ix) ;id назначения
	ld hl,esp_buffer ;откуда
	call esp_buffer_copy ;перекинем данные силами ядра

esp_check_get_skip_copy2
	ld ix,esp_link_id_table ;
	ld a,(Wifi.closed)
	xor 1
	ld (ix+2),a ;поставить текущий флаг открытия
	ld a,1 ;успех	
	ld (ix+6),a ;поставить флаг результата приёма
	ld (ix+5),0 ;сбросить флаг запроса
	ret
	
	
	
	include Drv/zx-wifi.asm ;драйвер сетевой карты ESP
	include Drv/wifi.asm ;работа с ESP
	include Drv/utils.asm ;работа с ESP
	
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
decimalS ds 6 ;здесь будет цифра	
	
msg_processes
	db "Processes: ",0
msg_free_ram
	db "Free pages RAM: ",0
msg_esp_link
	db "ESP id: ",0
msg_esp_transmit
	db "Trn: ",0
msg_esp_receive
	db "Rcv: ",0
msg_esp_address
	db "Adr: ",0
msg_press_num_to_close
	db "Press number process to close.",0
msg_active db "Active ",0	
msg_active1 db "|/-\\",0
msg_active_cur db 0 ;текущий значёк активности
	
end_sys
	;SAVETRD "OS.TRD",|"cmd.C",start_cmd,$-start_cmd
	savebin "sys.com",start_sys,$-start_sys
;------------------------------------------------------------------------







;ядро системы
    ;device ZXSPECTRUM128
	;include os_defs.asm ;список функций	
	
	org #0000	
	;bank 0
start_os_main

x0000	jp	InitProgramm + #c000		;+#C000 после запуска меняется
	ds	#08-3

x0008	jr	x003B			;обработка rst 8
	nop
x000B	nop
	nop
x000D	jr	ExitMon
	ds	#01

x0010	jp	drvgmx.putC  ;PrnSym_Rst10		;печать одного символа

x0013	out	(c),a
	nop
	ds	#02

x0018	ds	#08

x0020	jp function  ;rst #20
		ds	#05 ;#08

x0028	ds	#08 ;rst #28

x0030	ds	#03 ;rst #30

x0033	out	(c),a
	nop

x0036	dw	font

;обработчик прерываний
x0038	jp	Interrupts

;обработка RST 8
x003B	push	af
	ld	a,r
	jp	pe,x0043
	ld	a,r
x0043	push	af
	ld	a,#10			;вход из ram 0
	push	af
	inc	sp
	push	bc
	push	hl
	ld	bc,#0000
	ld	a,#02
	out	(c),a
	ld	bc,#7EFD
	in	h,(c)			;h=in #7EFD
	ld	b,#7A
	in	l,(c)			;l=in #7AFD
	ld	b,#1F
	ld	a,#12
	jr	x0013
	ds	#06			;=#0060

;обработка NMI
;
x0066	push	af
	ld	a,r
	push	af
	ld	a,#20			;вход из ram 0
	push	af
	inc	sp
	push	bc
	push	hl
	ld	hl,(#C001)
	ex	(sp),hl
	ld	a,#55
	ld	(#C001),a
	cpl
	ld	(#C001+1),a
	ld	bc,#1FFD
	ld	a,#12
	jr	x0033

;возврат из монитора =#0084
ExitMon	out	(c),d			;#1FFD
	ld	b,#7F
	out	(c),e			;#7FFD
	ld	bc,#0000
	out	(c),a
	pop	de
	pop	bc
	inc	sp
	pop	af
	ld	r,a
	jp	po,x009B
	pop	af
	ei
	ret
x009B	pop	af
	di
	ret

x009E
; StartWord
	; ldir
	; call	onPageTXT
	; jp	MainLoopEdit
	; INSERT	"Info/!version.txt"
	; INSERT	"Info/!build.txt"
	; db	"GMX"
y009E	ds	#00FF-$

x00FF	dw	x0038


	
;Первый запуск
InitProgramm
	di
	ld sp,#4100 ;временный адрес стека
	ld a, #01 ;включить ОЗУ вместо ПЗУ
    ld   bc,#1ffd
	out (c),a
	ld hl,Start_warm ;заменить адрес старта
	ld (#0001),hl
	jp 0
	

; rst #08: db #8F установка/удаление резидента из памяти
; при "теплой" перезагрузке, если резидент установлен в странице, то эта страница
  ; будет впечатана в 3е окно и управление передано по заданному адресу
; вх:  a - номер страницы для установки резидента
        ; =#08 - удаление резидента
        ; 7,a =1 однократный вызов
     ; hl - адрес старта в странице
; вых: cy=1 резидент не установлен
; сначала копируем в эту страницу то что надо
; и только потом вызываем функцию
; для гмх страницу 8 и #78 задавать нельзя
; перед повторной установкой резидента, вызывать функцию удаления не нужно
	
;Старт системы
Start_warm
	;di
	im 1
	
;------------------------------------------------------------------------------
;вызов функции #00(00) (SetRam0) установка работы со страницей ram 0 вместо rom, требуется для
;корректного выхода из монитора, при ресете отключается 
;вх:  c=#00(00)
;     cy=1 - установка
;     cy=0 - отключение
;вых: регистры не меняются
;   R8CONF
	ld	c,#00
	scf
	rst	#08
	db	#8E
;
	;ei
	;подготовить системный процесс
	ld a,proc_id_system ;код системного процесса
	ld (proc_id_cur),a ;запомнить как текущий
	ld (proc_id_focus),a ;сразу в фокусе
	;ld (proc_run_prepar_id_tmp),a ;для правильного выделения памяти
	ld (proc_id_next),a ;для вычисления следующего процесса

	ld a,con_scr_real ;экран реальный для драйвера
	ld (con_scr_cur),a
	ld a,con_atr_real ;атрибуты реальные
	ld (con_atr_cur),a
	ld a,#39 ;видимый экран
	ld (scr_cur),a
	call drvgmx.init
	
	;запустить системный процесс
;proc_run_sys
;запуск sys не с диска, а из состава ОС
	ld hl,proc_sys_name
	call proc_run_prepar
	ret c
	
	;включить страницы	
	;ld ix,(proc_run_prepar_deskr_tmp) 	
	ld a,(ix+2)
	ld (page_slot2_cur),a ;сделать страницы текущими
	call drvgmx.PageSlot2
	ld a,(ix+3)
	ld (page_slot3_cur),a
	call drvgmx.PageSlot3
	;цвета
	ld a,proc_color_def ;цвет
	ld (drvgmx.attr_screen),a
	ld (ix+#0c),a ;актрибуты (цвет текста)	
	;
	ld a,proc_color2_def ;цвет 2
	ld (drvgmx.attr_screen2),a
	ld (ix+#0d),a ;актрибуты (цвет текста)	
	;перенести код
	ld hl,start_sys_incl
	ld de,PROGSTART
	ld bc,end_sys_incl-start_sys_incl
	ldir 
	;подготовить правильный старт
	ld l,(ix+6) ;стек нового процесса
	ld h,(ix+7) ;стек
	ld sp,hl

	ld a,proc_id_system
	ld (ix),a
	jp PROGSTART ;старт сначала на заглушку

		
	
		
;запуск теста	
	

	; ld hl,proc_name_01		;строка с именем
	; call proc_run
	;jr c,loop_idle
	
	
 	; ld hl,proc_name_02		;строка с именем
	; call proc_run 

 	; ld hl,proc_name_03		;строка с именем
	; call proc_run 

 	; ld hl,proc_name_02		;строка с именем
	; call proc_run 
	
 	; ld hl,proc_name_02		;строка с именем
	; call proc_run 

	; ld a,3
	; call Dos.fclose
	
	; ld hl,proc_name_01		;строка с именем
	; call proc_run	
	
	


	
loop_idle ;заглушка 
	jr loop_idle ;





proc_run_cmd
; запуск cmd не с диска, а из состава ОС
	ld hl,proc_cmd_name
	call proc_run_prepar
	ret c
	;включить страницы	
	;ld ix,(proc_run_prepar_deskr_tmp) 	
	ld a,(ix+2)
	call drvgmx.PageSlot2
	ld a,(ix+3)
	call drvgmx.PageSlot3
	;перенести код
	ld hl,start_cmd_incl
	ld de,PROGSTART
	ld bc,end_cmd_incl-start_cmd_incl
	ldir 
	
	jp file_load_ok ;продолжить стандартно

	
	
	

proc_run_prepar
;подготовка к запуску процесса
;выделение памяти и прочее
;вх: hl - имя процесса (файла) 8+3 символов
;вых: a - номер процесса, IX - дескриптор	

	ld (proc_run_prepar_name_tmp),hl ;сохранить имя
	;поиск свободного дескриптора
	ld hl,proc_table
	ld de,proc_descr_size
	ld b,proc_max ;цикл по максимальному количеству процессов
	ld c,proc_id_system ;первый номер
proc_run_prepar_cl
	ld a,(hl)
	or a ;свободен?
	jr z,proc_run_prepar_ok
	add hl,de
	inc c
	djnz proc_run_prepar_cl
	;не нашли свободного
	ld hl,msg_proc_max
	call drvgmx.printZ ;сообщение
	scf
	ret
proc_run_prepar_ok
	;есть свободный
	push hl
	pop ix ;дискриптор процесса
	ld (proc_run_prepar_deskr_tmp),hl
	ld a,c ;присвоить номер
	ld (proc_run_prepar_id_tmp),a
	
	
	ld a,(proc_id_cur)
	ld (ix+1),a ;код родительского
	
	;скопировать имя
	ld de,16 ;
	add hl,de
	ex de,hl
	ld hl,(proc_run_prepar_name_tmp)
	ld bc,8+3
	ldir
	

	;выделение памяти стандартное количество окон
	call proc_find_ram
	jr c,proc_run_prepar_no_mem
	ld (ix+2),a ;страница 8000
	call proc_find_ram
	jr c,proc_run_prepar_no_mem
	ld (ix+3),a ;страница c000
	call proc_find_ram
	jr c,proc_run_prepar_no_mem
	ld (ix+4),a ;страница пиксели
	call proc_find_ram
	jr c,proc_run_prepar_no_mem
	ld (ix+5),a ;страница атрибуты

	jr proc_run_prepar_mem_ok
	
proc_run_prepar_no_mem
	ld a,(proc_run_prepar_id_tmp)
	call proc_clear_ram ;освободить память обратно
	
	ld hl,msg_mem_max
	call drvgmx.printZ ;сообщение
	scf
	ret

proc_run_prepar_mem_ok ;памяти хватило
	
	;определить адрес стека
	ld a,(proc_run_prepar_id_tmp) ;id
	ld hl,proc_table-256
	add h
	ld h,a
	ld l,#80 ;на стек меньше 128 байт
	; ld hl,proc_stack
	; or a
	; jr z,proc_run_prepar_ex
	; ld b,a	
	; ld de,proc_stack_size
; proc_run_prepar_cl2 ;цикл	
	; add hl,de
	; djnz proc_run_prepar_cl2
;proc_run_prepar_ex	
	ld (ix+6),l ;адрес стека
	ld (ix+7),h ;адрес стека
	; ld a,(proc_run_prepar_id_tmp) ;id
	; ld (ix+0),a
	ld a,(proc_run_prepar_id_tmp) ;id
	or a
	ret

proc_run_prepar_name_tmp dw 0 ;временно имя нового процесса
proc_run_prepar_id_tmp db 0 ;временно id нового процесса	
proc_run_file_id_tmp db 0 ;временно id файла
proc_run_prepar_deskr_tmp dw 0 ;временно дескриптор процесса
	
proc_find_ram	;поиск свободной страницы памяти
;вых: a - номер страницы, также записан id процесса в таблицу proc_page_table
	ld de,drvgmx.page_table ;таблица возможных вариантов с номерами страниц
	ld hl,proc_page_table ;таблица памяти приложений с кодами процессов
	ld b,page_max
proc_find_ram_cl
	xor a
	or (hl)
	jr z,proc_find_ram_ok1 ;нашли
	;ищем дальше
	inc hl
	inc de
	djnz proc_find_ram_cl
	;совсем не нашли
	scf
	ret
proc_find_ram_ok1
	ld a,(proc_run_prepar_id_tmp)
	ld (hl),a ;записать id процесса в таблицу
	ld a,(de) ;вернуть номер страницы
	or a
	ret
	
	
proc_clear_ram ;освбождение всех страниц памяти процесса
;вх: a - номер процесса
	ld hl,proc_page_table
	ld b,page_max ;цикл сколько всего страниц в таблице	
proc_clear_ram_cl ;
	cp (hl) ;совпадает с номером процесса?
	jr nz,proc_clear1
	ld (hl),0 ;освободить
proc_clear1
	inc hl
	djnz proc_clear_ram_cl
	or a
	ret
	


proc_focus_next
	;переключение фокуса на следующий процесс
	ld a,(proc_id_focus)
	call proc_next_skip
	;ret c ;выернуться если один процесс
	;или сменить фокус, код ниже
	
	
proc_set_focus ;получение фокуса процессом
;вх: a - id процесса
	ld hl,proc_id_focus
	cp (hl)
	ret z ;если уже в фокусе, ничего не делаем
	ld (proc_set_focus_id_tmp),a ;сохранить
	
	ld hl,proc_table-256 ;проверка активен ли заданный процесс
	add h
	ld h,a
	xor a
	or (hl)
	ret z	

	
	;сохранить в буфер процесса текущий экран
	ld a,(proc_id_focus) ;текущий в фокусе
	ld hl,proc_table - 256
	add h
	ld h,a
	push hl
	pop ix ;дескриптор процесса предыдущего
	
	ld a,(ix + 04) ;буфер пиксели
	call drvgmx.PageSlot3
	ld a,con_scr_real ;настоящий экран
	call drvgmx.PageSlot2
	ld hl,#8000 ;скопировать
	ld de,#c000
	ld bc,#4000
	ldir
	
	ld a, (ix + 05) ;буфер атрибуты
	call drvgmx.PageSlot3
	ld a,con_atr_real
	call drvgmx.PageSlot2
	ld hl,#8000 ;скопировать
	ld de,#c000
	ld bc,#4000
	ldir	
	
	;сохранить позицию скрола
	;ld hl,(drvgmx.curscrl)
	;ld (ix+#08),hl ;позиция скрола	
	
	
	;вернуть из буфера экран нужного процесса
	ld a,(proc_set_focus_id_tmp)
	ld hl,proc_table - 256
	add h
	ld h,a
	push hl
	pop ix ;дескриптор процесса который будет в фокусе
	
	ld a,(ix + 04) ;буфер пиксели
	call drvgmx.PageSlot3
	ld a,con_scr_real ;настоящий экран
	call drvgmx.PageSlot2
	ld hl,#c000 ;скопировать
	ld de,#8000
	ld bc,#4000
	ldir
	
	ld a, (ix + 05) ;буфер атрибуты
	call drvgmx.PageSlot3
	ld a,con_atr_real
	call drvgmx.PageSlot2
	ld hl,#c000 ;скопировать
	ld de,#8000
	ld bc,#4000
	ldir	
	
	call page_cur_return	
	
	
	ld a,(proc_set_focus_id_tmp)	
	;запомнить активный процесс
	ld (proc_id_focus),a

	;ld hl,(ix+#08) ;позиция скрола	
	;ld (drvgmx.curscrl),hl
	;call drvgmx.gmxscroll ;обновить скролл
	jp Interrupts ;сразу на другой процесс
	;or a
	;ret
proc_set_focus_id_tmp db 0 ; временно 
	


page_cur_return
;вернуть текущие страницы
	ld a,(page_slot2_cur)
	call drvgmx.PageSlot2	
	ld a,(page_slot3_cur)
	call drvgmx.PageSlot3	
	ret
	

proc_run 
;запуск процесса
;вх: hl - имя файла
	call proc_run_prepar ;выделить память
	ret c

	ld hl,(proc_run_prepar_name_tmp) ;имя
	;ld b,Dos.FMODE_READ
	call Dos.fopen_r ;откроем файл для чтения
	call c,Dos.file_error_print_file_open_error
	jp c,file_load_err
	ld (proc_run_file_id_tmp),a ;запомнить id
	
	;проверка длины файла не больше #8000
	ld	a,d ;самые старшие байты длины
	or e
	jr z,file_size_ok ;если не слищком большой
file_too_big	
	ld hl,Dos.msg_file_too_big
	call drvgmx.printZ
	jp file_load_err	
	

file_size_ok	
	ld	a,b ;младший старший байт длины
	cp proc_size_max+1
	jr nc,file_too_big
	;размер нормальный, прочитаем
	; halt
	; halt
; WAITKEY	XOR A:IN A,(#FE):CPL:AND #1F:JR Z,WAITKEY
	
	;включить страницы	
	ld ix,(proc_run_prepar_deskr_tmp) 	
	ld a,(ix+2)
	call drvgmx.PageSlot2
	ld a,(ix+3)
	call drvgmx.PageSlot3		
	
	ld hl,PROGSTART
	ld a,(proc_run_file_id_tmp)
	ld d,b ;размер
	ld e,c
	call Dos.fread
	jr nc,file_size_ok2
	;если ошибка вернуть страницы
	call Dos.file_error_print_file_read_error
	call page_cur_return		
	scf
	ret
file_size_ok2
	ld a,(proc_run_file_id_tmp)	
	call Dos.fclose
	;jr file_load_ok
	

file_load_ok ;загрузился нормально
	ld ix,(proc_run_prepar_deskr_tmp) ;вспомнить дескриптор
	;очистить экран
	;сначала запомнить как было
	ld hl,(drvgmx.attr_screen)
	ld (proc_run_attr_screen_tmp),hl
	; запомнить координаты экрана предыдущего
	ld hl,(drvgmx.col_screen)
	ld (proc_run_col_screen_tmp),hl ;координаты
	;страницы буфера
	ld a,(con_scr_cur)
	ld (proc_run_con_scr_cur_tmp),a
	ld a,(con_atr_cur)
	ld (proc_run_con_atr_cur_tmp),a
	;скрола
	ld hl,(drvgmx.curscrl)
	ld (proc_run_curscrl_tmp),hl


	
	;чистить буфер экрана
	ld a,proc_color_def ;цвет
	ld (drvgmx.attr_screen),a
	ld (ix+#0c),a ;актрибуты (цвет текста)	
	;
	ld a,proc_color2_def ;цвет 2
	ld (drvgmx.attr_screen2),a
	ld (ix+#0d),a ;актрибуты (цвет текста)	
	;
	ld a,(ix+4)
	ld (con_scr_cur),a
	ld a,(ix+5)
	ld (con_atr_cur),a
	call drvgmx.cls	
	;вернуть
	ld hl,(proc_run_attr_screen_tmp)
	ld (drvgmx.attr_screen),hl
	ld hl,(proc_run_col_screen_tmp) ;координаты	
	ld (drvgmx.col_screen),hl
	ld a,(proc_run_con_scr_cur_tmp)
	ld (con_scr_cur),a
	ld a,(proc_run_con_atr_cur_tmp)
	ld (con_atr_cur),a
	ld hl,(proc_run_curscrl_tmp)
	ld (drvgmx.curscrl),hl


	
	
	;подготовить правильный старт
	ld l,(ix+6) ;адрес стека
	ld h,(ix+7) ;адрес стека
	ld bc,PROGSTART ;возврат сюда
	dec hl
	ld (hl),b
	dec hl
	ld (hl),c
	ld bc,-20 ;возврат будет с восстановлением регистров
	add hl,bc
	
	ld (ix+6),l ;адрес стека
	ld (ix+7),h ;адрес стека	
	ld a,(proc_run_prepar_id_tmp)
	ld (ix),a ;в последнюю очередь код (флаг что процесс работает)
	
	call page_cur_return
	or a
	ret


file_load_err
	scf
	ret

proc_run_attr_screen_tmp dw 0 ;временно
proc_run_con_scr_cur_tmp db 0 ;временно
proc_run_con_atr_cur_tmp db 0 ;временно
proc_run_col_screen_tmp dw 0 ;временно
proc_run_curscrl_tmp dw 0 ;временно








get_c ;функция получение кода нажатой клавиши
	;вых: a - код последней клавиши, 255 - ничего не нажато
	ld a,(proc_id_cur) ;сравнить если процесс в фокусе
	ld hl,proc_id_focus
	cp (hl)
	ld a,255 ;ничего не нажато если не в фокусе
	ret nz
	ld a,(key_cur) ;или вернуть клавишу
	push af
	ld a,255
	ld (key_cur),a ;очистить буфер
	pop af
	ret
	
get_timer ;функция получить значение системного таймера
	ld de,(sys_timer) ;младшие байты
	ld hl,(sys_timer+2)
	ret
	
	
	
page_copy ;скопировать страницу в страницу
;скопировать данные из страницы в страницу
;вх: hl - откуда (абсолютный адрес 0-ffff); de - куда; ix - длина; a - страница слот2; b - страница слот3; 
	ld (page_copy_tmp),bc
	ld (page_copy_tmp),a
	exx
	call page_check_owner 	;проверка разрешений
	ret c
	ld a,(page_copy_tmp+1)
	call page_check_owner 	;проверка разрешений
	ret c
	ld a,ixh ;не больше размера страницы
	cp #41
	jr nc,page_copy_err
	or ixl
	jr z,page_copy_err ;и не 0 длина
	ld a,(page_copy_tmp)	
	call drvgmx.PageSlot2
	ld a,(page_copy_tmp+1)	
	call drvgmx.PageSlot3	
	exx ;вспомнить регистры
	 ;скопировать
	push ix
	pop bc ;длина
	ldir
	call page_cur_return ;вернуть страницы
	xor a
	ret
page_copy_err
	scf
	ret
	

page_copy_tmp dw 0 ;временно

page_check_owner ;проверить разрешена ли страница для процесса
	cp #05 ;видео страница
	ret z
	cp #07 ;видео страница
	ret z
	cp #39 ;видео страница
	ret z
	cp #3a ;видео страница
	ret z
	ld (page_check_owner_tmp),a
	ld hl,drvgmx.page_table ;таблица памяти
	ld b,page_max ;всего страниц
	ld c,0 ;индекс
page_check_owner_cl ;найти такую страницу
	cp (hl)
	jr z,page_check_owner_ex
	inc c
	inc hl
	djnz page_check_owner_cl
	scf ;не нашли в списке страниц
	ret
page_check_owner_ex
	;нашли
	ld b,0
	ld hl,proc_page_table ;сверить с кодом текущего процесса
	add hl,bc
	ld a,(proc_id_cur)
	cp (hl)
	scf ;не совпадает владелец с процессом
	ld a,(page_check_owner_tmp)
	ret nz
	or a
	ret	
page_check_owner_tmp db 0 ;временно	


set_VTPL_PLAY ;запустить плеер AY. будет играть на прерываниях
	ld a,(page_slot2_cur)
	ld (proc_play_ay_slot2),a ;запомнить страницы с музыкой
	ld a,(page_slot3_cur)
	ld (proc_play_ay_slot3),a	
	ld a,(proc_id_cur) ;код процесса, который играет музыку
	ld (proc_play_ay),a 
	ret

set_VTPL_MUTE ;остановить плеер AY
	xor a 
	ld (proc_play_ay),a 
	jp VTPL.MUTE


get_VTPL_SETUP ;получить адрес переменной плеера
	ld hl,VTPL.SETUP
	ret


get_proc_page ;получить номера страниц процесса 
	;вых: BC - страницы в слоте 2, 3
	ld a,(page_slot2_cur)
	ld b,a
	ld a,(page_slot3_cur)
	ld c,a	
	ret
	
	
set_scr ;установить активный экран
	cp #05
	jp z,drvgmx.set_scr5
	cp #07
	jp z,drvgmx.set_scr7
	cp #39
	jp z,drvgmx.set_scr39
	cp #3a
	jp z,drvgmx.set_scr3a
	scf
	ret

set_page_slot2	;включить страницу в слот 2 (#8000);
	call page_check_owner ;проверить принадлежит ли страница процессу
	ret c
	ex af,af'
	ld a,(proc_id_cur)
	ld hl,proc_table - 256
	add h
	ld h,a 
	push hl
	pop ix ;дескриптор 
	ex af,af'
	ld (ix+#02),a ;запомнить текущую страницу процесса
	jp drvgmx.PageSlot2 ;включить
	

set_page_slot3	;включить страницу в слот 2 (#8000);
	call page_check_owner ;проверить принадлежит ли страница процессу
	ret c
	ex af,af'
	ld a,(proc_id_cur)
	ld hl,proc_table - 256
	add h
	ld h,a 
	push hl
	pop ix ;дескриптор 
	ex af,af'
	ld (ix+#03),a ;запомнить текущую страницу процесса	
	jp drvgmx.PageSlot3
	

	
set_interrupt ;установка адреса обработчика прерываний процесса;
	ex de,hl
	ld a,(proc_id_cur)
	ld hl,proc_table - 256
	add h
	ld h,a 
	push hl
	pop ix ;дескриптор 
	ex de,hl
	ld (ix+#0e),l ;адрес
	ld (ix+#0f),h ;адрес
	ret
	

	

;вх: a - тип соединения 0-tcp, 1-udp, 2-ssl; hl - строка адрес, de - строка порт
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
;вых: ix - адрес в таблице соединений (ix+2 - флаг открытия =1 - открыто);
esp_open ;установить соединение ESP (CIPSTART);
	ld ix,esp_link_id_table
	ex af,af'
	ld a,(uart_enable)
	or a
	jr z,esp_open_err ;нет порта
	ld a,(ix)
	or a
	jr nz,esp_open_err ;выйти если буфер занят
	ex af,af'
	ld (ix+14),a ;тип
	push de ;сохранить порт
	ld de,esp_link_id_table+15 ;на имя сервера
	call copyZ ;скопировать
	ld de,esp_link_id_table+59 ;тут адрес порта
	pop hl
	call copyZ
	ld a,(proc_id_cur)
	ld (ix),a ;флаг занято
	ld (ix+2),0 ;флаг результат открытия
	ld (ix+1),1 ;флаг запрос на открытие
	xor a
	ret

esp_open_err
	ld a,255
	scf
	ret



;вх: 
;вых: CY=0 - OK; CY=1 - занято другим процессом
esp_close ;закрыть соединение ESP	
	ld ix,esp_link_id_table
	ld a,(proc_id_cur) ;проверить кто владелец соединения
	cp (ix)
	scf
	ret nz ;выйти если чужое
	xor a
	ld (ix),a ;закрыть
	ret




;вх: hl - адрес данных, de - длина данных
;вых: CY=0 - OK; CY=1 - занято другим процессом
;вых: ix - адрес в таблице соединений (ix+4 - флаг =1 - отправлено)
esp_send ;послать запрос ESP (CIPSEND);
	ld ix,esp_link_id_table
	ld a,(proc_id_cur) ;проверить кто владелец соединения
	cp (ix)
	jr nz,esp_send_err ;выйти если буфер занят другим
	push de ; длина
	pop bc
	ld (ix+9),e  ;длина
	ld (ix+10),d
	ld de,esp_buffer ;перенести данные в буфер отправки
	ldir
	
	ld (ix+4),0 ;флаг результат отправки
	ld (ix+3),1 ;флаг запрос отправки
	xor a
	ret

esp_send_err	
	ld a,255
	scf
	ret



	
;вх: hl - адрес для данных
;вых: CY=0 - OK; CY=1 - занято другим процессом
;вых: ix - адрес в таблице соединений (ix+6 - флаг =1 - принято)	
esp_get ;получить пакет ESP (+IPD);	
	ld ix,esp_link_id_table
	ld a,(proc_id_cur) ;проверить кто владелец соединения
	cp (ix)
	jr nz,esp_get_err ;выйти если буфер занят другим
	ld (ix+7),l ;адрес данных
	ld (ix+8),h ;адрес данных
	ld (ix+6),0 ;флаг результат приёма
	ld (ix+5),1 ;флаг запрос на приём
	xor a
	ret

esp_get_err	
	ld a,255
	scf
	ret


;вх: a - id процесса куда копировать, hl - откуда, de - куда, bc - длина
esp_buffer_copy ;скопировать принятое из буфера ESP 
	exx
	ld hl,proc_table-256 ;проверка активен ли заданный процесс
	add h
	ld h,a
	xor a
	or (hl)
	ret z	
	
	push hl
	pop ix ;дескриптор процесса 
	;включить страницы целевого процесса
	ld a,(ix+2)
	call drvgmx.PageSlot2
	ld a,(ix+3)
	call drvgmx.PageSlot3	
	exx

	ldir
	
	;вернуть страницы
	jp page_cur_return



	
;вх: hl - откуда de - куда
copyZ ;копировать данные до кода 0
	ld a,(hl)
	or a
	jr z,copyZ_ex
	ld (de),a
	inc de
	inc hl
	jr copyZ
copyZ_ex
	xor a
	ld (de),a  ;в конце 0 
	ret
	
	


;выбор функции (вызова)
function
	ex af,af'
	ld a,c
	cp function_max ;проверка на общее количество
	jr c,function1
function_no
	ex af,af'
	ld a,255 ;??????
	scf
	ret
function1	
	exx
	ld l,a
	ld h,0
	add hl,hl ;*2
	ld bc,function_table
	add hl,bc
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld a,e ;временно проверка есть ли такая функция
	or d
	jr z,function_no ;-^
	push de
	exx
	ex af,af'
	ret ;перейти по адресу функции
	

function_table ;таблица функций
	dw drvgmx.cls  ; #00 (0 dec) - очистить консоль;
	dw drvgmx.gotoXY ; #01 (1 dec) - установить позицию курсора в консоли
	dw drvgmx.putC ; #02 (2 dec) - печать символа в консоль;
	dw drvgmx.fillLine ; #03 (3 dec) - заполнение строки одним символом
	dw drvgmx.paintLine ; #04 (4 dec) - покрасить строку цветом
	dw 0 ;#05 (5 dec) - 
	dw drvgmx.set_color ;#06 (6 dec) - установить цвет текста в консоли;
	dw 0 ;#07 (7 dec) - ???????? ???? ?????????? ????????? (???);
	dw 0 ;#08 (8 dec) - ?????????? ???? ?????????? ????????? (???);
	dw drvgmx.printZ ; #09 (9 dec) - ????? ?????? ????????;
	dw 0 ;#0A (10 dec) - ;
	dw 0 ;#0B (11 dec) - ;
	dw esp_close ;#0C (12 dec) - закрыть соединение ESP
	dw esp_open ;#0D (13 dec) - установить соединение ESP (CIPSTART);
	dw esp_send ;#0E (14 dec) - послать запрос ESP (CIPSEND);
	dw esp_get ;#0F (15 dec) - получить пакет ESP (+IPD);
	dw get_c ;#10 (16 dec) - получить код нажатой клавиши;
	dw 0 ;#11 (17 dec) - ????? ???????;
	dw 0 ;#12 (18 dec) - ????? ??????????;
	dw 0 ;#13 (19 dec)-???????? ?????;
	dw set_interrupt ;#14 (20 dec) - установка адреса обработчика прерываний процесса;
	dw VTPL.INIT ;#15 (21 dec) - инициализация плеера AY;
	dw set_VTPL_PLAY ;#16 (22 dec) - запустить плеер AY;
	dw set_VTPL_MUTE ;#17 (23 dec) - заглушить плеер AY;
	dw get_VTPL_SETUP ;#18 (24 dec) - получить значение переменной плеера;
	dw page_copy ;#19 (25 dec) - скопировать страницу в страницу;
	dw proc_find_ram ;#1A (26 dec) - получить дополнительную страницу памяти;
	dw set_page_slot2 ;#1B (27 dec) - включить страницу в слот 2 (#8000);
	dw set_page_slot3 ;#1C (28 dec) - включить страницу в слот 3 (#c000);
	dw set_scr ;#1D (29 dec) - включить экран N;
	dw get_proc_page ;#1E (30 dec) - получить номера страниц процесса;
	dw get_timer ;#1F (31 dec) - получить значение системного таймера
	dw 0 ;#20 (32 dec) - ;инициализация?
	dw Dos.fopen_r ;#21 (33 dec) - открыть файл для чтения или записи;
	dw Dos.fopen_c ;#22 (34 dec) - создать файл;
	dw Dos.fread ;#23 (35 dec) - прочитать из файла;
	dw Dos.fwrite ;#24 (36 dec) - записать в файл;
	dw Dos.fclose ;#25 (37 dec) - закрыть файл;
	dw 0 ;#26 (38 dec) - 
	dw 0 ;#27 (39 dec) - 
	dw 0 ;#28 (40 dec) - ?????? ?????? ?? ?????????? ????.
	dw 0 ;#29 (41 dec) - ??????? ??????;


	
	

	align 16
;обработчик прерываний
Interrupts
	di
	ex (sp),hl
	ld (proc_stack_addr_return_tmp),hl ;запомнить откуда вызвали прерывание
	ex (sp),hl
	push af
	push bc
	push de
	push hl
	exx
	ex af,af'
	push af
	push bc
	push de
	push hl
	push ix
	push iy
	ld (proc_stack_addr_tmp),sp ;запомнить адрес стека
	ld a,1
	out (254),a
	
	;таймер
	ld hl,(sys_timer)
	inc hl
	ld (sys_timer),hl
	ld a,h
	or l
	jr nz,Interrupts_timer
	ld hl,(sys_timer+2)
	inc hl
	ld (sys_timer+2),hl	
Interrupts_timer	

	
;опрос клавиатуры
	call @DriverKeyboard
	cp proc_switch_key ;если клавиша переключения задач
	jr nz,Interrupts_key_switch_no
	ld (proc_switch_key_flag),a ;сохранить нажатие
Interrupts_key_switch_no
	bit 6,(hl)
	jr nz,Interrupts_key1 ;если не нажата ни одна

	ld (key_cur),a ;запомнить клавишу
Interrupts_key1	
	;
	cp DrvKey.keyEdit
	jr nz,Interrupts_key2
	;переключение языка
	ld a,%00001000	;3,=1/0 Rus/Lat 
	xor (hl) ;флаг FlgScanKeys
	ld (hl),a
	jr Interrupts_key_ex
Interrupts_key2
	cp DrvKey.keyCaps
	jr nz,Interrupts_key3
	;переключение заглавных
	ld a,%00000010	;?1,=1/0 CapsLock on/off
	xor (hl)
	ld (hl),a	
	jr Interrupts_key_ex	
Interrupts_key3	
	cp DrvKey.keyDelete
	jr nz,Interrupts_key_ex
	;графическая
	ld a,%00000100	;2,=1/0 Grf on/off  
	xor (hl)
	ld (hl),a	
Interrupts_key_ex
	;с клавиатурой всё





;определить текущие страницы памяти
	ld bc,#7AFD
	in a,(c)
	and %01111111
	ld (Interrupts_cur_page_slot3),a 
	ld bc,#78fd
	in a,(c)
	xor %00000010
	ld (Interrupts_cur_page_slot2),a	
	
	
	
	
;плеер музыки и прочие неотложные процессы
	ld a,(proc_play_ay)
	or a
	jr z,Interrupts_ay_skip
	ld a,(proc_play_ay_slot2) ;страницы с музыкой
	call drvgmx.PageSlot2
	ld a,(proc_play_ay_slot3) ;страницы с музыкой
	call drvgmx.PageSlot3
	call VTPL.PLAY ;играть
	
	
;вернуть страницы
	ld a,(Interrupts_cur_page_slot2)
	call drvgmx.PageSlot2
	ld a,(Interrupts_cur_page_slot3)
	call drvgmx.PageSlot3

	
Interrupts_ay_skip








;многозадачность тут
	ld a,(proc_stack_addr_return_tmp+1) ;узнать адрес откуда были прерывания
	cp #40 ;если прерывание было в области пзу, значит работала система
	jp c,Interrupts_ex ;пропустим переключения на другие задачи
	
	
	call proc_next
	;jr c,Interrupts_ex ;если процесс один, то на выход
	
	push hl ;дескриптор следующего
	pop ix
	

	;запомнить стек предыдущего (текущего) процесса 
	ld a,(proc_id_cur)
	ld hl,proc_table - 256
	add h
	ld h,a 
	push hl
	pop iy ;дескриптор предыдущего
	
	ld bc,6
	add hl,bc
	ld bc,(proc_stack_addr_tmp)
	ld (hl),c
	inc hl
	ld (hl),b
	
	;запомнить координаты экрана предыдущего
	ld hl,(drvgmx.col_screen)
	ld (iy+#0a),hl ;координаты

	ld hl,(drvgmx.attr_screen)
	ld (iy+#0c),hl ;атрибуты (цвет текста)

	ld hl,(drvgmx.curscrl)
	ld (iy+#08),hl ;позиция скрола
	
	
	
	;следующий
	ld a,(ix+2)
	ld (page_slot2_cur),a ;сделать страницы текущими
	call drvgmx.PageSlot2
	ld a,(ix+3)
	ld (page_slot3_cur),a
	call drvgmx.PageSlot3	
	

	;параметры экрана (консоли) 
	ld hl,(ix+#0a) ;координаты
	ld (drvgmx.col_screen),hl
	
	ld hl,(ix+#0c) ;атрибуты (цвет текста)
	ld (drvgmx.attr_screen),hl

	ld hl,(ix+#08) ;позиция скрола
	ld (drvgmx.curscrl),hl
	

	
	ld a,(proc_id_focus) ;если это процесс в фокусе
	cp (ix)
	jr nz,proc_next_no_focus
	ld a,con_scr_real ;экран реальный для драйвера
	ld (con_scr_cur),a
	ld a,con_atr_real ;атрибуты реальные
	ld (con_atr_cur),a	
	jr proc_next2
proc_next_no_focus	
	;если не в фокусе
	ld a,(ix+4) ;пиксели
	ld (con_scr_cur),a
	ld a,(ix+5) ;атрибуты
	ld (con_atr_cur),a	
proc_next2	
	ld l,(ix+6) ;стек
	ld h,(ix+7) ;стек
	ld sp,hl
	
	ld a,(proc_id_next)
	ld (proc_id_cur),a ;сменить текущий
	
	call drvgmx.gmxscroll ;обновить скролл	
	
Interrupts_ex	
	ld a,0
	out (254),a
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af	
	pop hl
	pop de
	pop bc
	pop af
	ei
	ret

proc_next
	;переключение на следующую задачу
	;вых: hl - дескриптор следующего процесса
	ld a,(proc_id_next) ;узнать следующий
proc_next_skip
	inc a
	cp proc_max+1
	jr c,proc_next1
	ld a,proc_id_system
proc_next1
	ld (proc_id_next),a 

	ld hl,proc_table-256 ;номера процессов начинаются с 1
	add h ;перейти на номер кратный 256
	ld h,a
	ld a,(hl)
	or a ;нет активного процесса?
	jr z,proc_next ;искать дальше
	;нашли следующий процесс
	ld a,(proc_id_cur)
	cp (hl) ;если это он и был (всего один процесс)
	scf
	ret z
	ld a,(hl) ;или вернуть id слудующего
	or a
	ret
	
Interrupts_cur_page_slot2 db 0 ;временно
Interrupts_cur_page_slot3 db 0 ;временно


	

	
	include Drv/zsgmx.asm ;драйвер экрана и памяти
	include Drv/zsfat.asm ;драйвер диска
	include Drv/DrvKey.main.a80 ;драйвер клавиатуры
	include player.asm ;плеер AY, TS
	align 256
font
	incbin fontV6.chr ;шрифт

;Переменные 
uart_enable db 0; флаг есть порт uart
proc_play_ay db 0 ;код процесса с музыкой AY
proc_play_ay_slot2 db 0 ;страница с музыкой AY
proc_play_ay_slot3 db 0 ;страница с музыкой AY
scr_cur db 0 ;текущий активный экран
proc_id_focus db 0 ;процесс, у которого фокус (видимый экран и доступно управление)
proc_stack_addr_tmp dw 0 ; временно адрес стека
proc_stack_addr_return_tmp dw 0 ;временно адрес возврата из прерываний
proc_switch_key_flag db 0 ;флаг что нажата клавиша переключения задач
;stack_adr_sys dw 0 ;адрес системного стека
page_slot3_cur db 0 ;текущая страница вы слоте 3
page_slot2_cur db 0 ;текущая страница вы слоте 2
con_scr_cur db 0 ;страница активного экрана пиксели
con_atr_cur db 0 ;страница активного экрана атрибуты
key_cur db 0 ;печатный код нажатой клавиши
file_id_cur db 0 ;временно id файла

proc_id_next db 0 ;код следующего процесса
proc_stack_adr_tmp dw 0 ;временно адрес стека
proc_id_cur db 0 ;id текущего процесса
;proc_id_cur_tmp db 0 ;временно id процесса
proc_sys_name db "SYS        ",0 ;имя системного процесса
proc_cmd_name db "CMD        ",0 ;имя процесса консоль
sys_timer ds 4 ;таймер - счётчик прерываний

	align 256
proc_table ;данные процессов и приложений
	ds proc_descr_size*proc_max ;на командную строку, список страниц и прочее
	;#00 - id процесса
	;#01 - id родительского	
	;#02 - страница #8000
	;#03 - страница #c000	
	;#04 - страница буфер экран пиксели
	;#05 - страница буфер экран атрибуты
	;#06-07 - адрес стека	
	;#08-09 - позиция аппаратного скрола
	;#0a-0b - координаты курсора
	;#0c-0d - цвет текста основной, цвет второй
	;#0e-0f - адрес вызова по прерыванию
	;#0f-1a - Имя

	;..#80 - верх стека

proc_page_table	;таблица занятых процессами страниц
	ds 128 ;у GMX всего 128


esp_link_id_table;_id_table ;таблица соединений ESP
	;0 - id процесса (одновременно флаг "соединение используется")
	;1 - запрос соединения (=1 - активен)
	;2 - результат соединения (=1 - успешно, =255 - ошибка)
	;3 - запрос на отправку (=1 - активен)
	;4 - результат отправки (=1 - успешно, =255 - ошибка)
	;5 - запрос на приём (=1 - активен)
	;6 - результат приёма (=1 - успешно, =255 - ошибка)
	;7-8 - адрес назначения данных (для принятых)
	;9-10 - длина данных
	;11-13 -
	;14 - тип (TCP, UDP, SSL)
	;15-58 - адрес сервера, в конце 0
	;59-63 - порт сервера, в конце 0

	ds 1*esp_link_id_table_size_item ;1 соединение

; esp_buffer_flag ;флаги управления буфером ESP
	; ;0 - буфер занят системным процессом (=1 - идёт передача)
	; ;1-2 - длина данных
	; ds 1



proc_name_01	db "radio.com",0
proc_name_02	db "moonr.com",0
;proc_name_03	db "test.txt",0


;Константы
outputBuffer equ #c000 ;адрес файла для плеера AY
proc_color_def equ 7 ;цвет текста консоли
proc_color2_def equ #c ;цвет текста консоли 2 яркий
function_max equ 41+1 ;всего функций
proc_size_max equ #80 ;максимальный размер приложения старший байт
proc_descr_size equ 256 ;область памяти на одно приложение
proc_max equ 8 ;максимальное количество приложений
page_max equ drvgmx.page_table_end-drvgmx.page_table ;всего доступных страниц из 128
proc_id_system equ 1 ;код системного процесса
;proc_stack equ #4000;адрес стека для процессов
;proc_stack_size equ 128 ;размер стека для процесса
con_scr_real equ #39 ;экран физический
con_atr_real equ #79 ;атрибуты
;page_slot2_def equ 2 ;страница по умолчанию слот 2
;page_slot3_def equ 1 ;страница по умолчанию слот 3
proc_switch_key equ #1b ;код перключения задач sh+Enter
;esp_max_link_id equ 5 ;всего соединений ESP
esp_buffer equ #4000-1500 ;буфер для обмена с ESP
esp_link_id_table_size_item equ 64 ;размер элемента в таблице соединений
	
;Сообщения
msg_init_uart_found
	db "UART #EF found",13,10,0
msg_init_uart_not_found
	db "UART #EF not found",13,10,0
msg_proc_max
	db "Not enough processes",13,10,0
msg_mem_max
	db "Not enough memory",13,10,0



msg_ver_os
	db "OS ver 2024.12.11",13,10,0
	



	

start_sys_incl
	incbin sys.com ;
end_sys_incl

start_cmd_incl
	incbin cmd.com ;
end_cmd_incl

	;Последний перед #4000 буфер для данных от ESP!
	
end_os_main
	SAVETRD "OS.TRD",|"OS.C",start_os_main,$-start_os_main ;сохранить в TRD
	savebin "os.com",start_os_main,$-start_os_main ;сохранить для FAT
	
	;манипуляции для создания hobeta
	org #c000
	incbin os.com
	SAVEHOB "os.$c","os.C",#C000,end_os_main-start_os_main ;
	


	
