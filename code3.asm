a_sub6
    ldy #0
    lda $60
    sta a_sub2+2
    lda #32
    sta $6f
    lda #1
    sta a_sub2+1
    lda score_hundreds
    and #240
    lsr
    tax
    jsr update_custom_chars_from_reversed_set
    lda score_hundreds
    and #15
    asl
    asl
    asl
    tax
    jsr update_custom_chars_from_reversed_set
    lda score_tens
    and #240
    lsr
    tax
    jsr update_custom_chars_from_reversed_set
    lda score_tens
    and #15
    asl
    asl
    asl
    tax
    jsr update_custom_chars_from_reversed_set
    lda #19
    sta a_sub2+1
    lda #36
    sta $6f
    jsr a_sub2
    lda player_lives
    asl
    asl
    asl
    tax
    ldy #40

update_custom_chars_from_reversed_set
    lda #8
    sta $70
.charset_update_loop
    lda _CASEURV+384,x  ;Point to reversed charcater set
    sta DATA_CUSTOM_CHAR+256,y  ;Apply to custom character set 
    inx
    iny
    dec $70
    bne .charset_update_loop
    lda $6f
a_sub2
    sta _SCREEN_ADDR+513  ;Memory beyound the screen memory map is used (for unexpanded Vic is the standard screen map memory)
    inc $6f
    inc a_sub2+1
    rts

screen_transition
    lda #4
    sta DATA_1+171
    lda #112
    sta $a4
    sta $a5
    sta _SOUND3
    sta _NOISE
    lda #8  ;black background and border
    sta _BACKGROUND_BORDER_COLOUR
    lda $a2  ;jiffy real-time clock ($a2 is one jiffy)
    adc #24
.wait_24_jiffys
    cmp $a2
    bne .wait_24_jiffys
    lda #30  ;white background, blue border
    sta _BACKGROUND_BORDER_COLOUR
    rts

common_sub14
    sta $70
    lda DATA_3,y
    asl
    lda $60
    adc #0
    sta $62
    lda DATA_3,y
    asl
    clc
    adc $70
    bcc .end_routineG
    inc $62
.end_routineG
    sta $61
    ldy #0
    rts

common_sub6
    lda DATA_1+1,x
    lsr
    lsr
    lsr
    tay
    lda DATA_1,x
    lsr
    lsr
    lsr
    jsr common_sub14
    rts

end_code3