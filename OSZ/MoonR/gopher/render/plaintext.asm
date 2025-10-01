renderPlainTextScreen:
    call prepareScreen
	
	;поиск и печать первой нужной строки
    ld a, (page_offset) : ld b, a : call findLine ;поиск с начала буфера
    ld a, h : or l : jr z, .exit2
    xor a 
    add CURSOR_OFFSET : ld d, a, e, 1 : call TextMode.gotoXY
    call print70Text
	;теперь поиск продолжается 	
	
    ld b, PER_PAGE-1
.loop
    push bc
    ld a, PER_PAGE : sub b
    ld e, a : ld b, 1 : call Render.findLine2
    ld a, h : or l : jr z, .exit
    ld a, e
    add CURSOR_OFFSET : ld d, a, e, 1 : call TextMode.gotoXY
    call print70Text
    pop bc 
    djnz .loop
    ret
.exit
    pop bc
.exit2	
    ret

plainTextLoop:
    call Console.getC
    
    cp Console.KEY_DN : jp z, textDown
    cp 'a' : jp z, textDown

    cp Console.KEY_UP : jp z, textUp
    cp 'q' : jp z, textUp
    
    cp 'h' : jp z, History.home
    cp 'H' : jp z, History.home

    cp 'b' : jp z, History.back
    cp 'B' : jp z, History.back
    
    cp Console.BACKSPACE : jp z, History.back
 
    ifdef GS
    cp 'M' : call z, GeneralSound.toggleModule
    cp 'm' : call z, GeneralSound.toggleModule
    endif

    cp 'S' : call z, toggleSaveMode
	cp 's' : call z, toggleSaveMode
	
	cp 24
	jp z,exit_dos
	
    jr plainTextLoop


textDown:
    ld a, (page_offset) : add PER_PAGE : ld (page_offset), a
    call renderPlainTextScreen
    jp plainTextLoop

textUp:
    ld hl, page_offset 
    ld a, (hl) : and a : jr z, plainTextLoop
    sub PER_PAGE : ld (hl), a
    call renderPlainTextScreen
    jp plainTextLoop