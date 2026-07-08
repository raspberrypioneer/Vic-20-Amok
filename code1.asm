start_of_program
    lda #22  ;22 columns on screen
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

game_program_loop
    jsr setup_robots_and_player
program_loop2
    jsr prepare_screen_and_start_game_action
    lda screen_or_shadow_high
    cmp #shadow_screen_high_byte
    bne .switch_to_screen_at_7168
    lda #%10010110  ;prepare screen address at $1e00 (7680) for _VICCR2 (bit 7)
    bne .set_VICCR2_and_continue
.switch_to_screen_at_7168
    lda #%00010110  ;prepare screen address at $1c00 (7168) for _VICCR2 (bit 7)
.set_VICCR2_and_continue
    sta _VICCR2
    jsr play_sound_in_SOUND3
    jsr handle_robots_fire_bullets
    jmp check_if_need_to_switch_to_next_screen

!byte $00,$00

;-----------------------------------------------------------------------------------
draw_screen_and_start_game_action    

;clear screen or shadown screen (high byte is self-mod and switched each tick)
    ldx #0
    lda #0  ;black colour, empty screen
clear_screen_or_shadow_screen_loop
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+256,x  ;self-mod (high byte)
    sta _COLOUR_SCREEN_ADDR,x  ;self-mod (high byte)
    sta _COLOUR_SCREEN_ADDR+256,x  ;self-mod (high byte)
    inx
    bne clear_screen_or_shadow_screen_loop

;draw walls on side borders
    lda #wall_character  ;block character
draw_side_walls_loop
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+484,x  ;self-mod (high byte)
    inx
    cpx #22  ;22 columns on screen
    bne draw_side_walls_loop

;draw walls on top and bottom borders
    ldx #0
draw_top_bottom_walls_loop
    lda #wall_character  ;block character
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+21,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+286,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+307,x  ;self-mod (high byte)
    clc
    txa
    adc #22  ;move to next column
    tax
    cpx #220
    bne draw_top_bottom_walls_loop

;clear spaces
    lda #0
clear_spaces
    sta _SCREEN_ADDR+10  ;self-mod (high byte)
    sta _SCREEN_ADDR+11  ;self-mod (high byte)
    sta _SCREEN_ADDR+494  ;self-mod (high byte)
    sta _SCREEN_ADDR+495  ;self-mod (high byte)

;draw inner walls depending on screen offset
    ldx next_screen_offset  ;next screen values 0, 16, 32, 48, 64
.plot_walls_loop
    jsr setup_walls
    lda data_each_thing_col,x
    beq .skip_part_of_wall_draw

.plot_wall_length_loop
    lda #wall_character  ;block character for inner walls
    sta (map_address_low),y
    lda map_address_low
    clc
.horizontal_or_vertical_offset
    adc #0  ;#0 is a self-mod value
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    sta map_address_low
    iny
    cpy #5  ;controls the length of each wall (horizontal or vertical)
    bne .plot_wall_length_loop

.skip_part_of_wall_draw
    lda .horizontal_or_vertical_offset+1
    beq .skip_to_vertical_wall
    lda #0  ;horizontal wall
    beq .apply_wall_offset  ;always branch
.skip_to_vertical_wall
    lda #21  ;vertical wall
.apply_wall_offset
    sta .horizontal_or_vertical_offset+1
    inx
    txa
    and #%00000111  ;7
    bne .plot_walls_loop

;draw entrance gate (closed / blocked off)
    ldy #0
    lda entrance_gate_position  ;values are 0,1,2,3,255
    asl
    asl
    tax  ;X values are 0,4,8,12
    sty map_address_low
    lda screen_or_shadow_high
    adc data_entrance_gate_high,x
    sta map_address_high

    ;draw 3 gate characters
    jsr .draw_entrance_close_gate
    jsr .draw_entrance_close_gate
    jsr .draw_entrance_close_gate

;start the game action
    jsr handle_robot_player_and_bullets
    jsr get_user_input
    jsr check_if_player_is_dead
    jsr update_data_for_robots_and_things
    jsr move_robots
    jsr show_score_player_lives_on_top_row
    rts

!byte $00,$00,$00,$00,$00,$00,$00,$00,$00

;-----------------------------------------------------------------------------------
.draw_entrance_close_gate
    ;X values are 0,4,8,12
    clc
    lda data_entrance_gate_low,x
    adc map_address_low
    sta map_address_low
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    lda #gate_character
    sta (map_address_low),y
    inx
    rts

;-----------------------------------------------------------------------------------
;Data = $1100 to $11b1 (4352 to 4529)
;256 bytes in this data block
data_each_thing_col
data_each_thing_row = data_each_thing_col+1
data_each_thing_status = data_each_thing_col+2
data_each_thing_colour = data_each_thing_col+3
data_each_thing_character = data_each_thing_col+4
    !byte $1e, $48, $e6, $d6, $56, $63, $00, $00
    !byte $c5, $35, $a9, $4c, $f0, $34, $8a, $cc
    !byte $88, $77, $00, $00, $49, $73, $00, $00
    !byte $22, $57, $f0, $b3, $b8, $0e, $05, $dd
data_inner_walls  ;from 0, 16, 32, 46 for 16 characters each time, see swap_inner_wall_data_using_jiffy_value
    !byte $65, $00, $93, $00, $2d, $00, $5b, $00  ;inner wall data
    !byte $df, $33, $0f, $a5, $0b, $48, $33, $0d  ;inner wall data

    !byte $58, $7a, $9b, $93, $00, $00, $00, $00  ;inner wall data
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71  ;inner wall data

    !byte $00, $4a, $00, $26, $00, $c4, $00, $a4  ;inner wall data
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71  ;inner wall data

data_for_bullets_col  ;this address is offset by Y which points to data_robot_bullet and data_player_bullet below
data_for_bullets_row = data_for_bullets_col+1
data_for_bullets_status = data_for_bullets_col+2
data_for_bullets_colour = data_for_bullets_col+3
data_for_bullets_character = data_for_bullets_col+4
    !byte $00, $00, $00, $00, $00, $00, $00, $00  ;inner wall data
    !byte $df, $33, $0f, $a5, $0c, $48, $33, $0d  ;inner wall data

data_each_robot_col
data_each_robot_row = data_each_robot_col+1
data_each_robot_status = data_each_robot_col+2
data_each_robot_colour = data_each_robot_col+3
data_each_robot_character = data_each_robot_col+4
    !byte $60, $20, $00, red, robot_head1, $02, $40, $10
    !byte $20, $30, $00, red, robot_head1, $02, $40, $10
    !byte $60, $58, $00, red, robot_head1, $02, $40, $10
    !byte $38, $78, $00, red, robot_head1, $02, $40, $10
    !byte $90, $28, $00, red, robot_head1, $02, $40, $10
    !byte $38, $48, $00, red, robot_head1, $02, $40, $10
    !byte $10, $52, $00, red, robot_head1, $02, $40, $10
    !byte $98, $98, $00, red, robot_head1, $02, $40, $10
    !byte $00, $00, $00, red, robot_head2, $02, $40, $10

data_player_hero_col
data_player_hero_row = data_player_hero_col+1
data_player_hero_colour = data_player_hero_col+3
data_player_hero_character = data_player_hero_col+4
    !byte $60, $20, $00, purple, player_head1, $02, $10, $10  ;player data from position 168

data_robot_bullet
    !byte $00, $00, $00, red, bullet_character, $01, $70, $08
    !byte $0f, $00, $03, red, bullet_character, $01, $78, $08
    !byte $60, $2d, $00, yellow, bullet_character, $01, $80, $08
    !byte $00, $00, $00, red, bullet_character, $01, $88, $08
    !byte $00, $00, $00, red, bullet_character, $01, $90, $08
    !byte $00, $00, $00, red, bullet_character, $01, $98, $08
    !byte $00, $00, $00, red, bullet_character, $01, $a0, $08
    !byte $00, $00, $00, red, bullet_character, $01, $a8, $08
    !byte $00, $00, $00, red, bullet_character, $01, $b0, $08

data_player_bullet
    !byte $00, $00, $00, red, bullet_character, $01, $b8, $08

;-----------------------------------------------------------------------------------
setup_walls
    txa
    clc
    and #%00000111  ;7
    sta $70
    lda data_each_thing_col,x
    and #%00001111  ;15
    adc $70
    tay  ;Y input for calculate map address

    lda data_each_thing_col,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc $70
    jsr calc_map_address_using_A_for_col_and_Y_for_row
    rts

;-----------------------------------------------------------------------------------
setup_robots_and_player
    ldy #0
    lda next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    clc
    adc #8
    tax  ;so X is 8, 24, 40, 56 etc to start with and increases +1 in loop
.loop_8_times_Y_0_to_56_step_8         
    txa
    and #%00000111  ;7
    sta $65
    lda data_each_thing_col,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc $65
    asl
    asl
    asl
    sta data_each_robot_col,y
    lda data_each_thing_col,x
    and #%00001111  ;15
    clc
    adc $65
    asl
    asl
    asl
    sta data_each_robot_row,y

    lda #0
    sta data_player_bullet+1
    sta data_each_robot_status,y
    sta data_robot_bullet+1,y

    ;decide robot colour from screen offset
    lda next_screen_offset  ;next screen values 0, 16, 32, 48, 64
    lsr
    lsr
    lsr
    lsr
    sta .robot_colour+1  ;values 0, 1, 2, 3, 4
.robot_colour
    lda data_robot_colours  ;self-mod of low byte to address of robot colour data
    sta data_each_robot_colour,y
    inx
    tya
    adc #8
    tay  ;so Y is 0, 8, 16, 24, 32, 40, 48, 56 within loop
    cmp #64
    bne .loop_8_times_Y_0_to_56_step_8

    ldx entrance_gate_position  ;values are 0,1,2,3,255
    lda data_player_start_col,x
    sta data_player_hero_col
    lda data_player_start_row,x
    sta data_player_hero_row
    jsr screen_transition
    rts

!byte $00, $00, $00, $00

;-----------------------------------------------------------------------------------
handle_robot_player_and_bullets

    ldx #96  ;point to data_each_robot_col
.for_X_from_96_step_8_20_times
    lda data_each_thing_row,x
    beq .skip_to_next_robot_or_thing
    cpx #player_data_index  ;after robots, deal with player and bullets
    bcs .handle_player_and_bullets
    and #7
    bne .handle_player_and_bullets

    ;plot robot character
    lda data_each_thing_row,x
    lsr
    lsr
    lsr
    tay  ;Y input for calculate map address (row)

    lda data_each_thing_col,x
    and #7
    bne .handle_player_and_bullets
    lda data_each_thing_col,x
    lsr
    lsr
    lsr  ;A at this point is ready to calculate map address (col)
    jsr calc_map_address_using_A_for_col_and_Y_for_row

    ;plot robot head and tail characters
    lda data_each_thing_character,x  ;with X is data_each_robot_character
    sta (map_address_low),y
    ldy #22  ;row below
    clc
    adc #1  ;is tail character (+1 from head)
    sta (map_address_low),y

    ;plot robot colour
    lda map_address_low
    sta $63  ;colour map low
    lda map_address_high
    clc
    adc #screen_colour_map_offset
    sta $64  ;colour map high
    lda data_each_thing_colour,x
    ldy #0
    sta ($63),y
    ldy #22  ;row below
    sta ($63),y

.skip_to_next_robot_or_thing
    txa
    clc
    adc #8
    tax
    bne .for_X_from_96_step_8_20_times
    rts

.handle_player_and_bullets
    jsr plot_player_and_bullets
    jmp .skip_to_next_robot_or_thing

;-----------------------------------------------------------------------------------
;Get user input
get_user_input
    dec $a3  ;get user input evey third tick
    beq .get_keys_joystick_input
    rts
.get_keys_joystick_input
    lda #3
    sta $a3
    lda $cb  ;matrix coordinate of current key pressed, 64 if none
    cmp #64
    beq .keys_not_pressed_check_joystick
    cmp #28  ;keyboard N key
    bne *+4  ;skip next instruction
    lda #%00011011  ;27
    cmp #51  ;keyboard U key
    bne *+4  ;skip next instruction
    lda #%00011101  ;29
    cmp #20  ;keyboard J key
    bne *+4  ;skip next instruction
    lda #%00011110  ;30
    cmp #43  ;keyboard H key
    bne *+4  ;skip next instruction
    lda #%00010111  ;23
    ldy $028d  ;Keyboard shift / control flag
    beq .shift_etc_not_pressed
    and #%00001111  ;15 
.shift_etc_not_pressed
    jmp .handle_input_directions_and_fire

.keys_not_pressed_check_joystick
    lda #0
    sta _DATADIR_B
    lda _KEYB_ROWS
    asl  ;bit 7 into carry, 0 into bit 0
    rol key_press  ;carry into bit 0, bit 7 into carry
    lda #255
    sta _DATADIR_B

    ;build A with joystick bits and bit for right direction (above)
    ;00010000 fire (16)
    ;00001000 left (8)
    ;00000100 down (4)
    ;00000010 up (2)
    ;00000001 right (1) the right bit is added below
    lda _JOYSTICK
    and #%00111100  ;60
    clc
    lsr  ;together lose bits 0,1
    lsr  ;together lose bits 0,1
    lsr key_press  ;bit 0 into carry, to pickup this bit from key_press
    rol  ;carry into bit 0, so key_press has bit 0 tagged into A
.handle_input_directions_and_fire
    tay  ;direction from key / joystick
    ldx #player_data_index
    lda data_each_thing_col,x
    beq .player_was_shot_or_no_input
    lda data_each_thing_colour,x
    cmp #yellow
    beq .player_was_shot_or_no_input
    tya  ;direction from key / joystick
    eor #%00011111  ;31
    beq .player_was_shot_or_no_input
    jmp .handle_input_directions_and_fire_continued

.player_was_shot_or_no_input
    ldy #104
animate_player_sprite
    ldx #0
.copy_12_player_sprite_chars_loop
    lda data_player_animation,y
    sta data_player_custom_characters,x
    iny
    inx
    cpx #13  ;stops at 12 characters because bottom 4 (of the 16 head + tail bytes) are always empty / blank
    bne .copy_12_player_sprite_chars_loop
    rts

;-----------------------------------------------------------------------------------
.handle_input_directions_and_fire_continued
    tya  ;direction from key / joystick
    sta key_press
    and #%00010000  ;16 fire button
    bne .check_down_direction
    jmp .fire_button_pressed

.check_down_direction
    lda key_press
    and #%00000100  ;4 down direction
    bne .check_up_direction
    inc data_each_thing_row,x
.animate_player_down
    ldy #player_animate_up_down_offset
    jsr animate_player_sprite
    ldx #player_data_index
    lda .animate_player_down+1
    cmp #player_animate_up_down_offset
    bne .switch_animate_player_down
    lda #player_animate_up_down_offset+12
    bne .save_animate_player_down  ;always branch
.switch_animate_player_down
    lda #player_animate_up_down_offset
.save_animate_player_down
    sta .animate_player_down+1

.check_up_direction
    lda key_press
    and #%00000010  ;2 up direction
    bne .check_left_direction
    dec data_each_thing_row,x
.animate_player_up
    ldy #player_animate_up_down_offset
    jsr animate_player_sprite
    ldx #player_data_index
    lda .animate_player_up+1
    cmp #player_animate_up_down_offset
    bne .switch_animate_player_up
    lda #player_animate_up_down_offset+12
    bne .save_animate_player_up
.switch_animate_player_up
    lda #player_animate_up_down_offset
.save_animate_player_up
    sta .animate_player_up+1

.check_left_direction
    lda key_press
    and #%00001000  ;8 left direction
    bne .check_right_direction
    dec data_each_thing_col,x
.animate_player_left
    ldy #player_animate_left_offset
    jsr animate_player_sprite
    ldx #player_data_index
    lda .animate_player_left+1
    cmp #player_animate_left_offset
    bne .switch_animate_player_left
    lda #player_animate_left_offset+12
    bne .save_animate_player_left
.switch_animate_player_left
    lda #player_animate_left_offset
.save_animate_player_left
    sta .animate_player_left+1

.check_right_direction
    lda key_press
    and #%00000001  ;1 right direction
    bne .end_player_directions
    inc data_each_thing_col,x
.animate_player_right
    ldy #player_animate_right_offset
    jsr animate_player_sprite
    ldx #player_data_index
    lda .animate_player_right+1
    cmp #player_animate_right_offset
    bne .switch_animate_player_right
    lda #player_animate_right_offset+12
    bne .save_animate_player_right
.switch_animate_player_right
    lda #player_animate_right_offset
.save_animate_player_right
    sta .animate_player_right+1
.end_player_directions
    rts

!byte $00

;-----------------------------------------------------------------------------------
.fire_button_pressed
    ldx #player_data_index
fire_bullet_if_ok
    lda data_for_bullets_row,x
    beq .bullet_not_in_motion  ;the player or robot has not fired their bullet already
    rts

.bullet_not_in_motion
    ;ensure bullet also has a direction key press
    lda key_press
    and #%00001111  ;15
    tay
    cmp #%00001111  ;15
    bne .initiate_bullet_fired
    rts

.initiate_bullet_fired
    ;Y is the bullet direction right (1), up (2), down (4), left (8) or diagonal combinations (e.g. up + left)
    lda data_bullet_start_col,y
    clc
    adc data_each_thing_col,x
    sta data_for_bullets_col,x
    lda data_bullet_start_row,y
    clc
    adc data_each_thing_row,x
    sta data_for_bullets_row,x
    jmp .continue_bullet_fired

!byte $00

;-----------------------------------------------------------------------------------
;TODO: plot_player_and_bullets
plot_player_and_bullets

    jsr calc_map_address_for_thing_X
    lda data_each_thing_character,x
    asl
    asl
    asl
    tay
    lda #0
    adc #24
    sta .data_custom_char_high_byte+2

    cpx #player_data_index+8  ;is X a bullet index (player index + 8)?
    bcc .X_index_is_player
    lda #8  ;bullet
    bne *+4  ;skip next instruction
.X_index_is_player
    lda #48  ;player
    sta $69  ;custom char index 8 = bullet, 48 = player
    lda data_each_thing_col+7,x
    sta $6a
    lda data_each_thing_col,x
    and #7
    asl
    asl
    eor #255
    sec
    adc #117
    sta .jmp_to_low_byte+1
    stx $6c
    lda data_each_thing_col+6,x
    tax

    ;blank custom characters from bullet or player (downwards)
    lda #0  ;blank character
.clear_data_custom_char_in_X_loop
    sta data_custom_characters,x
    inx
    dec $69  ;custom char index 8 = bullet, 48 = player
    bne .clear_data_custom_char_in_X_loop

    ldx $6c
    lda data_each_thing_row,x
    and #7
    clc
    adc data_each_thing_col+6,x
    tax
.top_j2_loop
    lda #0
    sta $6b
.data_custom_char_high_byte
    lda data_custom_characters,y  ;self-mod (high byte)
    beq .skip_nextX
.jmp_to_low_byte
    jmp .bit_shift_right_jump_table  ;self-mod (low byte)

    lsr  ;shift character bit to the right (bit 7 becomes 0, carry is previous bit 0)
    nop
    ror $6b  ;shift to the right with bit 7 populated with the carry value from above
.bit_shift_right_jump_table
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
    sta data_custom_characters,x
    cpx #111
    bcs .skip_nextX
    nop
    lda $6b
    sta DATA_CUSTOM_CHAR_UNKNOWN,x
.skip_nextX
    inx
    iny
    dec $6a
    bne .top_j2_loop

    ldx $6c
    ldy #0
    lda #24
    sta $64
    lda data_each_thing_col+6,x
    sta $63
    lda map_address_high
    clc
    adc #screen_colour_map_offset
    sta colour_address_high
    lda map_address_low
    sta colour_address_low
    jsr animate_player_or_bullet
    cpx #player_data_index+8  ;is X a bullet index?
    bcc .X_is_robot_or_player
    rts

.X_is_robot_or_player
    jsr animate_player_or_bullet
    jsr animate_player_or_bullet
    jsr calc_map_address_for_thing_X
    inc map_address_low
    lda map_address_low
    bne *+4  ;skip high byte update line below
    inc map_address_high
    sta colour_address_low
    lda map_address_high
    clc
    adc #screen_colour_map_offset
    sta colour_address_high
    jsr animate_player_or_bullet
    jsr animate_player_or_bullet
    jsr animate_player_or_bullet
    rts

;-----------------------------------------------------------------------------------
play_sound_in_SOUND3
    lda play_sound_duration
    beq .sound_duration_ending
    tax
    lda data_sounds,x
    sta _SOUND3
    dec play_sound_duration
.end_sound_routine
    rts

.sound_duration_ending
    lda _SOUND3
    beq .end_sound_routine
    sec
    sbc #1
    cmp #218
    bne .skip_sound_reset
    lda #0
.skip_sound_reset         
    sta _SOUND3
    rts

;-----------------------------------------------------------------------------------
add_100_to_score_change_level_reset_next_screen_value
    sed  ;set decimal (so e.g. decimal 16 is $10 treated as decimal 10 when adding)
    lda score_hundreds
    clc
    adc #1
    jsr add_to_score_hundreds
    dec game_level  ;game level starts high (easy) and reduces to lowest value 1 (difficult)
    bne .not_on_final_game_level
    inc game_level
.not_on_final_game_level
    lda #0
    rts

;-----------------------------------------------------------------------------------
;TODO: animate_player_or_bullet
animate_player_or_bullet
    ldy #0
    sty $6e
    sty $6f
    lda (map_address_low),y
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
    beq *+4  ;skip high byte update line below
    inc $6f
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
    sta (map_address_low),y
    lda data_each_thing_colour,x
    sta (colour_address_low),y
.skip_nextAN
    lda $63
    clc
    adc #8
    sta $63
    lda map_address_low
    clc
    adc #22
    bcc *+6  ;skip high byte update lines below
    inc map_address_high
    inc colour_address_high
    sta map_address_low
    sta colour_address_low
    lda $6f
    bne .skip_nextAP
    rts

.skip_nextAP
    lda data_each_thing_colour,x
    cmp #yellow  ;the wall, a player or robot turns yellow when hit
    bne .bullet_has_not_hit_anything
.end_bullet_movement
    rts

.bullet_has_not_hit_anything
    lda #247
    sta $00ad  ;location re-used for storage, see MTV page 49
    txa
    cmp #160
    beq .skip_bullet_hits_wall

    ;bullet hits wall
    lda #yellow
    sta data_each_thing_colour,x
    lda #24
    sta data_each_thing_status,x

.skip_bullet_hits_wall
    ldy #0
    lda ($65),y
    cmp #255
    beq .end_bullet_movement

;check if bullet hits a robot
    ldy #96  ;index for start of robot data
.check_bullet_hit_robot_loop
    lda data_each_thing_col,y
    clc
    adc #7
    cmp data_each_thing_col,x
    bcc .missed_robot_continue_to_next_one
    sec
    sbc #8
    cmp data_each_thing_col,x
    bcs .missed_robot_continue_to_next_one
    lda data_each_thing_row,y
    clc
    adc #13
    cmp data_each_thing_row,x
    bcc .missed_robot_continue_to_next_one
    sec
    sbc #14
    cmp data_each_thing_row,x
    bcs .missed_robot_continue_to_next_one
    txa
    sta $69
    cpy $69
    beq .missed_robot_continue_to_next_one

    ;bullet hits robot or player
    lda #yellow
    sta data_each_thing_colour,y
    lda #14
    sta data_each_thing_status,y
    cpx #248  ;index of player bullet
    bne .skip_add_score  ;robot bullet hits another robot, skip add to score
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
add_to_score_hundreds
    sta score_hundreds
    cmp #21  ;is $15 and treated as decimal 15 with decimal mode enabled (with sed)
.skip_add_score
    bne .end_score_update
    inc player_lives  ;increase player lives at score >= 1500
.end_score_update         
    cld  ;clear decimal
    lda #15
    sta play_sound_duration
    rts

!byte $00, $00

.missed_robot_continue_to_next_one
    tya
    clc
    adc #8
    tay
    cpy #player_data_index+8  ;Y is after the player index (start of bullets)
    bne .check_bullet_hit_robot_loop
    rts

.continue_bullet_fired
    lda #red
    sta data_for_bullets_colour,x
    lda key_press
    and #%00001111  ;for bullet direction
    sta data_for_bullets_status,x
    lda play_sound_duration
    bne .end_bullet_fired
    lda #248
    sta _SOUND3
.end_bullet_fired
    lda #14
    sta _VOLUME
    rts

!byte $00

end_code1