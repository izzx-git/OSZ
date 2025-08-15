    ; module ScreenViewer
display:
    ; call Console.waitForKeyUp
	
	ld hl,file_name_cur		;строка с именем	
	OS_FILE_OPEN
	jr nc,display_file_open_ok
display_file_error
	ld hl,msg_file_error
	OS_PRINTZ	
	; ld b,2*50
	; call delay1
	scf ;ошибка
	ret
	
display_file_open_ok
	ld (file_id_cur_r),a
	
	ld a,(page_ext01) ;доп страница
	OS_SET_PAGE_SLOT3
	
	ld a,(file_id_cur_r)
	ld de,6912
	ld hl,#c000
	;ld a,(file_id_cur_r)
	OS_FILE_READ ;загрузить
	jr c,display_file_error	
	ld a,(file_id_cur_r)
	OS_FILE_CLOSE
	
display_wait1
	ld a,7
	OS_SET_SCREEN ;включить экран
	jr nc,display_wait1_ok
	OS_WAIT
	jr display_wait1 ;пока не получилось, может не в фокусе приложение
 
display_wait1_ok
 
	ld a,(page_ext01) ;доп страница для данных плеера
	ld b,7 ;страница назначения
	ld hl,#8000
	ld de,#c000
	ld ix,6912
	OS_RAM_COPY
    ;call TextMode.disable
.wait
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z, .wait
	xor a ;текстовый экран
	OS_SET_SCREEN
    ;call TextMode.cls
	
	
	ld a,(page_main) ;основная страница
	OS_SET_PAGE_SLOT3
	
	xor a ;ok
	ret
    ;jp History.back

;    endmodule
