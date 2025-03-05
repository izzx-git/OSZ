;Terminal - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROGSTART	
	
start_terminal
	; ld a,13 ;новая строка
	; OS_PRINT_CHARF	
	ld hl,msg_title_terminal ;имя приложения
	OS_PRINTZ ;печать


	ld hl,msg_open_port ;открываем порт
	OS_PRINTZ ;печать
terminal_open
	OS_WAIT
	ld a,3 ;прямое соединение с портом
	OS_ESP_OPEN
	jr c,terminal_open
	ld hl,msg_ready ;
	OS_PRINTZ ;печать	
	;основной цикл
terminal_wait
	OS_WAIT
terminal_wait1	
	OS_UART_READ ;прочитать байт из порта
	jr c,terminal_wait_no_input
	OS_PRINT_CHARF ;напечатать если есть что
	jr terminal_wait1 ;и проверить есть ли ещё
terminal_wait_no_input	
	OS_GET_CHAR ;получить клавишу из консоли
	cp 255
	jr z,terminal_wait_no_output
	cp 24 ;break
	jp z,terminal_exit
	cp 13 ;enter
	jp z,terminal_enter
	cp " " ;не печатное
	jr c,terminal_wait_no_output
	push af
	OS_PRINT_CHARF ;напечатать если есть что	
	pop af
	OS_UART_WRITE ;отправить в порт
	;здесь может быть обработка ошибки
	;jr c.
terminal_wait_no_output
	jr terminal_wait ;цикл

	
terminal_enter
	push af
	OS_PRINT_CHARF 	
	pop af
	OS_UART_WRITE	
	ld a,10 ;для ESP надо добавить после 13
	OS_UART_WRITE	
	jr terminal_wait ;цикл	

terminal_exit ;выход в DOS
	xor a
	OS_PROC_CLOSE
;

	
msg_open_port
	db "Open port...",0
	
	
msg_ready
	db "OK",13,0
	
msg_title_terminal
	db "Terminal ver 2025.02.12",13,0
	

end_terminal
	savebin "terminal.apg",start_terminal,$-start_terminal