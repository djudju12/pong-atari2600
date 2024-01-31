;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Program Name: Pong 2600                                                     ║
;║ Author: djudju12                                                            ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    processor 6502

    include "vcs.h"
    include "macro.h"


;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Variables Segment                                                           ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    seg.u Variables
    org $80

Paddle0YPos      byte
Paddle1YPos      byte

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Constants Segment                                                           ║
;╚═════════════════════════════════════════════════════════════════════════════╝
COLOR_BG  = $00
COLOR_PF  = $04
HEIGHT_PF = $07

PADDLE0_X_POS = $00
PADDLE1_X_POS = #125

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Macros Segment                                                              ║
;╚═════════════════════════════════════════════════════════════════════════════╝

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Start of the program                                                        ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    seg code
    org $F000

Reset:
    CLEAN_START

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Initialization of variables and TIA registers                               ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    LDA #70
    STA Paddle0YPos
    STA Paddle1YPos

StartFrame:
;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Turn o VSYNC and VBLANK                                                     ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    LDA #02
    STA VBLANK
    STA VSYNC

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Generate three lines of the VSYNC                                           ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    REPEAT 3
        sta WSYNC
    REPEND
    LDA #0
    STA VSYNC

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Let the TIA output the 37 Lines of the VBLANK                               ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    REPEAT 34
        sta WSYNC
    REPEND

;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Calculation in VBLANK                                                       │
;└─────────────────────────────────────────────────────────────────────────────┘
    LDA #PADDLE0_X_POS
    LDY #0
    JSR SetObjectXPos

    LDA #PADDLE1_X_POS
    LDY #1
    JSR SetObjectXPos

    STA WSYNC
    STA HMOVE

    LDA #0
    STA VBLANK

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Start of the visible lines                                                  ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    LDA #COLOR_BG
    STA COLUBK

    LDX #96
.GameLineLoop:
;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Check if its time to draw paddle 0                                          │
;└─────────────────────────────────────────────────────────────────────────────┘
    TXA
    SEC
    SBC Paddle0YPos
    CMP #PADDLE_HEIGHT
    BCC .DrawPaddle0
    LDA #0
.DrawPaddle0:
    TAY
    LDA Paddle0Sprite,Y
    STA WSYNC
    STA GRP0
    LDA Paddle0Color,Y
    STA COLUP0

;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Check if its time ddo draw paddle 1                                         │
;└─────────────────────────────────────────────────────────────────────────────┘
    TXA
    SEC
    SBC Paddle1YPos
    CMP #PADDLE_HEIGHT
    BCC .DrawPaddle1
    LDA #0
.DrawPaddle1:
    TAY
    LDA Paddle0Sprite,Y
    STA WSYNC
    STA GRP1
    LDA Paddle0Color,Y
    STA COLUP1

    DEX
    BNE .GameLineLoop
    LDA #0
;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Output the 30 more VBLANK overscan lines                                    ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    LDA #2
    STA VBLANK
    REPEAT 30
        STA WSYNC
    REPEND
    LDA #0
    STA VBLANK

;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Input-check section                                                         │
;└─────────────────────────────────────────────────────────────────────────────┘
CheckP0Up:
    LDA #16
    BIT SWCHA
    BNE CheckP0Down

    LDA Paddle0YPos
    CMP #75
    BPL CheckP0Down
    INC Paddle0YPos
CheckP0Down:
    LDA #32
    BIT SWCHA
    BNE CheckP1Up

    LDA Paddle0YPos
    CMP #2
    BMI CheckP1Up
    DEC Paddle0YPos
CheckP1Up:
    LDA #1
    BIT SWCHA
    BNE CheckP1Down

    LDA Paddle1YPos
    CMP #75
    BPL CheckP1Down
    INC Paddle1YPos
CheckP1Down:
    LDA #2
    BIT SWCHA
    BNE NoMoreInput

    LDA Paddle1YPos
    CMP #2
    BMI NoMoreInput
    DEC Paddle1YPos
NoMoreInput:
;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Ajust the Y position                                                        │
;└─────────────────────────────────────────────────────────────────────────────┘
;     DEC Paddle0YPos
;     LDA Paddle0YPos
;     CMP #0
;     BNE SkipAjustY
;     LDA #96
;     STA Paddle0YPos
; SkipAjustY:
;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Ajust the X position                                                        │
;└─────────────────────────────────────────────────────────────────────────────┘
;     INC PADDLE1_X_POS
;     LDA PADDLE1_X_POS
;     CMP #162
;     BCC SkipAjustX
;     LDA #0
;     STA PADDLE1_X_POS
; SkipAjustX:
;╔═════════════════════════════════════════════════════════════════════════════╗
;║ End of the Program                                                          ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    JMP StartFrame

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Subroutines Segment                                                         ║
;╚═════════════════════════════════════════════════════════════════════════════╝
;┌─────────────────────────────────────────────────────────────────────────────┐
;│ Subroutine to handle o object horizontal position with fine offset          │
;├─────────────────────────────────────────────────────────────────────────────┤
;│ A is the target x-coord position in pixels of our object                    │
;│ Y is the object type (0:P0, 1:P1, 2:M0, 3:M1, 4:B                           │
;└─────────────────────────────────────────────────────────────────────────────┘
SetObjectXPos subroutine
    STA WSYNC
    SEC
.Div15Loop
    SBC #15
    BCS .Div15Loop
    EOR #7
    ASL
    ASL
    ASL
    ASL
    STA HMP0,Y
    STA RESP0,Y
    RTS

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Lookups Segment                                                             ║
;╚═════════════════════════════════════════════════════════════════════════════╝
Paddle0Sprite:
    .byte #%00000000
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111
    .byte #%00000111

PADDLE_HEIGHT = . - Paddle0Sprite

Paddle0Color:
    .byte #$00
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A
    .byte #$0A

;╔═════════════════════════════════════════════════════════════════════════════╗
;║ Setting Reset memory                                                        ║
;╚═════════════════════════════════════════════════════════════════════════════╝
    org $FFFC
    .word Reset
    .word Reset