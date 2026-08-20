;--------------------------------------------------------------------------------------------------
; Program entry point from the BASIC SYS stub.
;
; The title text is already stored in screen buffer 1. Set the VIC to a 22-column display, initialise
; the option selector, then wait in the title routine for the player to start. The title uses the VIC
; ROM character set; after it returns, switch to the custom character set used by the game.

start_of_program

    lda #_VIC_CR2_SCREEN_BUFFER_1  ;22 columns and display the title at $1c00
    sta _VIC_CR2
    lda #9  ;option 1 is represented internally by the easiest delay value, 9
    sta game_select_level
    ; Original quirk: game_level is not copied here. poll_difficulty_selection sets it when F1 is pressed,
    ; so starting with F7 before cycling the option relies on the existing value at $77.
    nop  ;retained original instruction; no effect on the initialisation

!if USE_8k_MEMORY_LAYOUT = 1 {
    jsr extras_8k  ;set the expanded VIC memory layout before displaying the title
} else {
    ; The unexpanded VIC power-on setting already selects $1c00 and the ROM character set.
    jsr initialise_title_screen_and_wait_for_start
}

    ;----------------------------------------------------------------------------------------------
    ; Select the game display memory after leaving the title screen (MTV page 130):
    ;   bits 7-4 = 1111, combined with _VIC_CR2 bit 7, select $1c00/$1e00 screen memory
    ;   bits 3-0 = 1110 select the custom character set at $1800
    ; With _VIC_CR2 currently $16, buffer 1 at $1c00 is initially displayed and colour RAM is $9400.
    lda #%11111110  ;$fe
    sta _VIC_CR5

start_new_room
    jsr setup_robots_and_player
main_frame_loop
    ; Build the complete next frame in the hidden buffer. This also performs the game-state work
    ; associated with the frame: plotting, input, collision/death handling and robot movement.
    jsr build_next_frame_in_hidden_buffer

    ; draw_screen_high identifies the frame just completed. Expose that buffer only after drawing has
    ; finished, preventing the clear-and-redraw process from being visible. Bit 7 of _VIC_CR2 supplies
    ; screen-address bit 9; the lower seven bits remain 22 for the display width.
    lda draw_screen_high
    cmp #screen_buffer_2_high
    bne .display_screen_buffer_1
    lda #_VIC_CR2_SCREEN_BUFFER_2
    bne .display_completed_buffer  ;always branch: value is nonzero
.display_screen_buffer_1
    lda #_VIC_CR2_SCREEN_BUFFER_1
.display_completed_buffer
    sta _VIC_CR2

    ; These remaining tasks run after the page flip. The final routine either loops for another
    ; frame or enters start_new_room when the player has crossed a room boundary.
    jsr update_soprano_sound
    jsr update_robot_firing
    jmp handle_player_room_exit

!byte $00,$00

;--------------------------------------------------------------------------------------------------
; Construct one complete frame in the currently selected hidden draw buffer.
;
; The screen and its colour RAM are cleared, the room geometry is recreated, and all active objects
; are composited into it. Input and movement then update the object records ready for the following
; frame. The caller changes _VIC_CR2 only after this routine returns, exposing the completed buffer.

draw_screen_and_start_game_action

    ; Clear all 512 bytes in the draw buffer and its corresponding colour-RAM page. The operand high
    ; bytes are patched by build_next_frame_in_hidden_buffer before this routine is called.
    ldx #0
    lda #0  ;blank character and black foreground colour
clear_draw_buffer_loop
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+256,x  ;self-mod (high byte)
    sta _COLOUR_SCREEN_ADDR,x  ;self-mod (high byte)
    sta _COLOUR_SCREEN_ADDR+256,x  ;self-mod (high byte)
    inx
    bne clear_draw_buffer_loop

    ; Fill the complete top and bottom rows with wall characters.
    ; X is already zero after wrapping at the end of the clear loop.
    lda #wall_character  ;block character
draw_horizontal_borders_loop
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+_BOTTOM_SCREEN_ROW,x  ;self-mod (high byte)
    inx
    cpx #_SCREEN_COLUMNS
    bne draw_horizontal_borders_loop

    ; Draw the left and right borders for rows 0-9 and 13-22. Each iteration draws the same row in
    ; both sections; omitting rows 10-12 leaves a three-character-high exit in each side wall.
    ldx #0
draw_vertical_borders_loop
    lda #wall_character  ;block character
    sta _SCREEN_ADDR,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+_RIGHT_SCREEN_COLUMN,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+_LOWER_SIDE_WALLS,x  ;self-mod (high byte)
    sta _SCREEN_ADDR+_LOWER_SIDE_WALLS+_RIGHT_SCREEN_COLUMN,x  ;self-mod (high byte)
    clc
    txa
    adc #_SCREEN_COLUMNS
    tax
    cpx #10*_SCREEN_COLUMNS
    bne draw_vertical_borders_loop

    ; Cut two-character-wide exits into the centre of the top and bottom borders.
    lda #0
clear_horizontal_exits
    sta _SCREEN_ADDR+10  ;self-mod (high byte)
    sta _SCREEN_ADDR+11  ;self-mod (high byte)
    sta _SCREEN_ADDR+_BOTTOM_SCREEN_ROW+10  ;self-mod (high byte)
    sta _SCREEN_ADDR+_BOTTOM_SCREEN_ROW+11  ;self-mod (high byte)

    ; Each room owns eight packed wall bytes selected by next_screen_offset. setup_walls decodes the
    ; high and low nibbles into a screen column and row. The eight entries alternate horizontal and
    ; vertical, including zero entries which omit a wall but still retain the alternation.
    ldx next_screen_offset  ;room offsets $00, $10, $20 or $30
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
    adc #0  ;self-mod: 0 for horizontal or 21 for vertical
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    sta map_address_low
    iny
    cpy #5  ;every inner wall is five characters long
    bne .plot_wall_length_loop

.skip_part_of_wall_draw
    lda .horizontal_or_vertical_offset+1
    beq .skip_to_vertical_wall
    lda #0  ;horizontal wall
    beq .apply_wall_offset  ;always branch
.skip_to_vertical_wall
    ; Indirect Y already advances one byte. Adding another 21 makes the effective vertical stride 22.
    lda #_RIGHT_SCREEN_COLUMN  ;vertical wall
.apply_wall_offset
    sta .horizontal_or_vertical_offset+1
    inx
    txa
    and #%00000111  ;7
    bne .plot_walls_loop

    ; Close the entrance through which the player entered this room. The table contains one high-byte
    ; adjustment followed by three cumulative low-byte deltas for each edge. Side gates occupy three
    ; vertically adjacent cells; top/bottom gates use two cells and repeat the second on the third call.
    ldy #0
    lda entrance_gate_position  ;0=left, 1=top, 2=right, 3=bottom
    asl
    asl
    tax  ;X values are 0,4,8,12
    sty map_address_low
    lda draw_screen_high
    adc data_entrance_gate_high_adjustment,x
    sta map_address_high

    jsr .draw_next_entrance_gate_character
    jsr .draw_next_entrance_gate_character
    jsr .draw_next_entrance_gate_character

    ; Plot the frame using the current object positions, then advance the state for the next frame.
    ; Collision detection occurs while the player and bullet bitmaps are composited. A destroyed object
    ; is removed by update_object_movement_and_destruction when its yellow-state countdown reaches zero.
    jsr handle_robot_player_and_bullets
    jsr get_user_input
    jsr handle_player_death
    jsr update_object_movement_and_destruction
    jsr update_robot_movement_scheduler
    jsr render_score_and_lives
    rts

!byte $00,$00,$00,$00,$00,$00,$00,$00,$00

;--------------------------------------------------------------------------------------------------
.draw_next_entrance_gate_character
    ; X starts at 0, 4, 8 or 12 and advances through the three deltas for the selected edge.
    clc
    lda data_entrance_gate_low_delta,x
    adc map_address_low
    sta map_address_low
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    lda #gate_character
    sta (map_address_low),y
    inx
    rts

;--------------------------------------------------------------------------------------------------
; Shared 256-byte data page ($1100-$11ff in the original layout).
;
; The first 96 bytes hold six room-layout records. Each record contains eight packed wall positions
; followed by eight packed robot positions. Within a packed byte the high nibble is the base column
; and the low nibble is the base row; the entry number (0-7) is added to both when decoded.
;
; The remaining 160 bytes are twenty eight-byte object records. Code uses X/Y as an offset from this
; common page base, allowing the same field aliases to address robots, the player and their bullets.
data_room_layouts
data_room_1 = data_room_layouts
data_each_thing_col
data_each_thing_row = data_each_thing_col+1
data_each_thing_status = data_each_thing_col+2  ;movement direction or destruction countdown
data_each_thing_colour = data_each_thing_col+3
data_each_thing_character = data_each_thing_col+4  ;source bitmap's first character number
data_each_thing_height_chars = data_each_thing_col+5  ;apparent height: 1 or 2; not read by the code
data_each_thing_workspace_offset = data_each_thing_col+6  ;dynamic character-area byte offset
data_each_thing_bitmap_rows = data_each_thing_col+7  ;8 for bullets, 16 for robots/player
    ; Room 1: eight walls, then eight robots
    !byte $1e, $48, $e6, $d6, $56, $63, $00, $00
    !byte $c5, $35, $a9, $4c, $f0, $34, $8a, $cc

data_room_2 = data_room_layouts+16
    ; Room 2
    !byte $88, $77, $00, $00, $49, $73, $00, $00
    !byte $22, $57, $f0, $b3, $b8, $0e, $05, $dd

data_room_3 = data_room_layouts+32
data_room_shuffle_partners = data_room_layouts+room_shuffle_partner_offset
    ; Room 3. This address is also two records beyond data_room_layouts, allowing the shuffle routine
    ; to exchange a jiffy-selected room with the record two positions after it.
    !byte $65, $00, $93, $00, $2d, $00, $5b, $00
    !byte $df, $33, $0f, $a5, $0b, $48, $33, $0d

data_room_4 = data_room_layouts+48
    ; Room 4
    !byte $58, $7a, $9b, $93, $00, $00, $00, $00
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71

data_alternate_room_1 = data_room_layouts+64
    !byte $00, $4a, $00, $26, $00, $c4, $00, $a4
    !byte $21, $75, $77, $3b, $f0, $69, $79, $71

data_alternate_room_2 = data_room_layouts+80
; Biased aliases: adding a shooter object index addresses its bullet record 80 bytes later. No bullet
; record begins here; these sixteen physical bytes are still the second alternate room layout.
data_for_bullets_col
data_for_bullets_row = data_for_bullets_col+1
data_for_bullets_status = data_for_bullets_col+2
data_for_bullets_colour = data_for_bullets_col+3
data_for_bullets_character = data_for_bullets_col+4
    !byte $00, $00, $00, $00, $00, $00, $00, $00
    !byte $df, $33, $0f, $a5, $0c, $48, $33, $0d

; Object record offsets 96-159: the eight active robots.
data_each_robot_col
data_each_robot_row = data_each_robot_col+1
data_each_robot_status = data_each_robot_col+2
data_each_robot_colour = data_each_robot_col+3
data_each_robot_character = data_each_robot_col+4
    !byte $60, $20, $00, red, robot_character_1, $02, $40, $10
    !byte $20, $30, $00, red, robot_character_1, $02, $40, $10
    !byte $60, $58, $00, red, robot_character_1, $02, $40, $10
    !byte $38, $78, $00, red, robot_character_1, $02, $40, $10
    !byte $90, $28, $00, red, robot_character_1, $02, $40, $10
    !byte $38, $48, $00, red, robot_character_1, $02, $40, $10
    !byte $10, $52, $00, red, robot_character_1, $02, $40, $10
    !byte $98, $98, $00, red, robot_character_1, $02, $40, $10

; Offset 160: a ninth, normally inactive robot-shaped record. The object loops include it, and the
; collision routine treats index 160 specially, but no current initialisation path gives it a position.
data_inactive_robot
    !byte $00, $00, $00, red, robot_character_2, $02, $40, $10

; Offset 168: player record.
data_player_hero_col
data_player_hero_row = data_player_hero_col+1
data_player_hero_colour = data_player_hero_col+3
data_player_hero_character = data_player_hero_col+4
    !byte $60, $20, $00, purple, player_character, $02, $10, $10

; Offsets 176-247: one bullet record corresponding to each robot-shaped record above. The ninth bullet
; belongs to the inactive record and is likewise normally unused.
data_robot_bullet
data_robot_bullet_row = data_robot_bullet+1
    !byte $00, $00, $00, red, bullet_character, $01, $70, $08
    !byte $0f, $00, $03, red, bullet_character, $01, $78, $08
    !byte $60, $2d, $00, yellow, bullet_character, $01, $80, $08
    !byte $00, $00, $00, red, bullet_character, $01, $88, $08
    !byte $00, $00, $00, red, bullet_character, $01, $90, $08
    !byte $00, $00, $00, red, bullet_character, $01, $98, $08
    !byte $00, $00, $00, red, bullet_character, $01, $a0, $08
    !byte $00, $00, $00, red, bullet_character, $01, $a8, $08
    !byte $00, $00, $00, red, bullet_character, $01, $b0, $08

; Offset 248: the player's bullet. Adding the player index (168) to data_for_bullets_col reaches here.
data_player_bullet
data_player_bullet_row = data_player_bullet+1
    !byte $00, $00, $00, red, bullet_character, $01, $b8, $08

;--------------------------------------------------------------------------------------------------
; Decode packed wall entry X into a screen address.
;
; X points to one of the eight wall bytes in the selected room and its low three bits are therefore
; the wall number, 0-7. Add that number to both packed nibbles:
;   column = high nibble + wall number
;   row    = low nibble  + wall number
; Return map_address pointing into the current draw buffer and Y=0, ready for the wall-drawing loop.
setup_walls
    txa
    clc
    and #room_wall_count-1
    sta wall_position_adjustment
    lda data_each_thing_col,x
    and #%00001111  ;packed row base
    adc wall_position_adjustment
    tay

    lda data_each_thing_col,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc wall_position_adjustment  ;packed column base + wall number
    jsr calculate_screen_address_from_character_position
    rts

;--------------------------------------------------------------------------------------------------
; Initialise the eight robots and player on entering a room.
;
; The second half of each 16-byte room layout contains eight packed robot positions. They use the
; same nibble-plus-entry encoding as walls, but the decoded character coordinates are multiplied by
; eight to become pixel coordinates for smooth movement. Robot state and bullet activity are reset,
; all robots receive the colour/value of the current floor, and the player is placed just inside the
; edge opposite the exit used in the previous room.
setup_robots_and_player
    ldy #0
    lda next_screen_offset  ;selected room layout: $00, $10, $20 or $30
    clc
    adc #room_wall_count  ;skip the eight wall bytes to the robot-position bytes
    tax
.initialise_next_robot
    txa
    and #active_robot_count-1  ;robot number 0-7
    sta robot_position_adjustment
    lda data_each_thing_col,x
    lsr
    lsr
    lsr
    lsr
    clc
    adc robot_position_adjustment  ;packed column base + robot number
    asl
    asl
    asl  ;character column to pixel X
    sta data_each_robot_col,y
    lda data_each_thing_col,x
    and #%00001111  ;15
    clc
    adc robot_position_adjustment  ;packed row base + robot number
    asl
    asl
    asl  ;character row to pixel Y
    sta data_each_robot_row,y

    ; A row of zero marks a bullet inactive. The player-bullet reset is invariant but is compactly
    ; repeated inside this loop in the original code.
    lda #0
    sta data_player_bullet_row
    sta data_each_robot_status,y  ;stationary until the movement scheduler assigns a direction
    sta data_robot_bullet_row,y  ;this robot's corresponding bullet is inactive

    ; Convert room offsets $00/$10/$20/$30 into colour-table indices 0-3. The operand of the absolute
    ; LDA below is self-modified; data_robot_colours is page-aligned, so changing only its low byte is
    ; sufficient. This assignment is also invariant but repeated for each robot by the original loop.
    lda next_screen_offset
    lsr
    lsr
    lsr
    lsr
    sta .robot_colour+1  ;green, cyan, red or black
.robot_colour
    lda data_robot_colours  ;self-modified low address byte
    sta data_each_robot_colour,y
    inx
    ; The fourth LSR above shifted original bit 3 into carry. Valid room offsets have a zero low
    ; nibble, so carry is known clear for this ADC without a separate CLC.
    tya
    adc #object_record_size
    tay  ;next eight-byte runtime robot record
    cmp #active_robot_count*object_record_size
    bne .initialise_next_robot

    ; Spawn just inside the entrance: left, top, right or bottom. These are pixel coordinates and are
    ; deliberately offset from exact character boundaries.
    ldx entrance_gate_position  ;0=left, 1=top, 2=right, 3=bottom
    lda data_player_entrance_col,x
    sta data_player_hero_col
    lda data_player_entrance_row,x
    sta data_player_hero_row
    jsr run_room_transition_pause
    rts

!byte $00, $00, $00, $00

;--------------------------------------------------------------------------------------------------
; Render every active runtime object into the current draw buffer.
;
; X visits all twenty eight-byte records from the first robot at offset 96 through the player bullet
; at offset 248. Adding eight after the final record wraps X to zero and ends the loop. A row value of
; zero marks any object inactive.
;
; Character-aligned robots use a fast path which writes their existing head and tail characters
; directly. The player, every bullet, and robots between character boundaries use the software-sprite
; compositor, which shifts their bitmap into dynamic characters and performs pixel collision checks.
handle_robot_player_and_bullets

    ldx #robot_data_index
.object_loop
    lda data_each_thing_row,x
    beq .advance_to_next_object
    cpx #player_data_index
    bcs .render_as_software_sprite  ;player and all bullets
    and #pixel_subposition_mask
    bne .render_as_software_sprite  ;robot is vertically between character cells

    ; The robot is vertically aligned. Convert its pixel Y coordinate to a character row.
    lda data_each_thing_row,x
    lsr
    lsr
    lsr
    tay  ;Y input for calculate map address (row)

    lda data_each_thing_col,x
    and #pixel_subposition_mask
    bne .render_as_software_sprite  ;robot is horizontally between character cells
    lda data_each_thing_col,x
    lsr
    lsr
    lsr  ;A at this point is ready to calculate map address (col)
    jsr calculate_screen_address_from_character_position

    ; Fast aligned-robot path: the source head and tail characters can be placed directly without
    ; constructing shifted dynamic characters. The tail character immediately follows the head.
    lda data_each_thing_character,x
    sta (map_address_low),y
    ldy #_SCREEN_COLUMNS  ;row below
    clc
    adc #1  ;is tail character (+1 from head)
    sta (map_address_low),y

    ; Derive the colour-RAM pointer from the draw-screen pointer and colour both character cells.
    lda map_address_low
    sta colour_map_address_low  ;colour map low
    lda map_address_high
    clc
    adc #_SCREEN_TO_COLOUR_HIGH_OFFSET
    sta colour_map_address_high  ;colour map high
    lda data_each_thing_colour,x
    ldy #0
    sta (colour_map_address_low),y
    ldy #_SCREEN_COLUMNS  ;row below
    sta (colour_map_address_low),y

.advance_to_next_object
    txa
    clc
    adc #object_record_size
    tax
    bne .object_loop  ;offset 248 + 8 wraps to zero after all twenty records
    rts

.render_as_software_sprite
    jsr plot_software_sprite
    jmp .advance_to_next_object

;--------------------------------------------------------------------------------------------------
; Poll keyboard or joystick and apply player movement/animation.
;
; Input is sampled once every three frames and normalised to the active-low low five bits of
; input_bits: fire, left, down, up, right. $1f means idle. Keyboard takes priority whenever the
; KERNAL reports a key; otherwise the joystick is read directly from its two VIA ports.
;
; Original quirk: input_poll_delay is not initialised at game start, so the first poll depends on its
; existing zero-page value. Every poll after that reloads it with three.
get_user_input
    dec input_poll_delay
    beq .poll_input
    rts
.poll_input
    lda #input_poll_interval
    sta input_poll_delay
    lda _CURRENT_KEY_CODE  ;matrix coordinate of current key pressed, 64 if none
    cmp #64
    beq .read_joystick

    ; Translate U/H/J/N into the same active-low bits produced by the joystick. The comparisons are
    ; deliberately chained: when one matches, A becomes its input mask and cannot match a later key.
    cmp #28  ;keyboard N key
    bne *+4  ;skip next instruction
    lda #input_idle-input_down  ;down
    cmp #51  ;keyboard U key
    bne *+4  ;skip next instruction
    lda #input_idle-input_up  ;up
    cmp #20  ;keyboard J key
    bne *+4  ;skip next instruction
    lda #input_idle-input_right  ;right
    cmp #43  ;keyboard H key
    bne *+4  ;skip next instruction
    lda #input_idle-input_left  ;left
    ; Other keys retain their raw matrix code, whose low bits may consequently resemble movement.
    ldy _KEYBOARD_MODIFIER_FLAGS  ;Keyboard shift / control flag
    beq .keyboard_mask_ready
    and #input_directions  ;a modifier clears active-low fire while retaining the direction
.keyboard_mask_ready
    jmp .process_input

.read_joystick
    ; Joystick right is connected to VIA2 PB7, shared with the keyboard matrix. Temporarily make port B
    ; an input, capture PB7 in input_bits bit 0, then restore the keyboard port to outputs.
    lda #0
    sta _VIA_DATADIR_B
    lda _VIA_KEYB_ROWS
    asl  ;bit 7 into carry, 0 into bit 0
    rol input_bits  ;carry into bit 0, bit 7 into carry
    lda #255
    sta _VIA_DATADIR_B

    ; VIA1 supplies fire/left/down/up. Shift those four bits into positions 4-1 and rotate the saved
    ; right value into bit 0, producing the common active-low input mask.
    lda _VIA_JOYSTICK
    and #%00111100  ;60
    clc
    lsr  ;together lose bits 0,1
    lsr  ;together lose bits 0,1
    lsr input_bits  ;saved right bit into carry
    rol  ;carry into A bit 0
.process_input
    tay  ;preserve the new input mask while checking player state
    ldx #player_data_index
    lda data_each_thing_col,x
    beq .set_standing_frame  ;player is inactive/dead
    lda data_each_thing_colour,x
    cmp #yellow
    beq .set_standing_frame  ;player is in the hit countdown
    tya
    eor #input_idle
    beq .set_standing_frame
    jmp .apply_active_input

.set_standing_frame
    ldy #player_standing_offset
copy_player_animation_frame
    ldx #0
.copy_frame_loop
    lda data_player_animation,y
    sta data_player_custom_characters,x
    iny
    inx
    ; Copy the frame's twelve bitmap rows plus the guaranteed-zero first byte of the following frame.
    ; This clears destination byte 12; bytes 13-15 are permanently blank and need not be rewritten.
    cpx #player_animation_frame_size+1
    bne .copy_frame_loop
    rts

;--------------------------------------------------------------------------------------------------
.apply_active_input
    tya
    sta input_bits
    and #input_fire
    bne .check_down_direction
    ; Fire takes priority: the direction bits aim the bullet but do not move the player on this poll.
    jmp .player_fire_pressed

    ; All direction tests are independent, allowing diagonals. Opposite directions cancel their
    ; coordinate changes; because down/up and left/right are processed in that order, the later
    ; direction supplies the final animation frame. Each LDY operand below is self-modified after use
    ; to alternate between the two twelve-byte frames for that direction.
.check_down_direction
    lda input_bits
    and #input_down
    bne .check_up_direction
    inc data_each_thing_row,x
.animate_player_down
    ldy #player_animate_up_down_offset
    jsr copy_player_animation_frame
    ldx #player_data_index
    lda .animate_player_down+1
    cmp #player_animate_up_down_offset
    bne .switch_animate_player_down
    lda #player_animate_up_down_offset+player_animation_frame_size
    bne .save_animate_player_down  ;always branch
.switch_animate_player_down
    lda #player_animate_up_down_offset
.save_animate_player_down
    sta .animate_player_down+1

.check_up_direction
    lda input_bits
    and #input_up
    bne .check_left_direction
    dec data_each_thing_row,x
.animate_player_up
    ldy #player_animate_up_down_offset
    jsr copy_player_animation_frame
    ldx #player_data_index
    lda .animate_player_up+1
    cmp #player_animate_up_down_offset
    bne .switch_animate_player_up
    lda #player_animate_up_down_offset+player_animation_frame_size
    bne .save_animate_player_up
.switch_animate_player_up
    lda #player_animate_up_down_offset
.save_animate_player_up
    sta .animate_player_up+1

.check_left_direction
    lda input_bits
    and #input_left
    bne .check_right_direction
    dec data_each_thing_col,x
.animate_player_left
    ldy #player_animate_left_offset
    jsr copy_player_animation_frame
    ldx #player_data_index
    lda .animate_player_left+1
    cmp #player_animate_left_offset
    bne .switch_animate_player_left
    lda #player_animate_left_offset+player_animation_frame_size
    bne .save_animate_player_left
.switch_animate_player_left
    lda #player_animate_left_offset
.save_animate_player_left
    sta .animate_player_left+1

.check_right_direction
    lda input_bits
    and #input_right
    bne .end_player_directions
    inc data_each_thing_col,x
.animate_player_right
    ldy #player_animate_right_offset
    jsr copy_player_animation_frame
    ldx #player_data_index
    lda .animate_player_right+1
    cmp #player_animate_right_offset
    bne .switch_animate_player_right
    lda #player_animate_right_offset+player_animation_frame_size
    bne .save_animate_player_right
.switch_animate_player_right
    lda #player_animate_right_offset
.save_animate_player_right
    sta .animate_player_right+1
.end_player_directions
    rts

!byte $00

;--------------------------------------------------------------------------------------------------
; Player adapter for the shared firing routine. Robot callers arrive directly at fire_bullet_if_ok
; with X already pointing to their robot record; player input must first supply the player index.
.player_fire_pressed
    ldx #player_data_index

; Attempt to activate the bullet belonging to shooter X.
;
; data_for_bullets_* is deliberately based 80 bytes above the common object page, so adding the
; shooter's object index reaches its corresponding bullet record. A nonzero bullet row means that
; shooter already has a shot in flight. input_bits/robot_direction ($69) supplies the active-low
; direction mask used by both player and robot callers.
fire_bullet_if_ok
    lda data_for_bullets_row,x
    beq .bullet_available
    rts

.bullet_available
    ; Firing requires at least one direction. $0f means all four active-low direction bits are idle.
    lda input_bits
    and #input_directions
    tay
    cmp #input_directions
    bne .set_bullet_position
    rts

.set_bullet_position
    ; Y is the active-low direction-table index: right=$e, up=$d, down=$b, left=$7; diagonal values
    ; are $3, $5, $a and $c. Add the direction-specific muzzle offset to the shooter's pixel position.
    lda data_bullet_spawn_col_offset,y
    clc
    adc data_each_thing_col,x
    sta data_for_bullets_col,x
    lda data_bullet_spawn_row_offset,y
    clc
    adc data_each_thing_row,x
    sta data_for_bullets_row,x
    ; The original completion code is stored near the end of code1, after the compositor/collision
    ; routines, so this is a jump rather than local fall-through.
    jmp .finish_bullet_initialisation

!byte $00

;--------------------------------------------------------------------------------------------------
; Build and plot a pixel-positioned software sprite for object X.
;
; The object's source bitmap begins at character_number*8 in the custom set. Its pixel coordinates
; select a screen cell plus horizontal/vertical offsets within that cell. The bitmap is shifted into
; a private dynamic-character workspace:
;   - robots/player: six characters arranged as two columns by three rows (48 bytes)
;   - bullets:       one character (8 bytes); their single set pixel never overflows horizontally
;
; Once constructed, each required cell is merged into the draw buffer by composite_software_sprite_cell,
; which also performs pixel collision detection. Robots use this path only while between character
; boundaries; aligned robots take the direct-character fast path in handle_robot_player_and_bullets.
plot_software_sprite

    ; Convert the object's pixel position to the address of its top-left screen cell.
    jsr calculate_object_screen_address

    ; Form the source bitmap address. Y holds the low-byte offset (character number * 8); carry from
    ; the final ASL selects $18xx or $19xx and is consumed by ADC below. Patch only the high byte of
    ; the absolute source load used by the row loop.
    lda data_each_thing_character,x
    asl
    asl
    asl
    tay
    lda #0
    adc #custom_character_memory_high
    sta .load_source_bitmap_row+2

    ; Robot/player workspaces need all six cells cleared. Bullet object indices begin at 176 and each
    ; owns one eight-byte character workspace.
    cpx #robot_bullet_data_index
    bcc .full_size_sprite
    lda #bullet_workspace_size
    bne *+4  ;skip next instruction
.full_size_sprite
    lda #software_sprite_workspace_size
    sta custom_char_clear_count
    lda data_each_thing_bitmap_rows,x
    sta bitmap_rows_remaining

    ; Select an entry in the seven repeated LSR/NOP/ROR groups below. For horizontal pixel offset P,
    ; complementing 4*P and adding the store label with carry set yields store_label-(4*P): P=0 jumps
    ; directly to the store, while P=7 enters before all seven shifts.
    lda data_each_thing_col,x
    and #pixel_subposition_mask
    asl
    asl
    eor #255
    sec
    adc #<.store_shifted_row
    sta .horizontal_shift_entry+1
    stx saved_object_index
    lda data_each_thing_workspace_offset,x
    tax

    ; Clear the object's previous dynamic characters before reconstructing the bitmap.
    lda #0  ;blank character
.clear_workspace_loop
    sta data_custom_characters,x
    inx
    dec custom_char_clear_count
    bne .clear_workspace_loop

    ; Begin at vertical row offset Y&7 within the left workspace column. Consecutive source rows then
    ; flow naturally through the three vertically stacked character bitmaps.
    ldx saved_object_index
    lda data_each_thing_row,x
    and #pixel_subposition_mask
    clc
    adc data_each_thing_workspace_offset,x
    tax
.build_bitmap_row_loop
    lda #0
    sta shifted_bitmap_overflow
.load_source_bitmap_row
    lda data_custom_characters,y  ;self-mod (high byte)
    beq .advance_bitmap_row  ;workspace was cleared, so blank source rows need no store
.horizontal_shift_entry
    jmp .bit_shift_right_jump_table  ;self-mod (low byte)

    lsr  ;shift character bit to the right (bit 7 becomes 0, carry is previous bit 0)
    nop
    ror shifted_bitmap_overflow  ;shift right, carrying overflow into the adjacent character
.bit_shift_right_jump_table
    lsr
    nop
    ror shifted_bitmap_overflow
    lsr
    nop
    ror shifted_bitmap_overflow
    lsr
    nop
    ror shifted_bitmap_overflow
    lsr
    nop
    ror shifted_bitmap_overflow
    lsr
    nop
    ror shifted_bitmap_overflow
    lsr
    nop
    ror shifted_bitmap_overflow
.store_shifted_row
    sta data_custom_characters,x
    ; Full-size sprites store bits shifted through the right edge in the matching right-column row.
    ; Bullet workspaces start at $70 and never require this store; $6f is the original threshold.
    cpx #first_bullet_workspace_offset-1
    bcs .advance_bitmap_row
    nop
    lda shifted_bitmap_overflow
    sta data_custom_characters_right_column,x
.advance_bitmap_row
    inx
    iny
    dec bitmap_rows_remaining
    bne .build_bitmap_row_loop

    ; Point to the first generated character and its top-left screen colour cell.
    ldx saved_object_index
    ldy #0
    lda #custom_character_memory_high
    sta custom_char_address_high
    lda data_each_thing_workspace_offset,x
    sta custom_char_address_low
    lda map_address_high
    clc
    adc #_SCREEN_TO_COLOUR_HIGH_OFFSET
    sta screen_colour_address_high
    lda map_address_low
    sta screen_colour_address_low

    ; A bullet occupies one generated screen character. Full-size sprites occupy three cells down the
    ; left column followed by three cells down the right column. composite_software_sprite_cell advances the
    ; custom-character and screen/colour pointers to the next row after every call.
    jsr composite_software_sprite_cell
    cpx #robot_bullet_data_index
    bcc .plot_remaining_full_size_cells
    rts

.plot_remaining_full_size_cells
    jsr composite_software_sprite_cell
    jsr composite_software_sprite_cell
    jsr calculate_object_screen_address
    inc map_address_low
    lda map_address_low
    bne *+4  ;skip high byte update line below
    inc map_address_high
    sta screen_colour_address_low
    lda map_address_high
    clc
    adc #_SCREEN_TO_COLOUR_HIGH_OFFSET
    sta screen_colour_address_high
    jsr composite_software_sprite_cell
    jsr composite_software_sprite_cell
    jsr composite_software_sprite_cell
    rts

;--------------------------------------------------------------------------------------------------
; Update VIC sound voice 3 once per frame.
;
; There are two sound modes selected by timed_sound_countdown:
;   nonzero - play the table-driven hit effect, using the countdown directly as an index
;   zero    - decay any bullet tone already present in the VIC register, or return if silent
;
; A hit sets the countdown to 15, so the table is read backwards from index 15 through index 1.
; Index 1 is zero and explicitly silences the voice on the final timed frame.
update_soprano_sound
    lda timed_sound_countdown
    beq .update_untimed_bullet_tone
    tax
    lda data_hit_sound_frequencies,x
    sta _VIC_SOUND_SOPRANO
    dec timed_sound_countdown
.sound_update_complete
    rts

.update_untimed_bullet_tone
    ; Firing writes $f8 directly to the voice without starting the timed countdown. Decrement that
    ; frequency once per frame; when the result reaches $da, replace it with zero rather than storing
    ; $da. Thus the generated decay runs from $f8 down through $db before becoming silent.
    lda _VIC_SOUND_SOPRANO
    beq .sound_update_complete
    sec
    sbc #1
    cmp #bullet_sound_stop_frequency
    bne .store_decayed_frequency
    lda #0
.store_decayed_frequency
    sta _VIC_SOUND_SOPRANO
    rts

;--------------------------------------------------------------------------------------------------
; Complete a cycle after the player leaves its fourth room.
;
; Award the 100-point completion bonus, make subsequent robots faster, and return A=0 for the
; caller to wrap next_screen_offset to the first room. The score helper also checks for the
; 1500-point extra life and starts the hit/bonus sound before returning here.
complete_four_floor_cycle
    sed  ;score_hundreds is a packed BCD thousands/hundreds pair
    lda score_hundreds
    clc
    adc #floor_cycle_bonus_hundreds
    jsr store_score_high_and_finish_score_update

    ; game_level is a movement delay: decrementing it increases the difficulty. Clamp it at one
    ; so the robots never advance more often than once per eligible update.
    dec game_level
    bne .difficulty_updated
    inc game_level  ;restore the minimum delay of one after DEC reached zero
.difficulty_updated
    lda #0  ;next_screen_offset for the first room of the new cycle
    rts

;--------------------------------------------------------------------------------------------------
; Composite one generated software-sprite character into its screen cell and detect pixel overlap.
;
; Entry:
;   X                         object-record index (robot, player or bullet)
;   map_address               screen cell to update
;   screen_colour_address     corresponding colour-RAM cell
;   custom_char_address       generated eight-byte character for this cell
;
; If the screen cell is occupied, its character number is converted back to an $18xx/$19xx bitmap
; address. Each generated row is ORed with that existing bitmap so room geometry and objects drawn
; earlier in the frame remain visible. A collision is a row containing at least one set bit in both
; bitmaps at the same pixel position—not merely two objects sharing a character cell.
;
; A generated cell containing no sprite pixels is left unchanged. Otherwise the screen is pointed at
; the generated character and coloured for object X. Before returning, all three pointers advance one
; character row, allowing the caller to invoke this routine repeatedly down a sprite column.
composite_software_sprite_cell
    ldy #0
    sty nonzero_sprite_row_count
    sty collision_row_count
    lda (map_address_low),y
    beq .install_generated_character  ;blank screen character needs no bitmap merge

    ; Convert the existing screen-code character into its bitmap address. The third ASL's carry
    ; selects the second custom-character page when the character number is 32 or greater.
    asl
    asl
    asl
    sta source_char_address_low
    lda #0
    adc custom_char_address_high
    sta source_char_address_high

.merge_bitmap_row_loop
    lda (custom_char_address_low),y
    beq .merge_existing_row  ;blank generated row cannot collide
    inc nonzero_sprite_row_count
    and (source_char_address_low),y
    beq *+4  ;skip high byte update line below
    inc collision_row_count
    lda (custom_char_address_low),y
.merge_existing_row
    ora (source_char_address_low),y
    sta (custom_char_address_low),y
    iny
    cpy #character_bitmap_size
    bne .merge_bitmap_row_loop

    ldy #0
    lda nonzero_sprite_row_count
    beq .advance_to_next_cell  ;this part of the shifted sprite contains no pixels
.install_generated_character
    lda custom_char_address_low
    lsr
    lsr
    lsr
    sta (map_address_low),y
    lda data_each_thing_colour,x
    sta (screen_colour_address_low),y
.advance_to_next_cell
    lda custom_char_address_low
    clc
    adc #character_bitmap_size
    sta custom_char_address_low
    lda map_address_low
    clc
    adc #_SCREEN_COLUMNS
    bcc *+6  ;skip high byte update lines below
    inc map_address_high
    inc screen_colour_address_high
    sta map_address_low
    sta screen_colour_address_low
    lda collision_row_count
    bne .object_pixels_overlapped
    rts

.object_pixels_overlapped
    ; Yellow denotes an object already in its destruction countdown. Do not restart that countdown
    ; when another overlap is detected on a later frame.
    lda data_each_thing_colour,x
    cmp #yellow
    bne .process_new_collision
.end_collision_processing
    rts

.process_new_collision
    ; This marker is written for every new collision but is not read anywhere in the game. $ad is a
    ; reused KERNAL zero-page location, so this appears to be a remnant or external status marker.
    lda #collision_scratch_value
    sta collision_scratch_marker
    txa
    cmp #inactive_robot_data_index
    beq .skip_current_object_hit_state

    ; Mark the currently plotted object as hit. This path is used by robots and the player as well as
    ; bullets; the movement update removes it after the countdown expires.
    lda #yellow
    sta data_each_thing_colour,x
    lda #colliding_object_countdown
    sta data_each_thing_status,x

.skip_current_object_hit_state
    ; A solid wall character begins with an all-set bitmap row. In that case the current object has
    ; already been marked and there is no object target to locate.
    ldy #0
    lda (source_char_address_low),y
    cmp #solid_wall_bitmap_row
    beq .end_collision_processing

    ; Identify the previously drawn robot/player by testing the current object's pixel coordinate
    ; against each target's 8-by-14 bounding box. The current record itself is excluded.
    ldy #robot_data_index
.find_collided_object_loop
    lda data_each_thing_col,y
    clc
    adc #7
    cmp data_each_thing_col,x
    bcc .try_next_collision_target
    sec
    sbc #8
    cmp data_each_thing_col,x
    bcs .try_next_collision_target
    lda data_each_thing_row,y
    clc
    adc #13
    cmp data_each_thing_row,x
    bcc .try_next_collision_target
    sec
    sbc #14
    cmp data_each_thing_row,x
    bcs .try_next_collision_target
    txa
    sta current_object_index
    cpy current_object_index
    beq .try_next_collision_target

    ; The previously drawn target uses a shorter hit countdown than the currently plotted object.
    lda #yellow
    sta data_each_thing_colour,y
    lda #hit_target_countdown
    sta data_each_thing_status,y
    cpx #player_bullet_data_index
    bne .skip_add_score  ;only the player's bullet earns points
    ldy #0

    ; Add the destroyed robot's value using packed-BCD arithmetic.
    sed
    clc
    lda next_screen_offset  ;$00/$10/$20/$30 contributes 0/10/20/30 points in packed BCD
    adc #5  ;base robot value: 5, 15, 25 or 35 points according to the room
    adc score_tens
    sta score_tens
    bcc .end_score_update
    lda #0
    adc score_hundreds
; Shared score-update tail. Entry: A is the new packed-BCD score high pair and decimal mode is set.
; It stores A, awards the single extra life at exactly 1500 points, restores binary arithmetic,
; and starts the sound used for both a robot hit and the four-floor completion bonus.
store_score_high_and_finish_score_update
    sta score_hundreds
    cmp #extra_life_score_high_bcd
.skip_add_score
    bne .end_score_update
    inc player_lives  ;award the extra life when the score reaches exactly 1500
.end_score_update         
    cld  ;restore binary arithmetic
    lda #hit_sound_duration
    sta timed_sound_countdown
    rts

!byte $00, $00

.try_next_collision_target
    tya
    clc
    adc #object_record_size
    tay
    cpy #player_data_index+8  ;Y is after the player index (start of bullets)
    bne .find_collided_object_loop
    rts

.finish_bullet_initialisation
    ; Every new bullet is red. Its status retains the direction-table index used by
    ; update_object_movement_and_destruction to obtain the per-frame X/Y movement deltas.
    lda #red
    sta data_for_bullets_colour,x
    lda input_bits
    and #input_directions
    sta data_for_bullets_status,x

    ; Do not interrupt the timed robot-hit sound. Otherwise begin the bullet tone; the normal sound
    ; update subsequently decays this frequency. Volume is raised for either case.
    lda timed_sound_countdown
    bne .end_bullet_fired
    lda #bullet_sound_frequency
    sta _VIC_SOUND_SOPRANO
.end_bullet_fired
    lda #game_audio_volume
    sta _VIC_VOLUME_AUX_COLOUR
    rts

!byte $00

end_code1
