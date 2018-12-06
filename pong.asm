;;Pong 1/4 K  Assembly outputs 256 byte ROM image..  
;;By Rick Skrbina 

	processor 6502
	include "vcs.h"
	include "macro.h"
	
        MAC READ_PADDLE_1
        lda INPT0    ; 3   - always 9
        bpl .save    ; 2 3
        .byte $2c    ; 4 0
.save   sty P0_Y     ; 0 3
        ENDM

        MAC READ_PADDLE_2
        lda INPT1    ; 3   - always 9
        bpl .save    ; 2 3
        .byte $2c    ; 4 0
.save   sty P1_Y     ; 0 3
        ENDM
	
	seg.u vars
	org $80

P0_Y			ds 1
P1_Y			ds 1
P0_End			ds 1
P1_End			ds 1
Ball_Y			ds 1
Game			ds 1
;;As long as Game is something other than 0, game logic will be skiped
Ball_Vertical		ds 1	;Ball_Status removed and split in two to save ROM
Ball_Horizontal		ds 1

	org $E8			
Ball_X			ds 1	

	
	seg Code
	org $F000		
	
Start	

	cld
	lda #0
	tax
	tay
Clear_Stack
	dex
	txs
	pha
	bne Clear_Stack
	

	lda #70		
	
	sta COLUBK
	
	sta AUDF0
	sta AUDC0

Store_Loop
	sta P0_Y,y
	iny
	bpl Store_Loop

	
Start_Frame

	lda #$87
	sta VBLANK
	asl
loopVsync
	sta WSYNC
	sta VSYNC
	lsr
	bne loopVsync

	

	lda #35	
	sta TIM64T

Positions
	lda Ball_X
	ldy #4
Pos_Loop
	sta WSYNC
	sta HMCLR
Div_Loop
	sbc #15
	bcs Div_Loop
	eor #7
	asl
	asl
	asl
	asl
	sta HMP0,Y
	sta RESP0,Y
	sta WSYNC
	sta HMOVE
	lda Positions,X
	inx
	dey
	bne Pos_Loop




Vertical_Blank
	lda INTIM
	bpl Vertical_Blank
	

	stx VBLANK		

	
	ldy #192		
	lda #%00000010
Picture
	
	cpy P0_End
	bne Skip_M0


	
	sta ENAM0	
	
	
Skip_M0

	cpy P0_Y
	bne Check_Ball

	stx ENAM0	
	
Check_Ball

	cpy Ball_Y
	bne No_Ball
	
	sta ENABL	
	.byte $2C
	
No_Ball
	stx ENABL	

Check_M1
	
	cpy P1_End		
	bne Skip_M1
	
	sta ENAM1
Skip_M1
	cpy P1_Y
	bne Done_M1

	
	stx ENAM1	
	
Done_M1
	


	dey 
	sta WSYNC
	bne Picture
	



	sty ENAM0
	sty ENAM1
	sta VBLANK	;no need to load new value, Accumulator already contains 2 !
	
	
	
	lda #$2B
	sta TIM64T
	
	bit INPT4
	bmi Button_Not_Pushed

	
	sty Game
	
Button_Not_Pushed




	lda Game
	bne Skip_Logic

	
	lda Ball_Vertical
	beq Move_Ball_Down

	inc Ball_Y
	.byte $2C
	
Move_Ball_Down
	dec Ball_Y
	
Done_Moving_Ball


	lda Ball_Y
	cmp #180		
	beq Store_Status
	
Check_Other_Wall

	lda Ball_Y
	bne No_CX_BL_PF
	

	iny

Store_Status
	sty Ball_Vertical
No_CX_BL_PF
	


	lda Ball_Horizontal
	beq Move_Ball_left
	
	dec Ball_X
	.byte $2C
	
Move_Ball_left
	inc Ball_X
	
Done_Moving_Ball_X

	lda #1
	
	sty AUDV0
	
	bit CXM0FB
	bvc Check_Other_Player

	lsr
	beq Store_LR_Status	
	
Check_Other_Player

	bit CXM1FB
	bvc Dont_Store_LR_Status
	
Store_LR_Status

	sta Ball_Horizontal
	sta CXCLR
	lsr AUDV0

Dont_Store_LR_Status




	lda Ball_X
	beq Start_New_Round


	
Check_Other_X
	cmp #160
	bne Done_Update_Score

	
	
	
	
Start_New_Round

	brk
	

Done_Update_Score

Skip_Logic

	lda SWCHA      ;get both sticks
	ldx #2         ;# players to check
.check_stick_loop:
	ldy P0_Y-1,x   ;get current Y
	lsr            ;slide off up bit
	bcs .not_up    ;skip if set
	iny            ;...or, bump Y
	iny
.not_up:
   	lsr            ;slide off down bit
	bcs .not_down  ;skip if set
	dey            ;...or, bump y
	dey
.not_down:
   	lsr            ;slide off right/left
	lsr            ; (invalid movement)
	sty P0_Y-1,x   ;Store updated Y
	pha            ;push sticks to stack
	tya            ;do addition now...
	adc #24        ;
	sta P0_End-1,x   ;...to get the ending
	pla            ;get back stick value
	dex            ;bump to next player
	bne .check_stick_loop

Overscan
	lda INTIM
	bpl Overscan



	jmp Start_Frame		
	

	echo "----",($FFFC - *) ," bytes left"
	
	org $FFFC
	.word Start
	.word Start