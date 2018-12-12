;
; Horizontal "gas gauge" demo
;
; Notes:
;
; 1) Draws a gauge using the BK color of red and PF color of green
; 2) Using only PF0 and PF1 for a total of 12-pixels wide
; 3) Moving up and down will increase and decrease the gauge
;

;
; By Joe Grand, jgrand@xxxxxxxxxxxxxx
; March 23, 2001 (1:30am)
;
; Tested with StellaX v1.1.3a
;

        processor 6502
        include vcs.h


Table1  =       $80
Table2  =       $81


        ORG     $F000

Start:  SEI             ; Initialize the machine, set interrupt disable
        CLD             ; clear decimal mode
        LDX     #$FF    ; start X at $FF (255d)
        TXS             ; transfer it to the stack
        INX             ; set X to $00
        TXA             ; transfer it to the accumulator, A
B1:
        STA     0,X     ; store $00 at 0+X
        INX             ; increment X
        BNE     B1      ; if X is not zero yet, go back to @1
                        ; the above loop zeros out $00 to $FF
                        ; at this point X is $00

        ;Set variables
        LDA     #$F0
        STA     Table1
        LDA     #$FF
        STA     Table2

Top:                    ; Start a new screen
        ;LDA     #$05
        LDA     #$35
        STA     TIM64T  ; set timer for $05*$40 = $140 (320d) clocks

          ; do overscan stuff here

        LDA     #$00    ; put $00 in A
        STA     PF0     ; clear out first playfield section
        STA     PF1     ; clear out second playfield section
        STA     PF2     ; clear out third playfield section
        STA     GRP0    ; clear out player graphic 0
        STA     GRP1    ; clear out player graphic 1
        STA     ENAM0   ; clear out missile 0
        STA     ENAM1   ; clear out missile 1
        STA     ENABL   ; clear out ball
        STA     COLUP1  ; set player 1 to black
        STA     COLUP0  ; set player 0 to black
        STA     COLUBK  ; set background to black

          ;wait for overscan to finish, then start blanking

B2:
        LDA     INTIM   ; find current value of timer
        BNE     B2      ; if timer not zero, wait
                        ; when we get here, A will be $00
        LDY     #$02    ; this is 10000010b
        STY     WSYNC   ; wait for end of current line
        STY     VBLANK  ; start vertical, disable latches, dump orts
                        ; this is from the 10000010b
        STY     VSYNC   ; start vertical sync
        STY     WSYNC   ; send three lines while doing vertical sync
        STY     WSYNC
        STY     WSYNC
        STA     VSYNC   ; end vertical sync

         ;LDA     #$05    ; put $05 in A
        LDA     #$43
        STA     TIM64T  ; start VBLANK timer

        ; Setup the playfield graphics
        LDA     #%10111000 ; green
        STA     COLUPF

        LDA     SWCHA      ; Load the joystick switches
        ROL
        ROL
        BMI     NotDown    ; Joystick pushed down? Decrease gas gauge
        JSR     DecGauge
        JMP     NoStick
NotDown:
        ROL
        BMI     NoStick    ; Joystick pushed up? Increase gas gauge
        JSR     IncGauge
NoStick:
        JSR     Blank   ; do blanking stuff
        STA     WSYNC   ; one more line for good measure

; Draw the screen
; JOE'S GOAL: draw multi-colored gas gauge in playfield graphics

        LDX     #100    ; position drawing vertically
PreDraw:
        STA     WSYNC   ; wait for one line to be done
        DEX             ; decrease X by one
        BNE     PreDraw ; if not done with blank space, do another line

        LDX     #$06    ; number of lines alike
NxtLine:
        STA     WSYNC   ; wait for line to finish

        LDA     #%00110100      ; [0] +4 red
        STA     COLUBK          ; [4] +3 set background

        ; First half of screen
        LDA     Table1  ; [7] +3 get the Xth line for playfield 0
        STA     PF0     ; [10] +3 store it in playfield 0 register
        LDA     Table2  ; [13] +3 get the Xth line for playfield 1
        STA     PF1     ; [16] +3 store it in playfield 1 register


        NOP             ; [19] +2
        NOP             ; [21] +2
        NOP             ; [23] +2
        NOP             ; [25] +2
        NOP             ; [27] +2
        NOP             ; [29] +2
        NOP             ; [31] +2
        NOP             ; [33] +2

        LDA     #0      ; [35] +4
        STA     COLUBK  ; [39] +3 end of gauge -> background color back to black

        ; Second half of screen
        STA     PF0     ; [42] +3
        STA     PF1     ; [45] +3

        DEX             ; [48] +5
        BNE     NxtLine ; [53] +3 (take branch)

        LDA     #$00    ; get ready to clear playfield
        STA     PF0
        STA     PF1
        STA     COLUBK

        LDX     #66    ; get ready to finish screen (172 lines total)
Finish:
        STA     WSYNC   ; do one line
        DEX             ; decrement counter
        BNE     Finish  ; if not on last line, do another one
        JMP     Top     ; done with this frame, go back to Top

Blank:
        NOP
B3:
        LDA     INTIM   ; find out current status of timer
        BNE     B3      ; if timer is zero, then done, otherwise check timer
        STA     WSYNC   ; A is $00, kick out another line
        STA     VBLANK  ; blank off, disable latches, remove dump
        RTS


DecGauge:
        LDA     Table2
        CMP     #$0
        BEQ     DecTable1
        ASL
        STA     Table2
        JMP     DecDone
DecTable1:
        LDA     Table1
        LSR
        AND     #$F0
        STA     Table1
DecDone:
        RTS


IncGauge:
        LDA     Table1
        CMP     #$F0
        BEQ     IncTable2
        ASL
        ORA     #$10
        STA     Table1
        JMP     IncDone
IncTable2:
        LDA     Table2
        LSR
        ORA     #$80
        STA     Table2
IncDone:
        RTS


        ;org $FE00 ; *********************** GRAPHICS DATA

;Table1: ;.byte   $00, $00, $00, $00, $00, $00, $F0, $F0  ;PF0 left half (20 bits total)

        ;.byte $F0, $F0 ; Maximum length of gauge = 12 bits
        ;.byte $70, $70
        ;.byte $30, $30
        ;.byte $10, $10
        ;.byte $00, $00

        ;.word $6040
        ;.word $4040
        ;.word $00E0
        ;.word $0000

;Table2: ;.byte   $00, $00, $00, $00, $00, $00, $F0, $F0  ;PF1 left half

        ;.byte $FF, $FF
        ;.byte $FE, $FE
        ;.byte $FC, $FC
        ;.byte $F8, $F8
        ;.byte $F0, $F0
        ;.byte $E0, $E0
        ;.byte $C0, $C0
        ;.byte $80, $80
        ;.byte $00, $00

        ;.word $1177
        ;.word $4173
        ;.word $0077
        ;.word $0000

;Table3: .byte   $00, $00, $00, $00, $00, $00, $F0, $F0  ;PF2 left half

        ;.word $2AEA
        ;.word $88EE
        ;.word $00E8
        ;.word $0000

;Table4: .byte   $00, $00, $00, $00, $00, $00, $F0, $F0  ;PF0 right half (20 bits total)

        ;.word $20E0
        ;.word $A0E0
        ;.word $00E0
        ;.word $0000

;Table5: .byte   $00, $00, $00, $00, $00, $00, $FC, $FC  ;PF1 right half

        ;.word $1577
        ;.word $1517
        ;.word $0017
        ;.word $0000

;Table6: .byte   $00, $00, $00, $00, $00, $00, $00, $00  ;PF2 right half

        ;.word $AAEE
        ;.word $A8AE
        ;.word $00E8
        ;.word $0000


         ORG     $FFFC   ; vectors for 4k cart
        .word      Start   ; reset
        .word      Start   ; IRQ
