;-----------------------------------------------------------------------------------
; Render the four-digit packed-BCD score and remaining lives in the hidden buffer's top row.
;
; The score bytes hold thousands/hundreds and tens/units respectively. Each nibble is multiplied by
; eight to index its reversed-video digit bitmap in the VIC character ROM. For example, score bytes
; $12 and $34 produce the displayed digits 1, 2, 3 and 4. Only the five digit glyphs
; needed for the current frame are copied into RAM: characters 32-35 for the score and character 37
; for lives; character 36 is a fixed `#` marker. Reusing these six slots instead of storing all ten
; digits plus the marker saves 40 bytes of custom-character data.
;
; These six slots occupy $1900-$192f, immediately before code3 at $1930 in the original layout. Both
; screen buffers share this character RAM, so glyph copying can update digit shapes referenced by the
; visible buffer before the page flip; double buffering protects screen codes/colours, not bitmaps.
; Colour RAM is not written here: the frame clear has already left these top-row cells black.
;
; The screen store is self-modified: its high operand selects draw_screen_high, while the low operand
; starts at column 1 for the score and is changed to column 19 for `#` and the lives digit. The helper
; increments both the screen column and destination character number after each plot.
render_score_and_lives
    ldy #0  ;destination bitmap offset for score character 32
    lda draw_screen_high
    sta .plot_score_display_character+2
    lda #first_score_character
    sta next_score_display_character
    lda #first_score_screen_column
    sta .plot_score_display_character+1

    ; Thousands digit: masking the high nibble then shifting once produces digit*8 directly.
    lda score_hundreds
    and #packed_bcd_high_nibble_mask
    lsr
    tax
    jsr copy_rom_digit_to_custom_character_and_plot

    ; Hundreds digit.
    lda score_hundreds
    and #packed_bcd_low_nibble_mask
    asl
    asl
    asl
    tax
    jsr copy_rom_digit_to_custom_character_and_plot

    ; Tens digit.
    lda score_tens
    and #packed_bcd_high_nibble_mask
    lsr
    tax
    jsr copy_rom_digit_to_custom_character_and_plot

    ; Units digit.
    lda score_tens
    and #packed_bcd_low_nibble_mask
    asl
    asl
    asl
    tax
    jsr copy_rom_digit_to_custom_character_and_plot

    ; Plot the fixed marker, then redefine and plot character 37 as the current lives digit.
    lda #lives_marker_screen_column
    sta .plot_score_display_character+1
    lda #lives_marker_character
    sta next_score_display_character
    jsr .plot_score_display_character
    lda player_lives
    asl
    asl
    asl
    tax

    ldy #lives_digit_custom_bitmap_offset

; Copy one reversed-video ROM digit into the selected custom-character slot and plot that character.
;
; Entry: X = digit*8 source offset, Y = destination offset from data_score_custom_characters.
; Exit:  X and Y advanced by eight; next_score_display_character and the screen column incremented.
copy_rom_digit_to_custom_character_and_plot
    lda #character_bitmap_size
    sta custom_char_bytes_remaining
.copy_digit_bitmap_loop
    lda _VIC_CASEURV+rom_digit_zero_bitmap_offset,x
    sta data_score_custom_characters,y
    inx
    iny
    dec custom_char_bytes_remaining
    bne .copy_digit_bitmap_loop

    lda next_score_display_character
.plot_score_display_character
    sta _SCREEN_ADDR+513  ;self-modified to selected screen base plus score-display column
    inc next_score_display_character
    inc .plot_score_display_character+1
    rts

;-----------------------------------------------------------------------------------
; Reset per-room presentation/timers and pause briefly before gameplay resumes.
;
; The player colour is restored after any yellow destruction state. Robot firing and movement receive
; their long 112-frame initial delays. The same numeric value is written to VIC voice 3 and the noise
; voice; its enable bit (bit 7) is clear, so both voices are disabled. The noise register remains at
; this disabled value, while update_soprano_sound later counts voice 3 down silently to zero.
;
; The VIC background/border register is changed to the transition value during a busy wait and then
; restored to the normal game value. The wait compares the wrapping low jiffy byte with a precomputed
; target, so crossing $ff is handled naturally.
;
; Original carry quirk: setup_robots_and_player is the only caller. Its final CMP against 64 leaves
; carry set, and the player-position loads/stores do not alter it. ADC #24 therefore calculates
; current_jiffy+25. Despite the old label/comment, the actual pause is exactly 25 jiffy ticks.
run_room_transition_pause
    lda #purple
    sta data_player_hero_colour
    lda #room_initial_delay_and_sound_off
    sta robot_fire_delay
    sta robot_speed
    sta _VIC_SOUND_SOPRANO
    sta _VIC_SOUND_NOISE
    lda #room_transition_colour
    sta _VIC_BG_BORDER_COL
    lda one_jiffy
    adc #room_transition_jiffy_addend  ;carry is set: effective addition is 25
.wait_for_room_transition_target
    cmp one_jiffy
    bne .wait_for_room_transition_target
    lda #normal_game_colour
    sta _VIC_BG_BORDER_COL
    rts

;-----------------------------------------------------------------------------------
; Convert a character column and row into an address in the current hidden draw buffer.
;
; Entry: A = character column (0-21), Y = character row (0-22).
; Exit:  map_address = draw-buffer base + row*22 + column; Y=0. X is preserved.
;
; data_row_times_11 stores row*11 in one byte. Doubling an entry gives row*22: the ASL result is the
; low byte and carry is its high bit. The first table load is therefore not redundant even though A
; is overwritten—the ASL's carry is consumed by ADC #0 to select the first or second screen page.
; The table is loaded and doubled again to recover the low byte, then adding the column may contribute
; one further carry into map_address_high.
calculate_screen_address_from_character_position
    sta screen_character_column
    lda data_row_times_11,y
    asl  ;carry = high byte of row*22
    lda draw_screen_high
    adc #0  ;add row offset's page bit
    sta map_address_high
    lda data_row_times_11,y
    asl  ;low byte of row*22: 0, 22, 44, 66, ...
    clc
    adc screen_character_column
    bcc *+4  ;skip high byte update line below
    inc map_address_high
    sta map_address_low
    ldy #0
    rts

;-----------------------------------------------------------------------------------
; Convert object X's pixel coordinates to the address of its top-left character cell.
;
; Dividing each coordinate by eight discards its within-cell pixel offset. The software-sprite builder
; handles those remaining low three bits separately when shifting the bitmap.
calculate_object_screen_address
    lda data_each_thing_row,x
    lsr
    lsr
    lsr
    tay  ;character row

    lda data_each_thing_col,x
    lsr
    lsr
    lsr  ;character column
    jsr calculate_screen_address_from_character_position
    rts

;-----------------------------------------------------------------------------------
; Half-width row-offset table for all 24 addressable rows. Doubling an entry produces row*22 while
; exposing the ninth bit through carry. Row 23 is included for calculations immediately below the
; 23-row visible area. This table begins at page offset $e8, so its 24 bytes end exactly on the next
; page boundary required by the aliased colour/animation data below.
data_row_times_11
    !byte 0, 11, 22, 33, 44, 55, 66, 77
    !byte 88, 99, 110, 121, 132, 143, 154, 165
    !byte 176, 187, 198, 209, 220, 231, 242, 253

data_player_animation
data_robot_colours
    ; Room offsets $00/$10/$20/$30 select entries 0-3: green, cyan, red and black. The remaining
    ; twelve zero bytes pad this prefix to 16 bytes and form animation offsets 0-15, which are unused.
    !byte green, cyan, red, black, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00, $00, $00, $00

; Timed hit effect, indexed by a countdown from 15 to 1 (therefore played in reverse declaration
; order). Entries 0 and 1 are both silent; index 0 is never read by the timed path.
data_hit_sound_frequencies
    !byte $00, $00, $e8, $ec, $f0, $f2, $f5, $f7
    !byte $f8, $f9, $f9, $f8, $f5, $f3, $f0, $ec

; The animation base deliberately aliases data_robot_colours. Colour and sound data occupy offsets
; 0-31, so seven twelve-byte player frames begin at offset 32. copy_player_animation_frame copies a
; thirteenth byte to clear the first unused row; this is the zero first byte of the next frame, or the
; first padding byte after the standing frame.

data_player_animate_left_1 = data_player_animation+player_animate_left_offset
; Player animation offset 32: move left, frame 1.
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

data_player_animate_left_2 = data_player_animate_left_1+player_animation_frame_size
; Offset 44: move left, frame 2.
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

data_player_animate_right_1 = data_player_animation+player_animate_right_offset
; Offset 56: move right, frame 1.
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

data_player_animate_right_2 = data_player_animate_right_1+player_animation_frame_size
; Offset 68: move right, frame 2.
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

data_player_animate_vertical_1 = data_player_animation+player_animate_up_down_offset
; Offset 80: move up or down, frame 1.
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

data_player_animate_vertical_2 = data_player_animate_vertical_1+player_animation_frame_size
; Offset 92: move up or down, frame 2.
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

data_player_standing = data_player_animation+player_standing_offset
; Offset 104: standing.
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
; Initialise the preloaded title screen and wait for F7 to start the first game.
;
; The title's screen codes already reside at $1c00. This routine colours all 512 bytes of its two
; corresponding colour-RAM pages blue, including the six bytes beyond the visible 22-by-23 area,
; then gives the player three lives. The second copy written to $a6 is never read anywhere in the game.
;
; poll_difficulty_selection is called repeatedly. F1 cycles displayed options 1-9, represented
; internally by delay values 9-1: option 1 is easiest and option 9 hardest. F7 returns from the loop.
; The initial room, entrance, timed sound and packed-BCD score state are then cleared before returning
; to start_of_program.
;
; Original startup quirk: start_of_program sets game_select_level=9 but not game_level.
; poll_difficulty_selection copies a value into game_level only when F1 is pressed. Starting
; immediately with F7 therefore leaves game_level dependent on the pre-existing byte at $77. This
; routine deliberately preserves that bug.
initialise_title_screen_and_wait_for_start
    ldx #0
    lda #blue
.colour_title_screen_loop
    sta _COLOUR_SCREEN_ADDR,x
    sta _COLOUR_SCREEN_ADDR+256,x
    inx
    bne .colour_title_screen_loop

    lda #starting_player_lives
    sta player_lives
    sta unused_starting_lives_copy

.wait_for_title_start
    jsr poll_difficulty_selection
    cmp #f7_key_code
    bne .wait_for_title_start

    lda #0
    sta next_screen_offset  ;select room record zero
    sta entrance_gate_position  ;zero is entrance_left
    sta timed_sound_countdown
    sta score_hundreds
    sta score_tens
    rts

;-----------------------------------------------------------------------------------
; Nine bytes between executable code and the gate tables are not referenced by the game. Some are
; nonzero, so retain them as original unidentified/padding data rather than assigning a purpose.
unreferenced_data_before_room_tables
    !byte $00
    !byte $00, $00, $00, $f3, $60, $00, $00, $00

; Four four-byte entrance-gate records: high-page adjustment followed by three cumulative low-byte
; deltas. Left/right records step down by 22 for three rows; top/bottom step right once and repeat the
; second cell on the third plot call.
data_entrance_gate_high_adjustment
data_entrance_gate_low_delta = data_entrance_gate_high_adjustment+1
    !byte $00, $dc, $16, $16  ;left
    !byte $00, $0a, $01, $00  ;top
    !byte $00, $f1, $16, $16  ;right
    !byte $01, $ee, $01, $00  ;bottom
; Player pixel spawn positions indexed by entrance_left/top/right/bottom. Each lies just inside its
; corresponding edge and is intentionally not aligned to character boundaries.
data_player_entrance_col
    !byte 9, 83, 153, 84
data_player_entrance_row
    !byte 82, 10, 82, 160
; Per-frame signed pixel deltas indexed by the active-low direction mask. The valid indexes are
; direction_down_left ($03), direction_up_left ($05), direction_left ($07), direction_down_right
; ($0a), direction_down ($0b), direction_up_right ($0c), direction_up ($0d) and direction_right ($0e).
data_direction_col_delta
    !byte $00, $00, $00, $ff, $00, $ff, $00, $ff
    !byte $00, $00, $01, $00, $01, $00, $01, $00
data_direction_row_delta
    !byte $00, $01, $01, $01, $00, $ff, $00, $00
    !byte $00, $00, $01, $01, $ff, $ff, $00, $00
; Bullet muzzle offsets indexed by the active-low direction mask. Only indices $3, $5, $7 and
; $a-$e are used: the four diagonals and four cardinal directions respectively. The nonzero offsets
; place the bullet at the appropriate edge of the 8-by-14 player/robot bitmap.
;   down-left=(-1,8), up-left=(0,0), left=(0,3), down-right=(9,8)
;   down=(5,14), up-right=(8,0), up=(5,0), right=(8,3)
data_bullet_spawn_col_offset
    !byte $00, $00, $00, $ff, $00, $00, $00, $00
    !byte $00, $00, $09, $05, $08, $05, $08, $00
data_bullet_spawn_row_offset
    !byte $00, $00, $00, $08, $00, $00, $00, $03
    !byte $00, $00, $08, $0e, $00, $00, $03, $00

;-----------------------------------------------------------------------------------
; Schedule movement for one robot at a time.
;
; This routine does not change coordinates itself. data_each_thing_status holds the selected robot's
; active-low direction, and update_object_movement_and_destruction applies its one-pixel delta earlier
; in each frame. While either coordinate is between character boundaries, this routine returns and
; lets that movement continue. On reaching an 8-pixel boundary it clears the direction, making the
; robot stationary, then counts down robot_speed before selecting the next robot.
;
; The selected record is the self-modified LDX operand. It starts at offset 144, then advances through
; 152, 96, 104, 112, 120, 128 and 136. The value persists across rooms and lives. Yellow robots retain
; their destruction countdown rather than having status cleared; if the next selected robot is yellow,
; it receives no direction and the scheduler reloads its delay before returning.
;
; A live selected robot initially aims at the player. On the 1-in-16 jiffy values whose low nibble is
; zero, or whenever that route is obstructed, robot_direction_seed is incremented and masked to four
; bits to try another direction. All screen cells needed by the robot's leading edges are checked;
; any obstacle restarts the search. Once clear, the direction is stored as movement status and the
; delay is reloaded from game_level. Thus lower game levels shorten the stationary pause between robots.
;
; Original direction-seed quirk: masking to four bits permits all values 0-15, not just the eight valid
; active-low direction masks. The movement tables define every index, so an accepted fallback can
; duplicate a vertical step or produce no movement before this robot's next scheduling cycle.
update_robot_movement_scheduler
.selected_moving_robot_index
    ldx #robot_data_index+6*object_record_size  ;self-modified; initially robot offset 144
    lda data_each_thing_col,x
    ora data_each_thing_row,x
    and #pixel_subposition_mask
    bne .end_robot_movement_scheduler
    lda data_each_thing_colour,x
    cmp #yellow
    beq .keep_destruction_countdown
    lda #0
    sta data_each_thing_status,x  ;stop on the character boundary
.keep_destruction_countdown
    dec robot_speed
    beq .select_next_robot
.end_robot_movement_scheduler
    rts

.select_next_robot
    txa
    clc
    adc #object_record_size
    cmp #inactive_robot_data_index
    bne *+4  ;skip next instruction
    lda #robot_data_index
    tax
    sta .selected_moving_robot_index+1
    lda data_each_thing_colour,x
    cmp #yellow
    bne .choose_robot_direction
    lda game_level
    sta robot_speed
    rts

.choose_robot_direction
    jsr prepare_robot_aim_towards_player  ;robot_direction receives an active-low eight-way direction
    lda one_jiffy
    and #robot_direction_seed_mask
    bne .test_selected_robot_direction

.try_another_robot_direction
    inc robot_direction_seed
    lda robot_direction_seed
    and #robot_direction_seed_mask
    sta robot_direction
.test_selected_robot_direction
    jsr calculate_object_screen_address
    sty obstacle_count  ;Y equals 0 from the subroutine above
    lda robot_direction
    and #input_right
    bne .right_edge_not_needed
    ldy #obstacle_one_right_offset
    jsr count_obstacle_at_screen_offset
    ldy #obstacle_down_right_offset
.right_edge_not_needed
    jsr count_obstacle_at_screen_offset  ;Y is down-right or zero
    cmp #direction_down_right
    bne *+4  ;skip next instruction
    ldy #obstacle_two_down_right_offset
    jsr count_obstacle_at_screen_offset
    cmp #direction_up_right
    bne *+4  ;skip next instruction
    ldy #obstacle_up_right_biased_offset
    jsr count_obstacle_at_screen_offset
    and #input_up
    bne *+4  ;skip next instruction
    ldy #obstacle_one_up_biased_offset
    jsr count_obstacle_at_screen_offset
    and #input_left
    bne .left_edge_not_needed
    ldy #obstacle_one_left_biased_offset
    jsr count_obstacle_at_screen_offset
    ldy #obstacle_down_left_offset
.left_edge_not_needed
    jsr count_obstacle_at_screen_offset  ;Y is down-left or zero
    cmp #direction_down_left
    bne *+4  ;skip next instruction
    ldy #obstacle_two_down_left_offset
    jsr count_obstacle_at_screen_offset
    cmp #direction_up_left
    bne *+4  ;skip next instruction
    ldy #obstacle_up_left_biased_offset
    jsr count_obstacle_at_screen_offset
    and #input_down
    bne *+4  ;skip next instruction
    ldy #obstacle_two_down_offset
    jsr count_obstacle_at_screen_offset
    lda obstacle_count
    bne .try_another_robot_direction

    lda robot_direction
    sta data_each_thing_status,x  ;direction-table index used by update_object_movement_and_destruction
    lda game_level
    sta robot_speed
    rts

!byte $00

;-----------------------------------------------------------------------------------
; Count a blocking character at a screen offset from the selected robot.
;
; Entry: map_address points to the robot's top-left character cell; Y supplies a relative screen
; offset; obstacle_count contains the count accumulated for the candidate direction. Y=0 is a
; deliberate no-op used by the caller's conditional chains.
;
; Positive offsets are ordinary unsigned additions. Values with bit 7 set use a biased negative
; encoding: SEC/ADC makes their effective signed displacement Y+1. The values used are therefore
; $fe=-1 (left), $ea=-21 (up-right), $e9=-22 (up), and $e8=-23 (up-left). Carry or borrow adjusts
; the address high byte in either direction.
;
; Screen codes 0-6 are treated as passable; code 7 and above increment obstacle_count. The threshold
; makes blank cells and the lower dynamic-character slots nonblocking, while walls, gates, robots,
; bullets and most other generated characters block the route.
;
; Exit: Y=0 and A=robot_direction. Returning the direction lets the caller immediately use CMP/AND
; after every check without reloading it; X and map_address are preserved.
count_obstacle_at_screen_offset
    lda map_address_high
    sta obstacle_address_high
    tya
    beq .end_obstacle_check
    bmi .add_biased_negative_offset
    clc
    adc map_address_low
    bcc *+4  ;skip high byte update line below
    inc obstacle_address_high
    jmp .read_obstacle_cell

.add_biased_negative_offset
    sec
    adc map_address_low
    bcs *+4  ;skip high byte update line below
    dec obstacle_address_high
.read_obstacle_cell
    sta obstacle_address_low
    ldy #0
    lda (obstacle_address_low),y
    cmp #first_blocking_screen_character
    bcc *+4  ;skip high byte update line below
    inc obstacle_count
.end_obstacle_check
    lda robot_direction
    rts

;-----------------------------------------------------------------------------------
; Poll F1 and, when pressed, advance the displayed difficulty option.
;
; The user-facing options run from 1 (easiest) to 9 (hardest), but game_select_level stores the
; inverse movement-delay value: option 1 is 9, option 2 is 8, ... option 9 is 1. Each F1 press
; decrements that value and wraps zero back to nine. The same delay is copied to game_level so it
; controls robot movement immediately and contributes to robot firing timing.
;
; Subtracting the internal value from 58 converts it to the screen code for the displayed option:
; 58-9=49 (digit 1) through 58-1=57 (digit 9). This is written to the option digit in the preloaded
; title screen. Masking that screen code to its low nibble also yields the numeric digit 1-9, which
; is stored in score_tens. At game over, render_score_and_lives therefore shows the selected option
; in the score's units position; the next game clears the score before play resumes.
;
; The routine waits for F1 to be released, preventing one press from cycling repeatedly. It returns
; the current key code in A: normally the non-F1 code which ended the debounce, or the initially
; sampled code when F1 was not pressed. Both callers use this return value to recognise F7.
poll_difficulty_selection
    lda _CURRENT_KEY_CODE  ;matrix coordinate of current key pressed, 64 if none
    cmp #f1_key_code
    bne .end_difficulty_poll
    lda game_select_level
    sec
    sbc #1
    bne .store_difficulty_delay
    lda #difficulty_option_count
.store_difficulty_delay
    sta game_level
    sta game_select_level
    lda #difficulty_digit_screen_code_base
    sec
    sbc game_select_level
    sta _SCREEN_ADDR+title_option_digit_offset
    and #15
    sta score_tens
.wait_for_f1_release
    lda _CURRENT_KEY_CODE  ;matrix coordinate of current key pressed, 64 if none
    cmp #f1_key_code
    beq .wait_for_f1_release
.end_difficulty_poll
    rts

!byte $00

end_code3
