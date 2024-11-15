    module ScreenViewer
display:
    call Console.waitForKeyUp
    ;ld a, 7 : call Memory.setPage
    ld hl, outputBuffer+6912, de, #c000+6912, bc, 6912 : lddr
	OS_GET_MAIN_PAGES
	ld a,c
	ld b,7
	OS_PAGE_COPY
    ;call TextMode.disable
	ld a,7
	OS_SET_SCR
.wait
	halt
	OS_GETCHAR
	cp 255
	jr z, .wait
	ld a,#39
	OS_SET_SCR
    ;call TextMode.cls
    jp History.back

    endmodule