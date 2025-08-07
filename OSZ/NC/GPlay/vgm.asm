        ;DEVICE ZXSPECTRUM48
        ;include "../../../_sdk/sys_h.asm"
        ;       ORG PROGSTART ;0x4000



;memorystreamcurrentpage = 0x5100
;current_ram_page = 0x5100  


AREA_C000_FFFF   equ 1



module = $C000



begin
START
        	LD HL,module;MDLADDR ;DE - address of 2nd module for TS
        	JR INIT
        	JP PLAY
        	JP MUTE
INIT:
        jp init_

DEVICE_AY_BIT         = 0
DEVICE_TURBOSOUND_BIT = 1
DEVICE_TFM_BIT        = 2
DEVICE_MOONSOUND_BIT  = 3
DEVICE_GS_BIT         = 4
DEVICE_NEOGS_BIT      = 5
DEVICE_MIDI_UART_BIT  = 6

DEVICE_AY_MASK         = 1<<DEVICE_AY_BIT
DEVICE_TURBOSOUND_MASK = 1<<DEVICE_TURBOSOUND_BIT
DEVICE_TFM_MASK        = 1<<DEVICE_TFM_BIT
DEVICE_MOONSOUND_MASK  = 1<<DEVICE_MOONSOUND_BIT
DEVICE_GS_MASK         = 1<<DEVICE_GS_BIT
DEVICE_NEOGS_MASK      = 1<<DEVICE_NEOGS_BIT
DEVICE_MIDI_UART_MASK  = 1<<DEVICE_MIDI_UART_BIT





HEADER_DATA_OFFSET = module+0x34 ;0xC034
HEADER_LOOP_SAMPLES_COUNT = module+0x20 ;0xC020
HEADER_GD3_OFFSET = module+0x14 ;0xC014
HEADER_SAMPLES_COUNT = module+0x18 ;0xC018
HEADER_LOOP_OFFSET = module+0x1c ;0xC01c


HEADER_SIZE_MAX = 256
TITLELENGTH = 64
MEMORYSTREAMMAXPAGES = 210
MEMORYSTREAMERRORMASK = 255 ; TODO: do we need to enforce loading the entire file?
ENABLE_FM = 1







        align 256   ;0x8100 ;0x4100
        display "s98_file00_pages_list ",$

memorystreampages: ds 256,0
memorystreampagecount = memorystreampages + 255

	include "common/memorystream.asm"
	include "common/opl4.asm"
	include "common/opm.asm"
	include "vgm/opl4.asm"
	include "common/opn.asm"
	include "vgm/opn.asm"
	include "vgm/opm.asm"
	include "vgm/ssg.asm"






waittimer50hz
	;YIELD
	OS_WAIT
	ret


waveheaderbuffer = 0xc000-2048 ;0x5400 ;текущий размер буфера 1536 (128*12)
waveheaderbufferend = waveheaderbuffer+WAVEHEADERBUFFERSIZE
vgmheadercopy = waveheaderbufferend
vgmheadercopyend = vgmheadercopy+HEADER_SIZE_MAX ;(ещё 256)

titlestr = waveheaderbufferend
titlestrend = titlestr+TITLELENGTH


HEADER_CLOCK_YM2203 = vgmheadercopy+0x44
HEADER_CLOCK_YM3812 = vgmheadercopy+0x50
HEADER_CLOCK_YMF262 = vgmheadercopy+0x5c
HEADER_CLOCK_YMF278B = vgmheadercopy+0x60
HEADER_CLOCK_AY8910 = vgmheadercopy+0x74


	macro a_or_dw addr
	ld hl,(addr+0)
	or h
	or l
	ld de,(addr+2)
	or d
	or e
	endm

	macro set_timer wait,ticks
	ld hl,ticks
	ld (waittimerstep),hl
	endm


init_:
	set_timer waittimer50hz,882
	ld hl,0
	ld (waitcounterlo),hl
	xor a
	ld (waitcounterhi),a
	ld (devicemask),a

      	ld (vgm_play_var),a
;map header to 0x8000
        ;first page (vgm_header) now in page_plr3
        ;now do init.
        
;copy header
	ld bc,HEADER_SIZE_MAX
	ld hl,vgmheadercopy
	ld de,vgmheadercopy+1
	ld (hl),0
	ldir
	ld hl,(HEADER_DATA_OFFSET)  ;если HEADER_DATA_OFFSET == 0 to bc = 0x0040 иначе  bc = 0x0034
	ld a,h
	or l
	ld bc,0x40
	jr z,$+4
	ld c,0x34
	add hl,bc
	ld (.dataoffset),hl
              ;определяем сколько данных заголовка vgm нужно перекинуть в буфер исходя из значения HEADER_DATA_OFFSET
	ld bc,hl
	ld hl,-HEADER_SIZE_MAX-1
	add hl,bc
	jr nc,$+5
	ld bc,HEADER_SIZE_MAX

	ld hl,module
	ld de,vgmheadercopy
	ldir
;setup loop
	xor a
	a_or_dw HEADER_LOOP_OFFSET
	ld (loopoffsetlo),hl
	ld (loopoffsethi),de
;init Moonsound
	xor a
	a_or_dw HEADER_CLOCK_YM3812
	ld (useYM3812),a
	a_or_dw HEADER_CLOCK_YMF262
	jr nz,.opl4notneeded
	a_or_dw HEADER_CLOCK_YMF278B
	jr z,.opl4notneeded
	ld a,(moonsoundstatus)
	cp 2
	ret nz ;jp nz,memorystreamfree ;sets zf=0
	or a
.opl4notneeded
	call nz,initYMF278B
	ret nz  ;jp nz,memorystreamfree ;sets zf=0
.dataoffset=$+1
	ld hl,0
	ld de,0
        ;init music
	call memorystreamseek
devicemask=$+1
	ld a,0
;zf=0 if there isn't any supported device
	dec a
	ret m
	inc a
	cp a
	ret








MUTE:
                ld a,$C9			;ret	;stop playing
                ld (vgm_play_var),a
		ld a,(devicemask)
		and DEVICE_MOONSOUND_MASK
		call nz,opl4mute
                ret







PLAY:
;out: zf=0 if still playing, zf=1 otherwise
;waittimercallback=$+1
;	call 0

vgm_play_var = $ : nop		;nop - play
        ld a,0                          ;(memorystreamcurrentpage)
memorystreamcurrentpage equ $-1
        IF AREA_C000_FFFF=1
            ;SETPGC000
			OS_SET_PAGE_SLOT3
        ELSE
            SETPG8000
        ENDIF
playloop
waitcounterlo=$+1
	ld hl,0
waitcounterhi=$+1
	ld a,0
waittimerstep=$+1
	ld bc,0
	sub hl,bc
	ld d,0
	sbc a,d
	jr nc,exitplayloop
;read command
	memory_stream_read_1 e
	ld hl,cmdtable
	add hl,de
	ld e,(hl)
	inc h
	ld d,(hl)
	ld hl,playloop
	push hl
	ex hl,de
	jp (hl)

exitplayloop
	ld (waitcounterlo),hl
	ld (waitcounterhi),a
;continue playing
	or 1
	ret

wait1	ld hl,waitcounterlo
	inc (hl)
	ret nz
	inc hl
	inc (hl)
	ret nz
	ld hl,waitcounterhi
	inc (hl)
	ret

wait2	ld a,2
waitn	ld hl,waitcounterlo
	add a,(hl)
	ld (hl),a
	ret nc
	inc hl
	inc (hl)
	ret nz
	ld hl,waitcounterhi
	inc (hl)
	ret

wait3	ld a,3  : jp waitn
wait4	ld a,4  : jp waitn
wait5	ld a,5  : jp waitn
wait6	ld a,6  : jp waitn
wait7	ld a,7  : jp waitn
wait8	ld a,8  : jp waitn
wait9	ld a,9  : jp waitn
wait10	ld a,10 : jp waitn
wait11	ld a,11 : jp waitn
wait12	ld a,12 : jp waitn
wait13	ld a,13 : jp waitn
wait14	ld a,14 : jp waitn
wait15	ld a,15 : jp waitn
wait16	ld a,16 : jp waitn

wait735	ld de,735
waitnn	ld hl,(waitcounterlo)
	add hl,de
	ld (waitcounterlo),hl
	ret nc
	ld hl,waitcounterhi
	inc (hl)
	ret

wait882	ld de,882
	jp waitnn

waitvar	memory_stream_read_2 e,d
	ld hl,(waitcounterlo)
	add hl,de
	ld (waitcounterlo),hl
	ret nc
	ld hl,waitcounterhi
	inc (hl)
	ret

	macro skip_n n
	ld b,n
	jp memorystreamskip
	endm

skip1	ret
skip2	skip_n 1
skip3	skip_n 2
skip4	skip_n 3
skip5	skip_n 4
skip6	skip_n 5
skip11	skip_n 10
skip12	skip_n 11


endofsounddata
      ;  jp seektoloop ;здесь зацикливание, повтор
	  call PLR_MUTE ;выключить звук 
cmdunsupported
;stop playing
	pop af
	xor a
	ret

cmdYM2203
	memory_stream_read_2 e,d
	jp opnwritemusiconlyfm1

cmdYM2203dp
	memory_stream_read_2 e,d
	jp opnwritemusiconlyfm2

cmdYMF278B
	memory_stream_read_3 c,e,d
	dec c
	jp z,opl4writemusiconlyfm2
	jp p,opl4writewavemusiconly
	jp opl4writemusiconlyfm1

cmdYMF262p0
cmdYM3812
cmdY8950
cmdYM3526
	memory_stream_read_2 e,d
	jp opl4writemusiconlyfm1

cmdYMF262p1
cmdYM3812dp
cmdY8950dp
cmdYM3526dp
	memory_stream_read_2 e,d
	jp opl4writemusiconlyfm2

cmdYM2151
	memory_stream_read_2 e,d
	jp opmwritemusiconlychip0

cmdYM2151dp
	memory_stream_read_2 e,d
	jp opmwritemusiconlychip1

cmdAY8910
	memory_stream_read_2 e,d
	bit 7,e
	jp z,ssgwritemusiconlychip0
	res 7,e
	jp ssgwritemusiconlychip1

cmdYMF262dp0 equ memorystreamread2
cmdYMF262dp1 equ memorystreamread2

cmddatablock
	memory_stream_read_2 a,e ;a = 0x66 guard, e = type
	cp 0x66
	jp nz,cmdunsupported
processdatablock
;e = data type
	call memorystreamread4 ;adbc = data size
	ld a,e
	ld hl,bc
;	cp 0x81
;	jp z,opnaloaddatablock
	cp 0x84
	jp z,opl4loadromdatablock
	cp 0x87
	jp z,opl4loadramdatablock
	push de
	push bc
	call memorystreamgetpos
	pop bc
	pop af
	add hl,bc
	adc a,e
	ld e,a
	adc a,d
	sub e
	ld d,a
	jp memorystreamseek


seektoloop
	ld bc,0x1c
loopoffsethi=$+1
	ld de,0
loopoffsetlo=$+1
	ld hl,0
seektopos
;dehl + bc = position
;out: hl = read address
	add hl,bc
	jp nc,memorystreamseek
	inc de
	jp memorystreamseek




cmdtable
	db skip1           %256 ; 00
	db skip1           %256 ; 01
	db skip1           %256 ; 02
	db skip1           %256 ; 03
	db skip1           %256 ; 04
	db skip1           %256 ; 05
	db skip1           %256 ; 06
	db skip1           %256 ; 07
	db skip1           %256 ; 08
	db skip1           %256 ; 09
	db skip1           %256 ; 0A
	db skip1           %256 ; 0B
	db skip1           %256 ; 0C
	db skip1           %256 ; 0D
	db skip1           %256 ; 0E
	db skip1           %256 ; 0F
	db skip1           %256 ; 10
	db skip1           %256 ; 11
	db skip1           %256 ; 12
	db skip1           %256 ; 13
	db skip1           %256 ; 14
	db skip1           %256 ; 15
	db skip1           %256 ; 16
	db skip1           %256 ; 17
	db skip1           %256 ; 18
	db skip1           %256 ; 19
	db skip1           %256 ; 1A
	db skip1           %256 ; 1B
	db skip1           %256 ; 1C
	db skip1           %256 ; 1D
	db skip1           %256 ; 1E
	db skip1           %256 ; 1F
	db skip1           %256 ; 20
	db skip1           %256 ; 21
	db skip1           %256 ; 22
	db skip1           %256 ; 23
	db skip1           %256 ; 24
	db skip1           %256 ; 25
	db skip1           %256 ; 26
	db skip1           %256 ; 27
	db skip1           %256 ; 28
	db skip1           %256 ; 29
	db skip1           %256 ; 2A
	db skip1           %256 ; 2B
	db skip1           %256 ; 2C
	db skip1           %256 ; 2D
	db skip1           %256 ; 2E
	db skip1           %256 ; 2F
	db cmdunsupported  %256 ; 30
	db skip2           %256 ; 31
	db skip2           %256 ; 32
	db skip2           %256 ; 33
	db skip2           %256 ; 34
	db skip2           %256 ; 35
	db skip2           %256 ; 36
	db skip2           %256 ; 37
	db skip2           %256 ; 38
	db skip2           %256 ; 39
	db skip2           %256 ; 3A
	db skip2           %256 ; 3B
	db skip2           %256 ; 3C
	db skip2           %256 ; 3D
	db skip2           %256 ; 3E
	db skip2           %256 ; 3F
	db skip3           %256 ; 40
	db skip3           %256 ; 41
	db skip3           %256 ; 42
	db skip3           %256 ; 43
	db skip3           %256 ; 44
	db skip3           %256 ; 45
	db skip3           %256 ; 46
	db skip3           %256 ; 47
	db skip3           %256 ; 48
	db skip3           %256 ; 49
	db skip3           %256 ; 4A
	db skip3           %256 ; 4B
	db skip3           %256 ; 4C
	db skip3           %256 ; 4D
	db skip3           %256 ; 4E
	db skip2           %256 ; 4F
	db cmdunsupported  %256 ; 50
	db cmdunsupported  %256 ; 51
	db cmdunsupported  %256 ; 52
	db cmdunsupported  %256 ; 53
	db cmdYM2151       %256 ; 54
	db cmdYM2203       %256 ; 55
	db cmdYM2608p0     %256 ; 56
	db cmdYM2608p1     %256 ; 57
	db cmdunsupported  %256 ; 58
	db cmdunsupported  %256 ; 59
	db cmdYM3812       %256 ; 5A
	db cmdYM3526       %256 ; 5B
	db cmdY8950        %256 ; 5C
	db skip3           %256 ; 5D
	db cmdYMF262p0     %256 ; 5E
	db cmdYMF262p1     %256 ; 5F
	db cmdunsupported  %256 ; 60
	db waitvar         %256 ; 61
	db wait735         %256 ; 62
	db wait882         %256 ; 63
	db cmdunsupported  %256 ; 64
	db cmdunsupported  %256 ; 65
	db endofsounddata  %256 ; 66
	db cmddatablock    %256 ; 67
	db skip12          %256 ; 68
	db cmdunsupported  %256 ; 69
	db cmdunsupported  %256 ; 6A
	db cmdunsupported  %256 ; 6B
	db cmdunsupported  %256 ; 6C
	db cmdunsupported  %256 ; 6D
	db cmdunsupported  %256 ; 6E
	db cmdunsupported  %256 ; 6F
	db wait1           %256 ; 70
	db wait2           %256 ; 71
	db wait3           %256 ; 72
	db wait4           %256 ; 73
	db wait5           %256 ; 74
	db wait6           %256 ; 75
	db wait7           %256 ; 76
	db wait8           %256 ; 77
	db wait9           %256 ; 78
	db wait10          %256 ; 79
	db wait11          %256 ; 7A
	db wait12          %256 ; 7B
	db wait13          %256 ; 7C
	db wait14          %256 ; 7D
	db wait15          %256 ; 7E
	db wait16          %256 ; 7F
	db skip1           %256 ; 80
	db wait1           %256 ; 81
	db wait2           %256 ; 82
	db wait3           %256 ; 83
	db wait4           %256 ; 84
	db wait5           %256 ; 85
	db wait6           %256 ; 86
	db wait7           %256 ; 87
	db wait8           %256 ; 88
	db wait9           %256 ; 89
	db wait10          %256 ; 8A
	db wait11          %256 ; 8B
	db wait12          %256 ; 8C
	db wait13          %256 ; 8D
	db wait14          %256 ; 8E
	db wait15          %256 ; 8F
	db skip5           %256 ; 90
	db skip5           %256 ; 91
	db skip6           %256 ; 92
	db skip11          %256 ; 93
	db skip2           %256 ; 94
	db skip5           %256 ; 95
	db cmdunsupported  %256 ; 96
	db cmdunsupported  %256 ; 97
	db cmdunsupported  %256 ; 98
	db cmdunsupported  %256 ; 99
	db cmdunsupported  %256 ; 9A
	db cmdunsupported  %256 ; 9B
	db cmdunsupported  %256 ; 9C
	db cmdunsupported  %256 ; 9D
	db cmdunsupported  %256 ; 9E
	db cmdunsupported  %256 ; 9F
	db cmdAY8910       %256 ; A0
	db skip3           %256 ; A1
	db cmdunsupported  %256 ; A2
	db cmdunsupported  %256 ; A3
	db cmdYM2151dp     %256 ; A4
	db cmdYM2203dp     %256 ; A5
	db skip3           %256 ; A6
	db skip3           %256 ; A7
	db skip3           %256 ; A8
	db skip3           %256 ; A9
	db cmdYM3812dp     %256 ; AA
	db cmdYM3526dp     %256 ; AB
	db cmdY8950dp      %256 ; AC
	db skip3           %256 ; AD
	db cmdYMF262dp0    %256 ; AE
	db cmdYMF262dp0    %256 ; AF
	db skip3           %256 ; B0
	db skip3           %256 ; B1
	db skip3           %256 ; B2
	db skip3           %256 ; B3
	db skip3           %256 ; B4
	db skip3           %256 ; B5
	db skip3           %256 ; B6
	db skip3           %256 ; B7
	db skip3           %256 ; B8
	db skip3           %256 ; B9
	db skip3           %256 ; BA
	db skip3           %256 ; BB
	db skip3           %256 ; BC
	db skip3           %256 ; BD
	db skip3           %256 ; BE
	db skip3           %256 ; BF
	db skip4           %256 ; C0
	db skip4           %256 ; C1
	db skip4           %256 ; C2
	db skip4           %256 ; C3
	db skip4           %256 ; C4
	db skip4           %256 ; C5
	db skip4           %256 ; C6
	db skip4           %256 ; C7
	db skip4           %256 ; C8
	db skip4           %256 ; C9
	db skip4           %256 ; CA
	db skip4           %256 ; CB
	db skip4           %256 ; CC
	db skip4           %256 ; CD
	db skip4           %256 ; CE
	db skip4           %256 ; CF
	db cmdYMF278B      %256 ; D0
	db skip4           %256 ; D1
	db cmdunsupported  %256 ; D2
	db skip4           %256 ; D3
	db skip4           %256 ; D4
	db skip4           %256 ; D5
	db skip4           %256 ; D6
	db skip4           %256 ; D7
	db skip4           %256 ; D8
	db skip4           %256 ; D9
	db skip4           %256 ; DA
	db skip4           %256 ; DB
	db skip4           %256 ; DC
	db skip4           %256 ; DD
	db skip4           %256 ; DE
	db skip4           %256 ; DF
	db cmdunsupported  %256 ; E0
	db skip5           %256 ; E1
	db skip5           %256 ; E2
	db skip5           %256 ; E3
	db skip5           %256 ; E4
	db skip5           %256 ; E5
	db skip5           %256 ; E6
	db skip5           %256 ; E7
	db skip5           %256 ; E8
	db skip5           %256 ; E9
	db skip5           %256 ; EA
	db skip5           %256 ; EB
	db skip5           %256 ; EC
	db skip5           %256 ; ED
	db skip5           %256 ; EE
	db skip5           %256 ; EF
	db skip5           %256 ; F0
	db skip5           %256 ; F1
	db skip5           %256 ; F2
	db skip5           %256 ; F3
	db skip5           %256 ; F4
	db skip5           %256 ; F5
	db skip5           %256 ; F6
	db skip5           %256 ; F7
	db skip5           %256 ; F8
	db skip5           %256 ; F9
	db skip5           %256 ; FA
	db skip5           %256 ; FB
	db skip5           %256 ; FC
	db skip5           %256 ; FD
	db skip5           %256 ; FE
	db skip5           %256 ; FF
	db skip1           /256 ; 00
	db skip1           /256 ; 01
	db skip1           /256 ; 02
	db skip1           /256 ; 03
	db skip1           /256 ; 04
	db skip1           /256 ; 05
	db skip1           /256 ; 06
	db skip1           /256 ; 07
	db skip1           /256 ; 08
	db skip1           /256 ; 09
	db skip1           /256 ; 0A
	db skip1           /256 ; 0B
	db skip1           /256 ; 0C
	db skip1           /256 ; 0D
	db skip1           /256 ; 0E
	db skip1           /256 ; 0F
	db skip1           /256 ; 10
	db skip1           /256 ; 11
	db skip1           /256 ; 12
	db skip1           /256 ; 13
	db skip1           /256 ; 14
	db skip1           /256 ; 15
	db skip1           /256 ; 16
	db skip1           /256 ; 17
	db skip1           /256 ; 18
	db skip1           /256 ; 19
	db skip1           /256 ; 1A
	db skip1           /256 ; 1B
	db skip1           /256 ; 1C
	db skip1           /256 ; 1D
	db skip1           /256 ; 1E
	db skip1           /256 ; 1F
	db skip1           /256 ; 20
	db skip1           /256 ; 21
	db skip1           /256 ; 22
	db skip1           /256 ; 23
	db skip1           /256 ; 24
	db skip1           /256 ; 25
	db skip1           /256 ; 26
	db skip1           /256 ; 27
	db skip1           /256 ; 28
	db skip1           /256 ; 29
	db skip1           /256 ; 2A
	db skip1           /256 ; 2B
	db skip1           /256 ; 2C
	db skip1           /256 ; 2D
	db skip1           /256 ; 2E
	db skip1           /256 ; 2F
	db cmdunsupported  /256 ; 30
	db skip2           /256 ; 31
	db skip2           /256 ; 32
	db skip2           /256 ; 33
	db skip2           /256 ; 34
	db skip2           /256 ; 35
	db skip2           /256 ; 36
	db skip2           /256 ; 37
	db skip2           /256 ; 38
	db skip2           /256 ; 39
	db skip2           /256 ; 3A
	db skip2           /256 ; 3B
	db skip2           /256 ; 3C
	db skip2           /256 ; 3D
	db skip2           /256 ; 3E
	db skip2           /256 ; 3F
	db skip3           /256 ; 40
	db skip3           /256 ; 41
	db skip3           /256 ; 42
	db skip3           /256 ; 43
	db skip3           /256 ; 44
	db skip3           /256 ; 45
	db skip3           /256 ; 46
	db skip3           /256 ; 47
	db skip3           /256 ; 48
	db skip3           /256 ; 49
	db skip3           /256 ; 4A
	db skip3           /256 ; 4B
	db skip3           /256 ; 4C
	db skip3           /256 ; 4D
	db skip3           /256 ; 4E
	db skip2           /256 ; 4F
	db cmdunsupported  /256 ; 50
	db cmdunsupported  /256 ; 51
	db cmdunsupported  /256 ; 52
	db cmdunsupported  /256 ; 53
	db cmdYM2151       /256 ; 54
	db cmdYM2203       /256 ; 55
	db cmdYM2608p0     /256 ; 56
	db cmdYM2608p1     /256 ; 57
	db cmdunsupported  /256 ; 58
	db cmdunsupported  /256 ; 59
	db cmdYM3812       /256 ; 5A
	db cmdYM3526       /256 ; 5B
	db cmdY8950        /256 ; 5C
	db skip3           /256 ; 5D
	db cmdYMF262p0     /256 ; 5E
	db cmdYMF262p1     /256 ; 5F
	db cmdunsupported  /256 ; 60
	db waitvar         /256 ; 61
	db wait735         /256 ; 62
	db wait882         /256 ; 63
	db cmdunsupported  /256 ; 64
	db cmdunsupported  /256 ; 65
	db endofsounddata  /256 ; 66
	db cmddatablock    /256 ; 67
	db skip12          /256 ; 68
	db cmdunsupported  /256 ; 69
	db cmdunsupported  /256 ; 6A
	db cmdunsupported  /256 ; 6B
	db cmdunsupported  /256 ; 6C
	db cmdunsupported  /256 ; 6D
	db cmdunsupported  /256 ; 6E
	db cmdunsupported  /256 ; 6F
	db wait1           /256 ; 70
	db wait2           /256 ; 71
	db wait3           /256 ; 72
	db wait4           /256 ; 73
	db wait5           /256 ; 74
	db wait6           /256 ; 75
	db wait7           /256 ; 76
	db wait8           /256 ; 77
	db wait9           /256 ; 78
	db wait10          /256 ; 79
	db wait11          /256 ; 7A
	db wait12          /256 ; 7B
	db wait13          /256 ; 7C
	db wait14          /256 ; 7D
	db wait15          /256 ; 7E
	db wait16          /256 ; 7F
	db skip1           /256 ; 80
	db wait1           /256 ; 81
	db wait2           /256 ; 82
	db wait3           /256 ; 83
	db wait4           /256 ; 84
	db wait5           /256 ; 85
	db wait6           /256 ; 86
	db wait7           /256 ; 87
	db wait8           /256 ; 88
	db wait9           /256 ; 89
	db wait10          /256 ; 8A
	db wait11          /256 ; 8B
	db wait12          /256 ; 8C
	db wait13          /256 ; 8D
	db wait14          /256 ; 8E
	db wait15          /256 ; 8F
	db skip5           /256 ; 90
	db skip5           /256 ; 91
	db skip6           /256 ; 92
	db skip11          /256 ; 93
	db skip2           /256 ; 94
	db skip5           /256 ; 95
	db cmdunsupported  /256 ; 96
	db cmdunsupported  /256 ; 97
	db cmdunsupported  /256 ; 98
	db cmdunsupported  /256 ; 99
	db cmdunsupported  /256 ; 9A
	db cmdunsupported  /256 ; 9B
	db cmdunsupported  /256 ; 9C
	db cmdunsupported  /256 ; 9D
	db cmdunsupported  /256 ; 9E
	db cmdunsupported  /256 ; 9F
	db cmdAY8910       /256 ; A0
	db skip3           /256 ; A1
	db cmdunsupported  /256 ; A2
	db cmdunsupported  /256 ; A3
	db cmdYM2151dp     /256 ; A4
	db cmdYM2203dp     /256 ; A5
	db skip3           /256 ; A6
	db skip3           /256 ; A7
	db skip3           /256 ; A8
	db skip3           /256 ; A9
	db cmdYM3812dp     /256 ; AA
	db cmdYM3526dp     /256 ; AB
	db cmdY8950dp      /256 ; AC
	db skip3           /256 ; AD
	db cmdYMF262dp0    /256 ; AE
	db cmdYMF262dp0    /256 ; AF
	db skip3           /256 ; B0
	db skip3           /256 ; B1
	db skip3           /256 ; B2
	db skip3           /256 ; B3
	db skip3           /256 ; B4
	db skip3           /256 ; B5
	db skip3           /256 ; B6
	db skip3           /256 ; B7
	db skip3           /256 ; B8
	db skip3           /256 ; B9
	db skip3           /256 ; BA
	db skip3           /256 ; BB
	db skip3           /256 ; BC
	db skip3           /256 ; BD
	db skip3           /256 ; BE
	db skip3           /256 ; BF
	db skip4           /256 ; C0
	db skip4           /256 ; C1
	db skip4           /256 ; C2
	db skip4           /256 ; C3
	db skip4           /256 ; C4
	db skip4           /256 ; C5
	db skip4           /256 ; C6
	db skip4           /256 ; C7
	db skip4           /256 ; C8
	db skip4           /256 ; C9
	db skip4           /256 ; CA
	db skip4           /256 ; CB
	db skip4           /256 ; CC
	db skip4           /256 ; CD
	db skip4           /256 ; CE
	db skip4           /256 ; CF
	db cmdYMF278B      /256 ; D0
	db skip4           /256 ; D1
	db cmdunsupported  /256 ; D2
	db skip4           /256 ; D3
	db skip4           /256 ; D4
	db skip4           /256 ; D5
	db skip4           /256 ; D6
	db skip4           /256 ; D7
	db skip4           /256 ; D8
	db skip4           /256 ; D9
	db skip4           /256 ; DA
	db skip4           /256 ; DB
	db skip4           /256 ; DC
	db skip4           /256 ; DD
	db skip4           /256 ; DE
	db skip4           /256 ; DF
	db cmdunsupported  /256 ; E0
	db skip5           /256 ; E1
	db skip5           /256 ; E2
	db skip5           /256 ; E3
	db skip5           /256 ; E4
	db skip5           /256 ; E5
	db skip5           /256 ; E6
	db skip5           /256 ; E7
	db skip5           /256 ; E8
	db skip5           /256 ; E9
	db skip5           /256 ; EA
	db skip5           /256 ; EB
	db skip5           /256 ; EC
	db skip5           /256 ; ED
	db skip5           /256 ; EE
	db skip5           /256 ; EF
	db skip5           /256 ; F0
	db skip5           /256 ; F1
	db skip5           /256 ; F2
	db skip5           /256 ; F3
	db skip5           /256 ; F4
	db skip5           /256 ; F5
	db skip5           /256 ; F6
	db skip5           /256 ; F7
	db skip5           /256 ; F8
	db skip5           /256 ; F9
	db skip5           /256 ; FA
	db skip5           /256 ; FB
	db skip5           /256 ; FC
	db skip5           /256 ; FD
	db skip5           /256 ; FE
	db skip5           /256 ; FF



cmdYM2608p0 equ cmdYM2203

cmdYM2608p1
	memory_stream_read_2 e,d
	ld a,e
	cp 0x30
	ret c
	jp opnwritefm2


initAY8910
	call ssginit
	ld hl,devicemask
	ld a,(HEADER_CLOCK_AY8910+3)
	and 0x40
	jr nz,.dualchip
	set DEVICE_AY_BIT,(hl)
	ret
.dualchip
	set DEVICE_TURBOSOUND_BIT,(hl)
	ret

initYM2203
tfmstatus=$+1
	ld a,1
	dec a
	ret m
	call opninit
	set_timer opnwaittimer60hz,735
	call opninittimer60hz
	ld hl,devicemask
	set DEVICE_TFM_BIT,(hl)
	xor a
	ret

initYMF278B
moonsoundstatus=$+1
	ld a,2
	dec a
	ret m
	call vgmopl4init
	ld a,(HEADER_CLOCK_YM3812+3)
	and 0x40
	jr nz,notOPL2
useYM3812=$+1
	or 0
	ld de,0x0005
	call nz,opl4writefm2
notOPL2 
	call opl4inittimer60hz
	ld hl,devicemask
	set DEVICE_MOONSOUND_BIT,(hl)
	xor a
	ret

end



;        LABELSLIST "vgm_plr.l"    
;	savebin "gplay.apg",begin,end-begin