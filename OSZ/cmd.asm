;cmd - приложение для OS
   device ZXSPECTRUM128
	include "os_defs.asm"    
	org PROGSTART
start_cmd

	ld hl,msg_title_cmd
	OS_PRINTZ
	
	ld a,5
	ld b,#c
	OS_SET_COLOR
	
	ld hl,msg_title_cmd
	OS_PRINTZ	
	
	ld a,">" ;приглашение
	OS_PRCHARF
	
	
cmd_loop
	halt
	OS_GETCHAR ;получить нажатую клавишу
	cp 255
	jr z,cmd_loop
	cp 13
	jr z,cmd_loop_print
	cp " "
	jr c,cmd_loop ;символы до пробела не печатаем
cmd_loop_print
	OS_PRCHARF ;печать символа
	jr cmd_loop

	
msg_title_cmd
	db "cmd ver 2024 10 17",13,10,0

end_cmd
	;SAVETRD "OS.TRD",|"cmd.C",start_cmd,$-start_cmd
	savebin "cmd.com",start_cmd,$-start_cmd