a_sub6
    ldy #0
    lda screen_or_shadow_high
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
    sta DATA_CUSTOM_CHAR_OTHER,y  ;Apply to custom character set 
    inx
    iny
    dec $70
    bne .charset_update_loop
    lda $6f
a_sub2  ;self-mod at +1 and +2
    sta _SCREEN_ADDR+513  ;Memory beyound the screen memory map is used (for unexpanded Vic is the standard screen map memory)
    inc $6f
    inc a_sub2+1
    rts

;-----------------------------------------------------------------------------------
screen_transition
    lda #purple
    sta data_player_hero_colour
    lda #112
    sta game_speed
    sta $a5
    sta _SOUND3
    sta _NOISE
    lda #8  ;black background and border
    sta _BACKGROUND_BORDER_COLOUR
    lda one_jiffy  ;jiffy real-time clock ($a2 is one jiffy)
    adc #24
.wait_24_jiffys
    cmp one_jiffy
    bne .wait_24_jiffys
    lda #30  ;white background, blue border
    sta _BACKGROUND_BORDER_COLOUR
    rts

;-----------------------------------------------------------------------------------
calc_map_address_using_A_for_col_and_Y_for_row
    sta $70  ;column value
    lda data_step_11,y  ;not sure why this is done as A is disgarded 2 lines later
    asl  ;multiply by 2
    lda screen_or_shadow_high
    adc #0
    sta map_address_high
    lda data_step_11,y
    asl  ;multiply by 2, which gives a row start value (0, 22, 33, 44 etc)
    clc
    adc $70 ;column value
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    sta map_address_low
    ldy #0
    rts

;-----------------------------------------------------------------------------------
calc_map_address_for_thing_X
    lda data_each_thing_row,x
    lsr
    lsr
    lsr
    tay  ;Y input for calculate map address

    lda data_each_thing_col,x
    lsr
    lsr
    lsr
    jsr calc_map_address_using_A_for_col_and_Y_for_row
    rts

;-----------------------------------------------------------------------------------
;Data = $19e8 to $1a78 (6632 to 6776)
;18 x 8 = 144
;table for start of row, the looked up value is multiplied by 2, which gives a row start value (0, 22, 33, 44 etc)
data_step_11
    !byte 0, 11, 22, 33, 44, 55, 66, 77
    !byte 88, 99, 110, 121, 132, 143, 154, 165
    !byte 176, 187, 198, 209, 220, 231, 242, 253

data_player_animation
data_robot_colours
    !byte green, cyan, red, black, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00

data_sounds
    !byte $00, $00, $e8, $ec, $f0, $f2, $f5, $f7
    !byte $f8, $f9, $f9, $f8, $f5, $f3, $f0, $ec

;player animation position 32 move left 1
    !byte %00000000
    !byte %00110000
    !byte %00110000
    !byte %00010000
    !byte %01001110
    !byte %00111010
    !byte %00001000
    !byte %00001000
    !byte %00010101
    !byte %00010010
    !byte %00001000
    !byte %00000000

;player animation position 44 move left 2
    !byte %00000000
    !byte %00110000
    !byte %00110000
    !byte %00010000
    !byte %00001000
    !byte %00101100
    !byte %00011100
    !byte %00001000
    !byte %00001100
    !byte %00001010
    !byte %00000101
    !byte %00000000

;player animation position 56 move right 1
    !byte %00000000
    !byte %00001100
    !byte %00001100
    !byte %00001000
    !byte %00010000
    !byte %00110100
    !byte %00111000
    !byte %00110000
    !byte %00110000
    !byte %01010000
    !byte %10100000
    !byte %00000000

;player animation position 68 move right 2
    !byte %00000000
    !byte %00001100
    !byte %00001100
    !byte %00001000
    !byte %01110000
    !byte %01010000
    !byte %00010000
    !byte %00010000
    !byte %10101000
    !byte %01001000
    !byte %00010000
    !byte %00000000

;player animation position 80 move up-down 1
    !byte %00000000
    !byte %00001000
    !byte %00011100
    !byte %00001000
    !byte %00111100
    !byte %00101010
    !byte %00001010
    !byte %00010100
    !byte %00010110
    !byte %00110000
    !byte %00000000
    !byte %00000000

;player animation position 92 move up-down 2
    !byte %00000000
    !byte %00001000
    !byte %00011100
    !byte %00001000
    !byte %00011110
    !byte %00101010
    !byte %00101000
    !byte %00010100
    !byte %00110100
    !byte %00000110
    !byte %00000000
    !byte %00000000

;player animation position 104 standing
    !byte %00000000
    !byte %00001000
    !byte %00011100
    !byte %00001000
    !byte %00011100
    !byte %00101010
    !byte %00101010
    !byte %00001000
    !byte %00010100
    !byte %00010100
    !byte %00010100
    !byte %00110110

    !byte $00, $00, $00, $00

;-----------------------------------------------------------------------------------
title_screen_select_option
    ldx #0
    lda #blue
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
    sta next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    sta entrance_gate_position  ;values are 0,1,2,3,255
    sta play_sound_duration
    sta score_hundreds
    sta score_tens
    rts

;-----------------------------------------------------------------------------------
;Data = $1a9f to $1af8 (6807 to 6904)
;12 x 8 = 96 +1 bytes
    !byte $00
    !byte $00, $00, $00, $f3, $60, $00, $00, $00
data_entrance_gate_high
data_entrance_gate_low = data_entrance_gate_high+1
    !byte $00, $dc, $16, $16
    !byte $00, $0a, $01, $00
    !byte $00, $f1, $16, $16
    !byte $01, $ee, $01, $00
data_player_start_col
    !byte 9, 83, 153, 84
data_player_start_row
    !byte 82, 10, 82, 160
data_robot_move_col
    !byte $00, $00, $00, $ff, $00, $ff, $00, $ff
    !byte $00, $00, $01, $00, $01, $00, $01, $00
data_robot_move_row
    !byte $00, $01, $01, $01, $00, $ff, $00, $00
    !byte $00, $00, $01, $01, $ff, $ff, $00, $00
data_bullet_start_col
    !byte $00, $00, $00, $ff, $00, $00, $00, $00
    !byte $00, $00, $09, $05, $08, $05, $08, $00
data_bullet_start_row
    !byte $00, $00, $00, $08, $00, $00, $00, $03
    !byte $00, $00, $08, $0e, $00, $00, $03, $00

a_subF
.robot_index_2
    ldx #144  ;self-mod index values 144, 152, 96, 104, 112, 120, 128, 136, 144, 152, then resets to 96
    lda data_each_thing_col,x
    ora data_each_thing_row,x
    and #7
    bne .end_routineH
    lda data_each_thing_colour,x
    cmp #yellow
    beq .robot_has_been_shot_goto_next_one
    lda #0
    sta data_each_thing_status,x
.robot_has_been_shot_goto_next_one
    dec $a5
    beq .skip_to_next_robot
.end_routineH
    rts

.skip_to_next_robot
    txa
    clc
    adc #8
    cmp #160
    bne .reset_robot_index_2
    lda #96
.reset_robot_index_2
    tax
    sta .robot_index_2+1
    lda data_each_thing_colour,x
    cmp #yellow
    bne .robot_still_alive_continue
    lda game_level
    sta $a5
    rts

.robot_still_alive_continue
    jsr common_subZ1
    lda one_jiffy  ;jiffy real-time clock ($a2 is one jiffy)
    and #15
    bne .skip_nextA3
.top_of_loop1
    inc $a7
    lda $a7
    and #15
    sta $69
.skip_nextA3
    jsr calc_map_address_for_thing_X
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
    sta data_each_thing_status,x
    lda game_level
    sta $a5
    rts

!byte $00

common_sub1
    lda map_address_high
    sta $64
    tya  ;Y is added to map_address_low for $63 (low) and either increasing or decreasing $64 (high), dependent on Y value bit 7
    beq .Y_is_zero_so_end
    bmi .Y_bit_7_is_1
    clc
    adc map_address_low
    bcc *+4  ;skip high byte update line below
    inc $64
    jmp .check_calculated_address

.Y_bit_7_is_1
    sec
    adc map_address_low
    bcs *+4  ;skip high byte update line below
    dec $64
.check_calculated_address
    sta $63  ;calculated address low byte (from map address and Y above)
    ldy #0
    lda ($63),y
    cmp #7
    bcc *+4  ;skip high byte update line below
    inc $6f
.Y_is_zero_so_end
    lda $69
    rts

;-----------------------------------------------------------------------------------
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

end_code3