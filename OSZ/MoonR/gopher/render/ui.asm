prepareScreen:
    call TextMode.cls
    ld hl, header : call TextMode.printZ
    ld hl, toolbox : call TextMode.printZ
    ld hl, hostName : call TextMode.printZ
    ld de, #1700 : call TextMode.gotoXY : ld hl, footer : call TextMode.printZ

    xor a : call TextMode.highlightLine
    ld a, 1 : call TextMode.highlightLine
    ld a, #17 : call TextMode.highlightLine
    ret


toolbox db " [D]omain: ", 0
footer db "  Cursor - movement  [B]ack to prev. page  [H]ome page", 0

inputHost:
    call Console.waitForKeyUp
.loop
    ld de, #010B : call TextMode.gotoXY : ld hl, hostName : call TextMode.printZ
    ld a, MIME_INPUT : call TextMode.putC
    ld a, ' ' : call TextMode.putC
.wait
    call Console.getC
    ld e, a
    cp Console.BACKSPACE : jr z, .removeChar
    cp CR : jp z, inputNavigate
    cp 32 : jr c, .wait
.putC
    xor a : ld hl, hostName, bc, 48 : cpir
    ld (hl), a : dec hl : ld (hl), e 
    jr .loop
.removeChar
    xor a
    ld hl, hostName, bc, 48 : cpir
    dec hl : dec hl : ld (hl), a 
    jr .loop

inputNavigate:
    ld hl, hostName, de, domain
    ld a,(hl)
    and a
    jp z, History.load
.loop
    ld a, (hl) : and a : jr z, .complete
    ld (de), a : inc hl, de
    jr .loop
.complete
    ld a, TAB : ld (de), a : inc de
    ld a, '7' : ld (de), a : inc de
    ld a, '0' : ld (de), a : inc de
    ld a, CR : ld (de), a : inc de
    ld a, LF : ld (de), a : inc de
    ld hl, navRow : jp History.navigate

navRow db "1 ", TAB, "/", TAB
domain db "nihirash.net" 
    ds 64 - ($ - domain)

    IFDEF MB03
header db "      Moon Rabbit "
       db VERSION_STRING
       db " for MB03+  (c) 2021 Alexander Nihirash",13, 0
    ENDIF
    
    IFDEF UNO
header db "      Moon Rabbit "
       db VERSION_STRING
       db " for ZX-Uno (c) 2021 Alexander Nihirash",13, 0
    ENDIF

    IFDEF AY
header db "      Moon Rabbit "
       db VERSION_STRING
       db " for AYWIFI (c) 2021 Alexander Nihirash",13, 0
    ENDIF
	
    IFDEF ZW
header db "      Moon Rabbit "
       db VERSION_STRING
       db " for ZX WiFi (c) 2021 Alexander Nihirash",13, 0
    ENDIF