    module ScreenViewer
display:
    call Console.waitForKeyUp
    ;ld a, 7 : call Memory.setPage
    ;ld hl, outputBuffer+6912, de, #c000+6912, bc, 6912 : lddr
	OS_GET_MAIN_PAGES
	ld a,b ; страница с буфером
	ld b,7 ;страница назначения
	ld hl,outputBuffer 
	ld de,#c000
	ld ix,6912
	OS_RAM_COPY
    ;call TextMode.disable
display_wait
	ld a,7
	OS_SET_SCREEN ;включить экран
	jr nc,.wait
	OS_WAIT
	jr display_wait
.wait
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z, .wait
	ld a,0 ;текстовый
	OS_SET_SCREEN
    ;call TextMode.cls
    jp History.back

    endmodule