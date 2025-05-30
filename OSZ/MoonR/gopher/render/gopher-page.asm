renderGopherScreen:
    call Render.prepareScreen
	
	;поиск и печать первой нужной строки
    ld a, (page_offset) : ld b, a : call findLine ;поиск с начала буфера
    ld a, h : or l : jr z, .exit2
    xor a : push hl : call renderRow : pop hl ;печать строки 0
	;теперь поиск продолжается 
	
    ld b, PER_PAGE-1 ;одну строку уже обработали
.loop
    push bc
    ld a, PER_PAGE : sub b
    ld e, a : ld b, 1 : call findLine2 ;поиск одной следующей
    ld a, h : or l : jr z, .exit
    ld a, e : push hl: call renderRow : pop hl ;указатель hl надо сохранить
.exit
    pop bc 
    djnz .loop
.exit2
    call showCursor
    ret

checkBorder:
    ld a, (cursor_position) : cp #ff : jp z, pageUp
    ld a, (cursor_position) : cp PER_PAGE : jp z, pageDn
    call showCursor
    jp workLoop

workLoop:
    ld a, (play_next) : and a : jp nz, navigate

    ; dup 4
    ; halt
    ; edup
.nothing
	OS_WAIT
	call printRTC
    call Console.peekC
    cp 255 : jr z, .nothing

    cp Console.KEY_DN : jp z, cursorDown
    cp 'a' : jp z, cursorDown
    cp Console.KEY_UP : jp z, cursorUp
    cp 'q' : jp z, cursorUp
    cp Console.KEY_LT : jp z, pageUp
    cp 'o' : jp z, pageUp
    cp Console.KEY_RT : jp z, pageDn
    cp 'p' : jp z, pageDn

    cp 'h' : jp z, History.home
    cp 'H' : jp z, History.home

    cp 'b' : jp z, History.back
    cp 'B' : jp z, History.back
    cp Console.BACKSPACE : jp z, History.back

    cp 'd' : jp z, inputHost
    cp 'D' : jp z, inputHost

    cp CR : jp z, navigate

    ifdef GS
    cp 'M' : call z, GeneralSound.toggleModule
    cp 'm' : call z, GeneralSound.toggleModule
    endif
    
	cp 'S' : call z, toggleSaveMode
	cp 's' : call z, toggleSaveMode
	
    jp workLoop

navigate:
    call Console.waitForKeyUp
    xor a : ld (play_next), a
    
    call hideCursor
    ld a, (page_offset), b, a, a, (cursor_position) : add b : ld b, a : call Render.findLine
    ld a, (hl)
    cp '1' : jp z, .load
    cp '0' : jp z, .load
    cp '9' : jp z, .load
    cp '7' : jp z, .input
    call showCursor
    jp workLoop
.load
    push hl
    call getIcon 
    pop hl
    jp History.navigate
.input
    push hl
    call DialogBox.inputBox
    pop hl
    ld a, (DialogBox.inputBuffer) : and a : jp z, History.load
    jr .load

showCursor:
    ld a, (cursor_position) : add CURSOR_OFFSET
    jp TextMode.highlightLine

hideCursor:
    ld a, (cursor_position) : add CURSOR_OFFSET
    jp TextMode.usualLine

cursorDown:
    call hideCursor
    ld hl, cursor_position
    inc (hl)
    jp checkBorder

cursorUp:
    call hideCursor
    ld hl, cursor_position
    dec (hl)
    jp checkBorder

pageUp:
    ld a, (page_offset) : and a : jr z, .skip
    ld a, PER_PAGE - 1 : ld (cursor_position), a
    ld a, (page_offset) : sub PER_PAGE : ld (page_offset), a
.exit
    call renderGopherScreen
    jp workLoop
.skip
    xor a : ld (cursor_position), a : call renderGopherScreen : jp workLoop

pageDn:
    xor a : ld (cursor_position), a 
    ld a, (page_offset) : add PER_PAGE : ld (page_offset), a
    jr pageUp.exit