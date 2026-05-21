common_sub15
    lda DATA_1+1,x
    bne .skip_next1
    rts

.skip_next1
    lda DATA_1+169
    bne .skip_next2
    rts

.skip_next2
    lda #0
    sta $68
    clc
    lda DATA_1,x
    ror
    sta $6e
    clc
    lda DATA_1+168
    ror
    sta $6f
    sec
    sbc $6e
    sta $6d
    clc
    lda DATA_1+1,x
    ror
    sta $6b
    clc
    lda DATA_1+169
    ror
    sta $6c
    sec
    sbc $6b
    sta $6a
    lda $6d
    bpl .skip_nextBA
    eor #255
.skip_nextBA
    cmp $70
    bcs .skip_nextG1
    lda $6a
    bmi .skip_next3
    lda #11
    bne .end_routineB
.skip_next3
    lda #13
.end_routineB
    sta $69
    rts

.skip_nextG1         
    lda $6a
    bpl .skip_nextBB
    eor #255
.skip_nextBB
    cmp $70
    bcs .skip_nextBC
    lda $6d
    bpl .skip_next4
    lda #7
    bne .end_routineC
.skip_next4         
    lda #14
.end_routineC
    sta $69
    rts

.skip_nextBC
    lda $6d
    bpl .skip_nextBD
    eor #255
.skip_nextBD
    sta $6f
    lda $6a
    bpl .skip_nextBE
    eor #255
.skip_nextBE
    sec
    sbc $6f
    bpl .skip_nextBF
    eor #255
.skip_nextBF
    cmp $70
    bcc .skip_nextBG
    lda #1
    sta $68
.skip_nextBG
    lda $6a
    bpl .skip_nextBH
    lda $6d
    bpl .skip_next5
    lda #5
    bne .end_routineD
.skip_next5
    lda #12
.end_routineD
    sta $69
    rts

.skip_nextBH
    lda $6d
    bpl .skip_next6
    lda #3
    bne .end_routineE
.skip_next6
    lda #10
.end_routineE
    sta $69
    rts

!byte $00

a_subK
    lda $a2  ;jiffy real-time clock ($a2 is one jiffy)
    and #48  ;yields 0, 16, 32 or 48
    tax
    ldy #0
.top_of_loop5
    lda DATA_1,x
    pha
    lda DATA_1+32,x
    sta DATA_1,x
    pla
    sta DATA_1+32,x
    iny
    inx
    cpy #16
    bne .top_of_loop5
    rts

!byte $00, $00

a_subE
    ldx #96
.top_of_loop6
    lda DATA_1+1,x
    beq .skip_nextBI
    lda DATA_1+3,x
    cmp #7
    beq .skip_nextBJ
    lda DATA_1+2,x
    tay
    beq .skip_nextBI
    lda DATA_1,x
    beq .skip_nextBK
    clc
    adc DATA_4+33,y
    sta DATA_1,x
    lda DATA_4+49,y
    clc
    adc DATA_1+1,x
    sta DATA_1+1,x
    jmp .skip_nextBI

.skip_nextBJ
    dec DATA_1+2,x
    bne .skip_nextBI
.skip_nextBK
    lda #0
    sta DATA_1,x
    sta DATA_1+1,x
.skip_nextBI
    txa
    clc
    adc #8
    tax
    bne .top_of_loop6
    rts

a_sub4
    jsr a_subI
    bpl .skip_next7
    jmp program_loop2

.skip_next7
    sta $72
    lda next_screen_offset
    clc
    adc #16  ;offset value to point to next screen values 16, 32, 48, 64
    cmp #64
    bne .skip_next8
    jsr a_subJ
.skip_next8
    sta next_screen_offset
    jmp program_loop1

a_subI
    lda DATA_1+168
    cmp #1
    bne .skip_next9
    lda #2
    rts

.skip_next9
    cmp #168
    bne .skip_nextA
    lda #0
    rts

.skip_nextA
    lda DATA_1+169
    cmp #1
    bne .skip_nextB
    lda #3
    rts

.skip_nextB
    cmp #170
    bne .skip_nextC
    lda #1
    rts

.skip_nextC
    lda #255
    rts

common_sub11
    lda #3
    sta $70
    jsr common_sub15
    bne .skip_nextD
.end_routineF
    rts

.skip_nextD
    lda $69
    bne .end_routineF
    lda #14
    sta $70
    jsr common_sub15
    rts

a_subA
    dec $a4
    beq .skip_nextE
    rts

.skip_nextE
    lda #61
    adc game_level
    sbc next_screen_offset
    sta $a4
    clc
.self_mod_6
    lda #112
    adc #8
    cmp #160
    bne .skip_nextBL
    lda #96
.skip_nextBL
    sta .self_mod_6+1
    tax
    jsr common_sub11
    beq .end_routine2
    lda $68
    bne .end_routine2
    jsr a_sub7
.end_routine2         
    rts

!byte $00

a_sub3
    lda DATA_1+169
    beq .skip_nextF
    rts

.skip_nextF
    dec player_lives
    beq .skip_nextBM
    bmi .skip_nextBN
    lda #0
    sta next_screen_offset
    jsr a_subK
    jsr common_sub13
    rts

.skip_nextBN
    inc player_lives
.skip_nextBM
    jsr select_level
    cmp #63  ;f7 key
    bne .end_routine3
    lda #3  ;player number of lives
    sta player_lives
    lda #0
    sta score_hundreds
    sta score_tens
    sta next_screen_offset
    lda game_select_level
    sta game_level
    jsr common_sub13
.end_routine3         
    rts

!byte $00, $00, $00, $00, $00, $00, $00

a_sub8
    lda $60
    cmp #30
    bne .skip_nextG
    lda #28
    bne .skip_nextH
.skip_nextG
    lda #30
.skip_nextH
    sta $60
    sta draw_loop3+7
    sta draw_item+2
    sta draw_item+5
    sta draw_loop1+2
    sta draw_loop2+2
    sta draw_loop3+4
    clc
    adc #1
    sta draw_loop1+5
    sta draw_loop2+5
    sta draw_loop3+10
    sta draw_loop3+13
    sta draw_item+8
    sta draw_item+11
    clc
    adc #119
    sta draw_loop1+8
    clc
    adc #1
    sta draw_loop1+11
    jsr draw_screen
    rts

end_code2