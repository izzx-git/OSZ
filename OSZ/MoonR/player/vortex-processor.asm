    MODULE VortexProcessor
play:
    call Console.waitForKeyUp

    ld hl, message : call DialogBox.msgNoWait

    ld hl, outputBuffer  : OS_VTPL_INIT

    
    ld a, 1, (Render.play_next), a
    ifdef GS
    call GeneralSound.stopModule
    endif
	OS_VTPL_PLAY
.loop
    halt :; di : call VTPL.PLAY : ei
	OS_GET_CHAR
	cp " " ;останов по пробелу
	jp z, .stopKey
	call printRTC
	OS_GET_VTPL_SETUP
    ld a, (hl) : 
	rla : jr nc, .loop 
    ld a, 1, (Render.play_next), a
.stop
	OS_VTPL_MUTE
    
    IFDEF AY
    call restoreAyState
    ENDIF

    call Console.waitForKeyUp
    ret
.stopKey
    xor a : ld (Render.play_next), a
    jr .stop

    IFDEF AY
restoreAyState:
    ld a, #07
    ld bc, #fffd
    out (c), a
    ld a, #fc
    ld b, #bf
    out (c), a ; Enable read mode
    
    ld a, #0e
    ld bc, #fffd
    out (c), a
    ret
    ENDIF 

message db "Press key to stop...", 0
    ENDMODULE
    ;include "player.asm"
    