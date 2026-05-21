;DATA_3 = $19e8 to $1a78 (6632 to 6776)
;18 x 8 = 144
DATA_3
    !byte $00, $0b, $16, $21, $2c, $37, $42, $4d
    !byte $58, $63, $6e, $79, $84, $8f, $9a, $a5
    !byte $b0, $bb, $c6, $d1, $dc, $e7, $f2, $fd
DATA_ROBOT_COLOURS
    !byte $05, $03, $02, $00
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00
DATA_SOUNDS
    !byte $00, $00, $e8, $ec, $f0, $f2, $f5, $f7
    !byte $f8, $f9, $f9, $f8, $f5, $f3, $f0, $ec
DATA_3B
    !byte $00, $30, $30, $10, $4e, $3a, $08, $08
    !byte $15, $12, $08, $00, $00, $30, $30, $10
    !byte $08, $2c, $1c, $08, $0c, $0a, $05, $00
    !byte $00, $0c, $0c, $08, $10, $34, $38, $30
    !byte $30, $50, $a0, $00, $00, $0c, $0c, $08
    !byte $70, $50, $10, $10, $a8, $48, $10, $00
    !byte $00, $08, $1c, $08, $3c, $2a, $0a, $14
    !byte $16, $30, $00, $00, $00, $08, $1c, $08
    !byte $1e, $2a, $28, $14, $34, $06, $00, $00
    !byte $00, $08, $1c, $08, $1c, $2a, $2a, $08
    !byte $14, $14, $14, $36, $00, $00, $00, $00

title_screen_select_option
    ldx #0
    lda #6  ;blue colour
.set_screen_colour_loop
    sta _COLOUR_SCREEN_ADDR,x
    sta _COLOUR_SCREEN_ADDR+256,x
    inx
    bne .set_screen_colour_loop

    lda #3  ;player number of lives
    sta player_lives
    sta $a6

.wait_f7_game_start_loop
    jsr select_level
    cmp #63  ;f7 key
    bne .wait_f7_game_start_loop

    lda #0
    sta next_screen_offset
    sta $72
    sta play_sound
    sta score_hundreds
    sta score_tens
    rts

;DATA_4 = $1a9f to $1af8 (6807 to 6904)
;12 x 8 = 96 +1 bytes
DATA_4
    !byte $00, $00, $00, $00, $f3, $60, $00, $00
    !byte $00, $00, $dc, $16, $16, $00, $0a, $01
    !byte $00, $00, $f1, $16, $16, $01, $ee, $01
    !byte $00, $09, $53, $99, $54, $52, $0a, $52
    !byte $a0, $00, $00, $00, $ff, $00, $ff, $00
    !byte $ff, $00, $00, $01, $00, $01, $00, $01
    !byte $00, $00, $01, $01, $01, $00, $ff, $00
    !byte $00, $00, $00, $01, $01, $ff, $ff, $00
    !byte $00, $00, $00, $00, $ff, $00, $00, $00
    !byte $00, $00, $00, $09, $05, $08, $05, $08
    !byte $00, $00, $00, $00, $08, $00, $00, $00
    !byte $03, $00, $00, $08, $0e, $00, $00, $03
    !byte $00

a_subF
    ldx #144
    lda DATA_1,x
    ora DATA_1+1,x
    and #7
    bne .end_routineH
    lda DATA_1+3,x
    cmp #7
    beq .skip_nextCN
    lda #0
    sta DATA_1+2,x
.skip_nextCN
    dec $a5
    beq .skip_nextCM
.end_routineH
    rts

.skip_nextCM
    txa
    clc
    adc #8
    cmp #160
    bne .skip_nextA1
    lda #96
.skip_nextA1
    tax
    sta a_subF+1
    lda DATA_1+3,x
    cmp #7
    bne .skip_nextA2
    lda game_level
    sta $a5
    rts

.skip_nextA2
    jsr common_sub11
    lda $a2  ;jiffy real-time clock ($a2 is one jiffy)
    and #15
    bne .skip_nextA3
.top_of_loop1
    inc $a7
    lda $a7
    and #15
    sta $69
.skip_nextA3
    jsr common_sub6
    sty $6f
    lda $69
    and #1
    bne .skip_nextA4
    ldy #1
    jsr common_sub1
    ldy #23
.skip_nextA4         
    jsr common_sub1
    cmp #10
    bne .skip_nextA5
    ldy #45
.skip_nextA5
    jsr common_sub1
    cmp #12
    bne .skip_nextAC
    ldy #234
.skip_nextAC
    jsr common_sub1
    and #2
    bne .skip_nextAD
    ldy #233
.skip_nextAD
    jsr common_sub1
    and #8
    bne .skip_nextA8
    ldy #254
    jsr common_sub1
    ldy #21
.skip_nextA8
    jsr common_sub1
    cmp #3
    bne .skip_nextA9
    ldy #43
.skip_nextA9
    jsr common_sub1
    cmp #5
    bne .skip_nextAA
    ldy #232
.skip_nextAA
    jsr common_sub1
    and #4
    bne .skip_nextAB
    ldy #44
.skip_nextAB
    jsr common_sub1
    lda $6f
    bne .top_of_loop1
    lda $69
    sta DATA_1+2,x
    lda game_level
    sta $a5
    rts

!byte $00

common_sub1
    lda $62
    sta $64
    tya
    beq .end_routineI
    bmi .skip_nextCK
    clc
    adc $61
    bcc .skip_nextCI
    inc $64
.skip_nextCI
    jmp .skip_nextCJ

.skip_nextCK
    sec
    adc $61
    bcs .skip_nextCJ
    dec $64
.skip_nextCJ
    sta $63
    ldy #0
    lda ($63),y
    cmp #7
    bcc .end_routineI
    inc $6f
.end_routineI
    lda $69
    rts

select_level
    lda $cb  ;matrix coordinate of current key pressed, 64 if none
    cmp #39  ;f1 key
    bne .end_select_level
    lda game_select_level
    sec
    sbc #1
    bne .not_level_zero
    lda #9
.not_level_zero
    sta game_level
    sta game_select_level
    lda #58  ;translate game level to ASCII for display (values 49 to 57 for levels 1 to 9)
    sec
    sbc game_select_level
    sta _SCREEN_ADDR+500  ;shows game level
    and #15
    sta score_tens
.debounce_loop
    lda $cb  ;matrix coordinate of current key pressed, 64 if none
    cmp #39  ;f1 key
    beq .debounce_loop
.end_select_level
    rts

!byte $00

end_code4