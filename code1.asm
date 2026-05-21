start_of_program
    lda #22  ;22 columns
    sta _VICCR2
    lda #9
    sta game_select_level
    nop

;Need extras for 8k
!if USE_8k_MEMORY_LAYOUT = 1 {
    jsr extras_8k
extras_8k_done
} else {
    jsr title_screen_select_option
}
;

;Location of screen, colour map and character set:
    lda #254  ;254 = 1111 1110
    sta _VICCR5
;7-4 = 1111 + _VICCR2 bit 7 (is 0) means screen is located at $1c00 (7168), and colour map at $9400 (37888)
;3-0 = 1110 means character map is located at $1800 (6144)
;See MTV page 130

program_loop1
    jsr common_sub13
program_loop2
    jsr a_sub8
    lda $60
    cmp #30
    bne .skip_nextCA
    lda #150
    bne .skip_nextCB
.skip_nextCA
    lda #22
.skip_nextCB
    sta _VICCR2
    jsr a_sub9
    jsr a_subA
    jmp a_sub4

!byte $00,$00

draw_screen         
    ldx #0
    lda #0  ;black colour, empty screen
draw_loop1
    sta _SCREEN_ADDR,x
    sta _SCREEN_ADDR+256,x
    sta _COLOUR_SCREEN_ADDR,x
    sta _COLOUR_SCREEN_ADDR+256,x
    inx
    bne draw_loop1

    lda #28  ;block character, on side borders
draw_loop2
    sta _SCREEN_ADDR,x
    sta _SCREEN_ADDR+484,x
    inx
    cpx #22
    bne draw_loop2

    ldx #0
draw_loop3
    lda #28  ;block character, on top and bottom borders
    sta _SCREEN_ADDR,x
    sta _SCREEN_ADDR+21,x
    sta _SCREEN_ADDR+286,x
    sta _SCREEN_ADDR+307,x
    clc
    txa
    adc #22
    tax
    cpx #220
    bne draw_loop3

    lda #0
draw_item
    sta _SCREEN_ADDR+10
    sta _SCREEN_ADDR+11
    sta _SCREEN_ADDR+494
    sta _SCREEN_ADDR+495
    ldx next_screen_offset
.top_of_loop71
    jsr a_subB
    lda DATA_1,x
    beq .skip_nextK1
.top_of_loop72
    lda #28
    sta ($61),y
    lda $61
    clc
.self_mod_1
    adc #0  ;#0 is a self-mod value
    bcc .skip_nextG2
    inc $62
.skip_nextG2
    sta $61
    iny
    cpy #5
    bne .top_of_loop72
.skip_nextK1
    lda .self_mod_1+1
    beq .skip_nextH1
    lda #0
    beq .skip_nextH2
.skip_nextH1
    lda #21
.skip_nextH2
    sta .self_mod_1+1
    inx
    txa
    and #7
    bne .top_of_loop71
    ldy #0
    lda $72
    asl
    asl
    tax
    sty $61
    lda $60
    adc DATA_4+9,x
    sta $62
    jsr common_sub5
    jsr common_sub5
    jsr common_sub5
    jsr a_subC
    jsr a_subD
    jsr a_sub3
    jsr a_subE
    jsr a_subF
    jsr a_sub6
    rts

!byte $00,$00,$00,$00,$00,$00,$00,$00,$00

common_sub5         
    clc
    lda DATA_4+10,x
    adc $61
    sta $61
    bcc .skip_nextK5
    inc $62
.skip_nextK5         
    lda #31
    sta ($61),y
    inx
    rts

;DATA_1 = $1100 to $11b1 (4352 to 4529)
;DATA_1A,B = $11b1 to $1200 (4529 to 4608)
;22 x 8 = 176 + 1 = 177
;10 x 8 = 80 -1 = 79
;256 bytes in this data block
DATA_1
    !byte $1e, $48, $e6, $d6, $56, $63, $00, $00
    !byte $c5, $35, $a9, $4c, $f0, $34, $8a, $cc
    !byte $88, $77, $00, $00, $49, $73, $00, $00
    !byte $22, $57, $f0, $b3, $b8, $0e, $05, $dd
    !byte $65, $00, $93, $00, $2d, $00, $5b, $00
    !byte $df, $33, $0f, $a5, $0b, $48, $33, $0d
    !byte $58, $7a, $9b, $93, $00, $00, $00, $00
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71
    !byte $00, $4a, $00, $26, $00, $c4, $00, $a4
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71
    !byte $00, $00, $00, $00, $00, $00, $00, $00
    !byte $df, $33, $0f, $a5, $0c, $48, $33, $0d
    !byte $60, $20, $00, $02, $18, $02, $40, $10
    !byte $20, $30, $00, $02, $18, $02, $40, $10
    !byte $60, $58, $00, $02, $18, $02, $40, $10
    !byte $38, $78, $00, $02, $18, $02, $40, $10
    !byte $90, $28, $00, $02, $18, $02, $40, $10
    !byte $38, $48, $00, $02, $18, $02, $40, $10
    !byte $10, $52, $00, $02, $18, $02, $40, $10
    !byte $98, $98, $00, $02, $18, $02, $40, $10
    !byte $00, $00, $00, $02, $1d, $02, $40, $10
    !byte $60, $20, $00, $04, $1a, $02, $10, $10
    !byte $00
DATA_1A
    !byte $00, $00, $02, $01, $01, $70, $08, $0f
    !byte $00, $03, $02, $01, $01, $78, $08, $60
    !byte $2d, $00, $07, $01, $01, $80, $08, $00
    !byte $00, $00, $02, $01, $01, $88, $08, $00
    !byte $00, $00, $02, $01, $01, $90, $08, $00
    !byte $00, $00, $02, $01, $01, $98, $08, $00
    !byte $00, $00, $02, $01, $01, $a0, $08, $00
    !byte $00, $00, $02, $01, $01, $a8, $08, $00
    !byte $00, $00, $02, $01, $01, $b0, $08, $00
DATA_1B
    !byte $00, $00, $02, $01, $01, $b8, $08

a_subB
    txa
    clc
    and #7
    sta $70
    lda DATA_1,x
    and #15
    adc $70
    tay
    lda DATA_1,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc $70
    jsr common_sub14
    rts

common_sub13
    ldy #0
    lda next_screen_offset
    clc
    adc #8
    tax
.top_of_loop_z1         
    txa
    and #7
    sta $65
    lda DATA_1,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc $65
    asl
    asl
    asl
    sta DATA_1+96,y
    lda DATA_1,x
    and #15
    clc
    adc $65
    asl
    asl
    asl
    sta DATA_1+97,y
    lda #0
    sta DATA_1B
    sta DATA_1+98,y
    sta DATA_1A,y
    lda next_screen_offset
    lsr
    lsr
    lsr
    lsr
    sta .robot_colour+1
.robot_colour
    lda DATA_ROBOT_COLOURS
    sta DATA_1+99,y
    inx
    tya
    adc #8
    tay
    cmp #64
    bne .top_of_loop_z1
    ldx $72
    lda DATA_4+25,x
    sta DATA_1+168
    lda DATA_4+29,x
    sta DATA_1+169
    jsr screen_transition
    rts

!byte $00, $00, $00, $00

a_subC
    ldx #96
.top_of_loop21
    lda DATA_1+1,x
    beq .skip_nextK7
    cpx #168
    bcs .skip_nextF1
    and #7
    bne .skip_nextF1
    lda DATA_1+1,x
    lsr
    lsr
    lsr
    tay
    lda DATA_1,x
    and #7
    bne .skip_nextF1
    lda DATA_1,x
    lsr
    lsr
    lsr
    jsr common_sub14
    lda DATA_1+4,x
    sta ($61),y
    ldy #22
    clc
    adc #1
    sta ($61),y
    lda $61
    sta $63
    lda $62
    clc
    adc #120  ;screen to colour map offset (high byte)
    sta $64
    lda DATA_1+3,x
    ldy #0
    sta ($63),y
    ldy #22
    sta ($63),y
.skip_nextK7
    txa
    clc
    adc #8
    tax
    bne .top_of_loop21
    rts

.skip_nextF1
    jsr a_subG
    jmp .skip_nextK7

a_subD
    dec $a3
    beq .skip_nextF2
    rts

.skip_nextF2
    lda #3
    sta $a3
    lda $cb  ;matrix coordinate of current key pressed, 64 if none
    cmp #64
    beq .skip_nextF3
    cmp #28
    bne .skip_nextCC
    lda #27
.skip_nextCC
    cmp #51
    bne .skip_nextCD
    lda #29
.skip_nextCD
    cmp #20
    bne .skip_nextCE
    lda #30
.skip_nextCE
    cmp #43
    bne .skip_nextCF
    lda #23
.skip_nextCF
    ldy $028d  ;Keyboard shift / control flag
    beq .skip_nextCG
    and #15
.skip_nextCG
    jmp .jump_to1

.skip_nextF3
    lda #0
    sta _DATADIR_B
    lda _KEYB_ROWS
    asl
    rol $69
    lda #255
    sta _DATADIR_B
    lda _JOYSTICK
    and #60
    clc
    lsr
    lsr
    lsr $69
    rol
.jump_to1
    tay
    ldx #168
    lda DATA_1,x
    beq .skip_nextM
    lda DATA_1+3,x
    cmp #7
    beq .skip_nextM
    tya
    eor #31
    beq .skip_nextM
    jmp .jump_to2

.skip_nextM
    ldy #104
common_sub4
    ldx #0
.top_of_loop31
    lda DATA_ROBOT_COLOURS,y
    sta DATA_CUSTOM_CHAR+208,x
    iny
    inx
    cpx #13
    bne .top_of_loop31
    rts

.jump_to2
    tya
    sta $69
    and #16
    bne .skip_nextL
    jmp .jump_to3

.skip_nextL
    lda $69
    and #4
    bne .skip_nextK
    inc DATA_1+1,x
.self_mod_2
    ldy #80
    jsr common_sub4
    ldx #168
    lda .self_mod_2+1
    cmp #80
    bne .skip_nextI
    lda #92
    bne .skip_nextJ
.skip_nextI
    lda #80
.skip_nextJ
    sta .self_mod_2+1
.skip_nextK
    lda $69
    and #2
    bne .skip_nextP
    dec DATA_1+1,x
.self_mod_3
    ldy #80
    jsr common_sub4
    ldx #168
    lda .self_mod_3+1
    cmp #80
    bne .skip_nextN
    lda #92
    bne .skip_nextO
.skip_nextN
    lda #80
.skip_nextO
    sta .self_mod_3+1
.skip_nextP
    lda $69
    and #8
    bne .skip_nextS
    dec DATA_1,x
.self_mod_4
    ldy #32
    jsr common_sub4
    ldx #168
    lda .self_mod_4+1
    cmp #32
    bne .skip_nextQ
    lda #44
    bne .skip_nextR
.skip_nextQ
    lda #32
.skip_nextR
    sta .self_mod_4+1
.skip_nextS
    lda $69
    and #1
    bne .end_routine4
    inc DATA_1,x
.self_mod_5
    ldy #56
    jsr common_sub4
    ldx #168
    lda .self_mod_5+1
    cmp #56
    bne .skip_nextT
    lda #68
    bne .skip_nextU
.skip_nextT
    lda #56
.skip_nextU
    sta .self_mod_5+1
.end_routine4
    rts

!byte $00

.jump_to3
    ldx #168
a_sub7
    lda DATA_1+81,x
    beq .skip_nextCH
    rts

.skip_nextCH
    lda $69
    and #15
    tay
    cmp #15
    bne .skip_nextK3
    rts

.skip_nextK3
    lda DATA_4+65,y
    clc
    adc DATA_1,x
    sta DATA_1+80,x
    lda DATA_4+81,y
    clc
    adc DATA_1+1,x
    sta DATA_1+81,x
    jmp .jump_top_of_loop1

!byte $00

a_subG
    jsr common_sub6
    lda DATA_1+4,x
    asl
    asl
    asl
    tay
    lda #0
    adc #24
    sta .self_mod_8+2
    cpx #176
    bcc .skip_nextAJ
    lda #8
    bne .skip_nextAI
.skip_nextAJ
    lda #48
.skip_nextAI
    sta $69
    lda DATA_1+7,x
    sta $6a
    lda DATA_1,x
    and #7
    asl
    asl
    eor #255
    sec
    adc #117
    sta .self_mod_9+1
    stx $6c
    lda DATA_1+6,x
    tax
    lda #0
.skip_nextJ1
    sta DATA_CUSTOM_CHAR,x
    inx
    dec $69
    bne .skip_nextJ1
    ldx $6c
    lda DATA_1+1,x
    and #7
    clc
    adc DATA_1+6,x
    tax
.skip_nextJ2
    lda #0
    sta $6b
.self_mod_8
    lda DATA_CUSTOM_CHAR,y
    beq .skip_nextX
.self_mod_9
    jmp .jump_to9

    lsr
    nop
    ror $6b
.jump_to9
    lsr
    nop
    ror $6b
    lsr
    nop
    ror $6b
    lsr
    nop
    ror $6b
    lsr
    nop
    ror $6b
    lsr
    nop
    ror $6b
    lsr
    nop
    ror $6b
    sta DATA_CUSTOM_CHAR,x
    cpx #111
    bcs .skip_nextX
    nop
    lda $6b
    sta DATA_CUSTOM_CHAR+24,x
.skip_nextX
    inx
    iny
    dec $6a
    bne .skip_nextJ2
    ldx $6c
    ldy #0
    lda #24
    sta $64
    lda DATA_1+6,x
    sta $63
    lda $62
    clc
    adc #120  ;screen to colour map offset (high byte)
    sta $68
    lda $61
    sta $67
    jsr common_sub3
    cpx #176
    bcc .skip_nextZ
    rts

.skip_nextZ
    jsr common_sub3
    jsr common_sub3
    jsr common_sub6
    inc $61
    lda $61
    bne .skip_nextY
    inc $62
.skip_nextY
    sta $67
    lda $62
    clc
    adc #120  ;screen to colour map offset (high byte)
    sta $68
    jsr common_sub3
    jsr common_sub3
    jsr common_sub3
    rts

a_sub9
    lda play_sound
    beq .skip_nextK6
    tax
    lda DATA_SOUNDS,x
    sta _SOUND3
    dec play_sound
.end_routine6
    rts

.skip_nextK6
    lda _SOUND3
    beq .end_routine6
    sec
    sbc #1
    cmp #218
    bne .end_routine7
    lda #0
.end_routine7         
    sta _SOUND3
    rts

a_subJ
    sed  ;set decimal
    lda score_hundreds
    clc
    adc #1
    jsr a_subH
    dec game_level
    bne .end_routine8
    inc game_level
.end_routine8
    lda #0
    rts

common_sub3         
    ldy #0
    sty $6e
    sty $6f
    lda ($61),y
    beq .skip_nextAM
    asl
    asl
    asl
    sta $65
    lda #0
    adc $64
    sta $66
.top_of_loop2
    lda ($63),y
    beq .skip_nextAK
    inc $6e
    and ($65),y
    beq .skip_nextAL
    inc $6f
.skip_nextAL
    lda ($63),y
.skip_nextAK
    ora ($65),y
    sta ($63),y
    iny
    cpy #8
    bne .top_of_loop2
    ldy #0
    lda $6e
    beq .skip_nextAN
.skip_nextAM
    lda $63
    lsr
    lsr
    lsr
    sta ($61),y
    lda DATA_1+3,x
    sta ($67),y
.skip_nextAN
    lda $63
    clc
    adc #8
    sta $63
    lda $61
    clc
    adc #22
    bcc .skip_nextAO
    inc $62
    inc $68
.skip_nextAO
    sta $61
    sta $67
    lda $6f
    bne .skip_nextAP
    rts

.skip_nextAP
    lda DATA_1+3,x
    cmp #7
    bne .skip_nextAQ
.end_routine5
    rts

.skip_nextAQ
    lda #247
    sta $00ad  ;location re-used for storage, see MTV page 49
    txa
    cmp #160
    beq .skip_nextAR
    lda #7
    sta DATA_1+3,x
    lda #24
    sta DATA_1+2,x
.skip_nextAR
    ldy #0
    lda ($65),y
    cmp #255
    beq .end_routine5
    ldy #96
.skip_nextJ3
    lda DATA_1,y
    clc
    adc #7
    cmp DATA_1,x
    bcc .skip_next_common1
    sec
    sbc #8
    cmp DATA_1,x
    bcs .skip_next_common1
    lda DATA_1+1,y
    clc
    adc #13
    cmp DATA_1+1,x
    bcc .skip_next_common1
    sec
    sbc #14
    cmp DATA_1+1,x
    bcs .skip_next_common1
    txa
    sta $69
    cpy $69
    beq .skip_next_common1
    lda #7
    sta DATA_1+3,y
    lda #14
    sta DATA_1+2,y
    cpx #248
    bne .skip_nextK2
    ldy #0

    ;update score
    sed  ;set decimal (so e.g. decimal 16 is $10 treated as decimal 10 when adding)
    clc
    lda next_screen_offset  ;increase value of dead robot, will be 0, 16, 32, 48 etc
    adc #5  ;initial value of dead robot (screen 1 is 5, screen 2 is 15, screen 3 is 25, etc)
    adc score_tens
    sta score_tens
    bcc .end_score_update
    lda #0
    adc score_hundreds
a_subH
    sta score_hundreds
    cmp #21  ;is $15 and treated as decimal 15 with decimal mode enabled (with sed)
.skip_nextK2
    bne .end_score_update
    inc player_lives  ;increase player lives at score >= 1500
.end_score_update         
    cld  ;clear decimal
    lda #15
    sta play_sound
    rts

!byte $00, $00

.skip_next_common1
    tya
    clc
    adc #8
    tay
    cpy #176
    bne .skip_nextJ3
    rts

.jump_top_of_loop1
    lda #2
    sta DATA_1+83,x
    lda $69
    and #15
    sta DATA_1+82,x
    lda play_sound
    bne .end_routineA
    lda #248
    sta _SOUND3
.end_routineA
    lda #14
    sta _VOLUME
    rts

!byte $00

end_code1