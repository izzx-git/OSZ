MOON_BASE_HI = 0x00 ;старший байт
MOON_BASE = 0x24 ;0xc4
MOON_REG1 = MOON_BASE      
MOON_DAT1 = MOON_BASE+1  ;c5
MOON_REG2 = MOON_BASE+2  ;c6
MOON_DAT2 = MOON_BASE+3  ;c7
MOON_STAT = MOON_BASE
MOON_WREG = 0xc2
MOON_WDAT = MOON_WREG+1

;TODO: is this good enough for ATM2?
	macro opl4_wait
	ld a,MOON_BASE_HI
	in a,(MOON_STAT)
	rrca
	jr c,$-3
	endm

;makes ZXM-Moonsound firmware 1.01 switch PCM ports from default 7E and 7F to C2 and C3
	macro switch_to_pcm_ports_c2_c3
	ld a,MOON_BASE_HI
	in a,(MOON_REG2)
	endm



NR_OF_MIDI_CHANNELS = 16
NR_OF_WAVE_CHANNELS = 24



MOONSOUNDROMSIZE = 0x200000
MOONWAVEHEADERSIZE = 12
MOONRAMWAVETABLESIZE = 128
OPL4MAXWAVECHANNELS = NR_OF_WAVE_CHANNELS

OPL4_TIMER1_COUNT   = 0x02
OPL4_TIMER2_COUNT   = 0x03
OPL4_TIMER_CONTROL  = 0x04




OPL4_REG_TEST0               = 0x00
OPL4_REG_TEST1               = 0x01

OPL4_REG_MEMORY_CONFIGURATION = 0x02
OPL4_MODE_BIT                 = 0x01
OPL4_MTYPE_BIT                = 0x02
OPL4_TONE_HEADER_MASK         = 0x1C
OPL4_DEVICE_ID_MASK           = 0xE0

OPL4_REG_MEMORY_ADDRESS_HIGH  = 0x03
OPL4_REG_MEMORY_ADDRESS_MID   = 0x04
OPL4_REG_MEMORY_ADDRESS_LOW   = 0x05
OPL4_REG_MEMORY_DATA          = 0x06

/*
 * Offsets to the register banks for voices. To get the
 * register number just add the voice number to the bank offset.
 *
 * Wave Table Number low bits (0x08 to 0x1F)
 */
OPL4_REG_TONE_NUMBER  = 0x08

/* Wave Table Number high bit, F-Number low bits (0x20 to 0x37) */
OPL4_REG_F_NUMBER      = 0x20
OPL4_TONE_NUMBER_BIT8  = 0x01
OPL4_F_NUMBER_LOW_MASK = 0xFE

/* F-Number high bits, Octave, Pseudo-Reverb (0x38 to 0x4F) */
OPL4_REG_OCTAVE         = 0x38
OPL4_F_NUMBER_HIGH_MASK = 0x07
OPL4_BLOCK_MASK         = 0xF0
OPL4_PSEUDO_REVERB_BIT  = 0x08

/* Total Level, Level Direct (0x50 to 0x67) */
OPL4_REG_LEVEL        = 0x50
OPL4_TOTAL_LEVEL_MASK = 0xFE
OPL4_LEVEL_DIRECT_BIT = 0x01

/* Key On, Damp, LFO RST, CH, Panpot (0x68 to 0x7F) */
OPL4_REG_MISC           = 0x68
OPL4_KEY_ON_BIT         = 0x80
OPL4_DAMP_BIT           = 0x40
OPL4_LFO_RESET_BIT      = 0x20
OPL4_OUTPUT_CHANNEL_BIT = 0x10
OPL4_PAN_POT_MASK       = 0x0F

/* LFO, VIB (0x80 to 0x97) */
OPL4_REG_LFO_VIBRATO    = 0x80
OPL4_LFO_FREQUENCY_MASK = 0x38
OPL4_VIBRATO_DEPTH_MASK = 0x07
OPL4_CHORUS_SEND_MASK   = 0xC0

/* Attack / Decay 1 rate (0x98 to 0xAF) */
OPL4_REG_ATTACK_DECAY1  = 0x98
OPL4_ATTACK_RATE_MASK   = 0xF0
OPL4_DECAY1_RATE_MASK   = 0x0F

/* Decay level / 2 rate (0xB0 to 0xC7) */
OPL4_REG_LEVEL_DECAY2  = 0xB0
OPL4_DECAY_LEVEL_MASK  = 0xF0
OPL4_DECAY2_RATE_MASK  = 0x0F

/* Release rate / Rate correction (0xC8 to 0xDF) */
OPL4_REG_RELEASE_CORRECTION  = 0xC8
OPL4_RELEASE_RATE_MASK       = 0x0F
OPL4_RATE_INTERPOLATION_MASK = 0xF0

/* AM (0xE0 to 0xF7) */
OPL4_REG_TREMOLO        = 0xE0
OPL4_TREMOLO_DEPTH_MASK = 0x07
OPL4_REVERB_SEND_MASK   = 0xE0

/* Mixer */
OPL4_REG_MIX_CONTROL_FM  = 0xF8
OPL4_REG_MIX_CONTROL_PCM = 0xF9
OPL4_MIX_LEFT_MASK       = 0x07
OPL4_MIX_RIGHT_MASK      = 0x38

OPL4_REG_ATC             = 0xFA
OPL4_ATC_BIT             = 0x01

/* Bits in the OPL4 Status register */
OPL4_STATUS_BUSY = 0x01
OPL4_STATUS_LOAD = 0x02

