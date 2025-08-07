    ; module ScreenViewer
display:
    ; call Console.waitForKeyUp
	
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
	
	ret
    ;jp History.back

;    endmodule
