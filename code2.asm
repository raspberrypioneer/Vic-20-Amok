common_sub15
    lda data_each_thing_row,x
    bne .skip_next1
    rts

.skip_next1
    lda data_player_hero_row
    bne .skip_next2
    rts

.skip_next2
    lda #0
    sta $68
    clc
    lda data_each_thing_col,x
    ror
    sta $6e
    clc
    lda data_player_hero_col
    ror
    sta $6f
    sec
    sbc $6e
    sta $6d
    clc
    lda data_each_thing_row,x
    ror
    sta $6b
    clc
    lda data_player_hero_row
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

;-----------------------------------------------------------------------------------
swap_inner_wall_data_using_jiffy_value
    lda one_jiffy  ;jiffy real-time clock ($a2 is one jiffy)
    and #48  ;yields 0, 16, 32 or 48
    tax
    ldy #0
.swap_data_loop
    lda data_each_thing_col,x
    pha
    lda data_inner_walls,x
    sta data_each_thing_col,x
    pla
    sta data_inner_walls,x
    iny
    inx
    cpy #16
    bne .swap_data_loop
    rts

!byte $00, $00

;-----------------------------------------------------------------------------------
update_data_for_robots_and_things
    ldx #96  ;point to data_each_robot_col
.for_X_from_96_step_8_20_times_2
    lda data_each_thing_row,x
    beq .skip_to_next_robot_or_thing2
    lda data_each_thing_colour,x  ;is data_each_robot_colour
    cmp #yellow
    beq .robot_has_already_been_shot
    lda data_each_thing_status,x
    tay
    beq .skip_to_next_robot_or_thing2
    lda data_each_thing_col,x
    beq .reset_row_col_for_robot_or_thing
    clc
    adc data_robot_move_col,y
    sta data_each_thing_col,x
    lda data_robot_move_row,y
    clc
    adc data_each_thing_row,x
    sta data_each_thing_row,x
    jmp .skip_to_next_robot_or_thing2

.robot_has_already_been_shot
    dec data_each_thing_status,x
    bne .skip_to_next_robot_or_thing2
.reset_row_col_for_robot_or_thing
    lda #0
    sta data_each_thing_col,x
    sta data_each_thing_row,x
.skip_to_next_robot_or_thing2
    txa
    clc
    adc #8
    tax
    bne .for_X_from_96_step_8_20_times_2
    rts

;-----------------------------------------------------------------------------------
check_if_need_to_switch_to_next_screen
    jsr .use_player_row_col_to_decide_entrance_gate
    bpl .prepare_for_next_screen
    jmp program_loop2

.prepare_for_next_screen
    sta entrance_gate_position  ;values are 0,1,2,3,255
    lda next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    clc
    adc #16  ;offset value to point to next screen values 16, 32, 48, 64
    cmp #64
    bne .not_on_last_screen_for_level
    jsr add_100_to_score_change_level_reset_next_screen_value
.not_on_last_screen_for_level
    sta next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    jmp game_program_loop

.use_player_row_col_to_decide_entrance_gate
    lda data_player_hero_col
    cmp #1
    bne .value_not_1
    lda #2
    rts
.value_not_1
    cmp #168
    bne .value_not_168
    lda #0
    rts
.value_not_168
    lda data_player_hero_row
    cmp #1
    bne .value2_not_1
    lda #3
    rts
.value2_not_1
    cmp #170
    bne .value2_not_170
    lda #1
    rts
.value2_not_170
    lda #255
    rts

common_subZ1
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

game_action_with_speed_delay
    dec game_speed
    beq .reset_game_speed
    rts

.reset_game_speed
    lda #61
    adc game_level
    sbc next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    sta game_speed
    clc
.robot_index_1
    lda #112  ;self-mod index values 96, 104, 112, 120, 128, 136, 144, 152, then resets to 96
    adc #8
    cmp #160
    bne .reset_robot_index_1
    lda #96
.reset_robot_index_1
    sta .robot_index_1+1
    tax
    jsr common_subZ1
    beq .end_routine2
    lda $68
    bne .end_routine2
    jsr fire_bullet_if_ok
.end_routine2         
    rts

!byte $00

;-----------------------------------------------------------------------------------
check_if_player_is_dead
    lda data_player_hero_row
    beq .player_loses_life
    rts

.player_loses_life
    dec player_lives
    beq .no_more_player_lives_left
    bmi .no_more_player_lives_left_ensure_zero
    lda #0
    sta next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    jsr swap_inner_wall_data_using_jiffy_value
    jsr setup_robots_and_player
    rts

.no_more_player_lives_left_ensure_zero
    inc player_lives
.no_more_player_lives_left
    jsr select_level
    cmp #63  ;f7 key
    bne .end_routine3
    lda #3  ;player number of lives
    sta player_lives
    lda #0
    sta score_hundreds
    sta score_tens
    sta next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    lda game_select_level
    sta game_level
    jsr setup_robots_and_player
.end_routine3         
    rts

!byte $00, $00, $00, $00, $00, $00, $00

;-----------------------------------------------------------------------------------
prepare_screen_and_start_game_action

; Maintains the high byte for screen addresses used in the draw loop/item routines
; This is done via self-mod code and is also applied to a 'shadow' screen address
; which is 512 bytes below the actual screen

    lda screen_or_shadow_high
    cmp #shadow_screen_high_byte
    bne .switch_to_shadow_high_byte_update
    lda #screen_high_byte
    bne .apply_high_bytes_to_draw_routines  ;always branch
.switch_to_shadow_high_byte_update
    lda #shadow_screen_high_byte
.apply_high_bytes_to_draw_routines
    sta screen_or_shadow_high
    sta draw_top_bottom_walls_loop+7
    sta clear_spaces+2
    sta clear_spaces+5
    sta clear_screen_or_shadow_screen_loop+2
    sta draw_side_walls_loop+2
    sta draw_top_bottom_walls_loop+4
    clc
    adc #1
    sta clear_screen_or_shadow_screen_loop+5
    sta draw_side_walls_loop+5
    sta draw_top_bottom_walls_loop+10
    sta draw_top_bottom_walls_loop+13
    sta clear_spaces+8
    sta clear_spaces+11
    clc
    adc #screen_colour_map_offset-1
    sta clear_screen_or_shadow_screen_loop+8
    clc
    adc #1
    sta clear_screen_or_shadow_screen_loop+11

; The screen is drawn and game is started
    jsr draw_screen_and_start_game_action
    rts

end_code2