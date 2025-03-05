    MODULE ModProcessor
    ifdef GS
	
    macro GS_WaitCommand2
.wait
    in a, (CMD)
    rrca
    jr c, .wait
    endm

    macro GS_SendCommand2 nn
    ld a, nn : out (CMD), a
    endm
	
play:
    call Console.waitForKeyUp

    ld hl, Gopher.requestbuffer : call DialogBox.msgNoWait

    ;ld a, 1, (Render.play_next), a 
	xor a
	ld (last_song_position),a

.loop
    OS_WAIT : 
    OS_GET_CHAR
	cp " " ;пробел
	jp z, .stopKey
	call printRTC
    ;проверка что MOD начал играть сначала
    GS_SendCommand2 CMD_GET_SONG_POSITION
    GS_WaitCommand2
	ld a,(last_song_position) ;предыдущая позиция
	ld c,a
	in a,(DATA) ;текущая позиция
	ld (last_song_position),a
	cp c
	jr nc, .loop ;если не меньше, продолжаем играть
    ld a, 1, (Render.play_next), a ;флаг что надо будет играть следующий файл
.stop
    call GeneralSound.stopModule
    
    call Console.waitForKeyUp
    ret
.stopKey
    xor a : ld (Render.play_next), a ;флаг что не надо играть следующий файл
    jr .stop


;message db "Press key to stop...", 0


CMD_GET_SONG_POSITION     = #60	
last_song_position db 0

;; Control ports
CMD  = 187
DATA = 179

    endif
    ENDMODULE

    