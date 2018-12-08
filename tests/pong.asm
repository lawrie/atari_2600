;;Ball test program.
;;By Lawrie Griffiths

    processor 6502
    include "vcs.h"
    include "macro.h"
	
    seg.u vars
    org $80
	
Ball_X  DS 1
Ball_Y  DS 1
Ball_E  DS 1
Bat0_Y  DS 1
Bat0_E  DS 1
Bat1_Y  DS 1

    seg Code
    org $F000		
	
Start:
    LDX #0            ; Clear RAM and TIA and set Stack Pointer
    TXA    

Clear:
    DEX
    TXS
    PHA
    BNE Clear

    LDA #$00          ; Set colours
    STA COLUPF
    LDA #$5A
    STA COLUBK
    LDA #$0E
    STA COLUP0
    STA COLUP1

    LDA #$21          ; Set ball size to 4
    STA CTRLPF

    LDA #100
    STA Ball_Y
    LDA #104
    STA Ball_E

    LDA #$E0          ; Move Ball 2 right, gets done 37 times
    STA HMBL          ; So ball X position becomes 74
    LDA #$F0          ; Move missile 0 1 right so it gets set to 37
    STA HMM0
    LDA #$C0
    STA HMM1
    LDA #60
    STA Bat0_Y
    CLC
    ADC #40
    STA Bat0_E
    LDA #2            ; Start VBLANK
    STA VBLANK

Frame:
    LDA #2

Vsync0:
    STA VSYNC         ; 3 VSYNC lines
    STA WSYNC
    STA WSYNC
    STA WSYNC
    LDA #0
    STA VSYNC
    LDY #37           ; 37 VBLANK lines

Vblank0:
    STA WSYNC
    CPY #30
    BPL Cont_M0
    LDA #0
    STA HMM0

Cont_M0:
    STA HMOVE         ; Move ball and missiles
    DEY
    BNE Vblank0
    LDA #0            ; Clear VBLANK
    STA VBLANK
    STA HMCLR         ; Clear Ball and missile movement
    LDY #16           ; Count picture lines from 16 t0 208 (192 lines)

Picture:
    LDA #0
    CPY Ball_Y 
    BMI NoBall
    CPY Ball_E
    BPL NoBall
    LDA #2

NoBall:
    STA ENABL
    LDA #0
    CPY Bat0_Y
    BMI NoBat
    CPY Bat0_E
    BPL NoBat
    LDA #2

NoBat:
    STA ENAM0 
    STA ENAM1
    INY
    STA WSYNC
    CPY #208
    BNE Picture

    LDA #2            ; Set VBLANK
    STA VBLANK
    LDA SWCHA         ;get both sticks
    LDY Bat0_Y
    ASL               ;slide off up bit
    ASL
    ASL
    BCS Not_Up        ;skip if set
    INY               ;...or, bump Y
    INY

Not_Up:
    ASL               ;slide off down bit
    BCS Not_Down      ;skip if set
    DEY               ;...or, bump y
    DEY

Not_Down:
    TYA
    STA Bat0_Y
    CLC
    ADC #40
    STA Bat0_E

    LDA Ball_Y
    CLC
    ADC #2
    STA Ball_Y
    CLC
    ADC #4
    STA Ball_E
	
    LDY #30           ; 30 Overscan lines
Overscan:
    DEY
    STA WSYNC
    BNE Overscan
    JMP Frame
		
    echo "----",($FFFC - *) ," bytes left"
	
    org $FFFC
    .word Start
    .word Start
