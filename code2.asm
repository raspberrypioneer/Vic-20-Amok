;-----------------------------------------------------------------------------------
; Aim robot X towards the player and decide whether that direction is sufficiently accurate to fire.
;
; Both coordinates are halved before subtraction, keeping their signed deltas within -85..+85. If
; the horizontal separation is below robot_aim_tolerance, aim vertically; otherwise, if the vertical
; separation is below it, aim horizontally. In all other cases aim diagonally, but set
; robot_will_not_fire when the two axis magnitudes differ by at least the tolerance.
;
; robot_direction uses the same active-low direction mask as player input. Negative deltas mean that
; the player is left/above the robot; positive deltas mean right/below. The compact absolute-value
; operations use EOR #$ff, so a negative magnitude is represented one less than its mathematical
; absolute value. This makes each negative-side tolerance test one half-coordinate unit more lenient.
;
; Return: Z set and A=0 if either object is inactive; otherwise Z clear, robot_direction selected,
; and robot_will_not_fire set to zero or one. The coordinate and delta zero-page values are scratch.
aim_robot_at_player
    lda data_each_thing_row,x
    bne .robot_is_active
    rts

.robot_is_active
    lda data_player_hero_row
    bne .player_is_active
    rts

.player_is_active
    lda #0  ;robot may fire
    sta robot_will_not_fire

    ; Divide the coordinates by two, then calculate signed player-minus-robot deltas.
    clc
    lda data_each_thing_col,x
    ror
    sta robot_half_x
    clc
    lda data_player_hero_col
    ror
    sta player_half_x
    sec
    sbc robot_half_x
    sta player_robot_x_delta
    clc
    lda data_each_thing_row,x
    ror
    sta robot_half_y
    clc
    lda data_player_hero_row
    ror
    sta player_half_y
    sec
    sbc robot_half_y
    sta player_robot_y_delta

    ; Nearly the same X coordinate: fire vertically towards the player.
    lda player_robot_x_delta
    bpl .x_magnitude_ready
    eor #$ff  ;one's-complement magnitude: abs(delta)-1 for a negative delta
.x_magnitude_ready
    cmp robot_aim_tolerance
    bcs .not_vertically_aligned
    lda player_robot_y_delta
    bmi .aim_up
    lda #direction_down
    bne *+4  ;always branch, skipping next statement
.aim_up
    lda #direction_up
    sta robot_direction
    rts

.not_vertically_aligned
    ; Nearly the same Y coordinate: fire horizontally towards the player.
    lda player_robot_y_delta
    bpl *+4  ;skip next instruction
    eor #$ff
    cmp robot_aim_tolerance
    bcs .select_diagonal
    lda player_robot_x_delta
    bpl .aim_right
    lda #direction_left
    bne *+4  ;always branch, skipping next statement
.aim_right
    lda #direction_right
    sta robot_direction
    rts

.select_diagonal
    ; A diagonal shot is allowed only when |X| and |Y| are close enough to describe a roughly
    ; 45-degree line. The direction is still returned when firing is disallowed because robot
    ; movement also uses this routine to obtain a direction towards the player.
    lda player_robot_x_delta
    bpl *+4  ;skip next instruction
    eor #$ff
    sta absolute_x_delta
    lda player_robot_y_delta
    bpl *+4  ;skip next instruction
    eor #$ff
    sec
    sbc absolute_x_delta
    bpl *+4  ;skip next instruction
    eor #$ff
    cmp robot_aim_tolerance
    bcc .diagonal_fire_allowed
    lda #1  ;robot will not fire
    sta robot_will_not_fire
.diagonal_fire_allowed
    lda player_robot_y_delta
    bpl .player_is_below
    lda player_robot_x_delta
    bpl .aim_up_right
    lda #direction_up_left
    bne *+4  ;always branch, skipping next statement
.aim_up_right
    lda #direction_up_right
    sta robot_direction
    rts

.player_is_below
    lda player_robot_x_delta
    bpl .aim_down_right
    lda #direction_down_left
    bne *+4  ;always branch, skipping next statement
.aim_down_right
    lda #direction_down_right
    sta robot_direction
    rts

!byte $00

;-----------------------------------------------------------------------------------
; Shuffle one pair of complete room-layout records after the player loses a life.
;
; Bits 4-5 of the low jiffy-clock byte select a 16-byte record offset: 0, 16, 32 or 48. That record
; is exchanged in place with the record 32 bytes later, producing one of these pairings:
;
;   room 1 <-> room 3          room 2 <-> room 4
;   room 3 <-> alternate 1     room 4 <-> alternate 2
;
; Each record contains eight wall entries followed by eight robot-position entries, so the routine
; changes the complete room setup rather than only its inner walls. The exchanges are cumulative;
; repeated deaths therefore permute the layouts along two independent three-record chains. The
; caller resets next_screen_offset first, so setup_robots_and_player immediately uses the newly
; selected contents of room 1.
shuffle_room_layout_pair_using_jiffy
    lda one_jiffy
    and #room_shuffle_jiffy_mask
    tax
    ldy #0
.swap_room_byte_loop
    lda data_room_layouts,x
    pha
    lda data_room_shuffle_partners,x
    sta data_room_layouts,x
    pla
    sta data_room_shuffle_partners,x
    iny
    inx
    cpy #room_layout_size
    bne .swap_room_byte_loop
    rts

!byte $00, $00

;-----------------------------------------------------------------------------------
; Advance every runtime object and expire objects in their yellow destruction state.
;
; X visits all twenty eight-byte records: eight active robots, the normally unused ninth robot, the
; player, nine robot bullets and the player bullet. Adding eight after offset 248 wraps X to zero and
; terminates the loop. A zero row is the common inactive marker and causes the record to be ignored.
;
; data_each_thing_status is overloaded according to colour:
;   non-yellow object - active-low direction-table index; zero means stationary
;   yellow object     - destruction countdown; position is cleared when it reaches zero
;
; Movement is one pixel per axis per frame. The direction indexes select signed -1/0/+1 deltas from
; data_direction_col_delta/data_direction_row_delta and are shared by moving robots and bullets.
; Player movement is applied
; directly by get_user_input, so its status normally remains zero here.
update_object_movement_and_destruction
    ldx #robot_data_index
.object_update_loop
    lda data_each_thing_row,x
    beq .advance_to_next_runtime_object
    lda data_each_thing_colour,x
    cmp #yellow
    beq .update_destruction_countdown

    ; A normal object's status is its movement-table index. Robots waiting for the movement scheduler
    ; a direction and the separately controlled player both have status zero.
    lda data_each_thing_status,x
    tay
    beq .advance_to_next_runtime_object

    ; Column zero is outside the playing area. Clear both coordinates before consulting the movement
    ; tables; row zero is already handled by the inactive test at the top of the loop.
    lda data_each_thing_col,x
    beq .deactivate_object
    clc
    adc data_direction_col_delta,y
    sta data_each_thing_col,x
    lda data_direction_row_delta,y
    clc
    adc data_each_thing_row,x
    sta data_each_thing_row,x
    jmp .advance_to_next_runtime_object

.update_destruction_countdown
    ; Collision handling has already changed the colour to yellow and loaded either the current-
    ; object or target-object countdown. Yellow objects remain visible but stationary until expiry.
    dec data_each_thing_status,x
    bne .advance_to_next_runtime_object
.deactivate_object
    lda #0
    sta data_each_thing_col,x
    sta data_each_thing_row,x
.advance_to_next_runtime_object
    txa
    clc
    adc #object_record_size
    tax
    bne .object_update_loop  ;player bullet offset 248 + record size wraps to zero
    rts

;-----------------------------------------------------------------------------------
; Continue the frame loop or enter the next room when the player crosses a room boundary.
;
; The helper returns the opposite edge as the next room's entrance: leaving left/right/top/bottom
; produces entrance right/left/bottom/top respectively. `$ff` means no exit; its set negative flag
; provides the compact branch back to main_frame_loop. Horizontal edges are tested before vertical
; edges, giving them precedence in the otherwise unlikely case of an exact corner coordinate.
;
; The chosen edge affects only the player's entrance position and the gate closed behind them. Every
; exit advances to the next sequential room layout; there is no directional room map. Exact boundary
; comparisons are sufficient because player movement changes each coordinate one pixel at a time.
;
; Every successful exit advances the 16-byte room-layout offset. Leaving the fourth room produces
; the transient offset 64; complete_four_floor_cycle awards the bonus, increases difficulty and
; returns zero to wrap the layout selection. Both paths tail-jump rather than return.
handle_player_room_exit
    jsr .get_opposite_entrance_for_player_exit
    bpl .begin_next_room
    jmp main_frame_loop

.begin_next_room
    sta entrance_gate_position
    lda next_screen_offset  ;stored room offsets are 0, 16, 32 and 48
    clc
    adc #room_layout_size
    cmp #completed_cycle_room_offset  ;64 occurs only transiently after leaving the fourth room
    bne .room_cycle_not_complete
    jsr complete_four_floor_cycle  ;returns A=0 to wrap around to the first room
.room_cycle_not_complete
    sta next_screen_offset
    jmp start_new_room

.get_opposite_entrance_for_player_exit
    lda data_player_hero_col
    cmp #player_near_exit_coordinate
    bne .player_not_at_left_exit
    lda #entrance_right
    rts
.player_not_at_left_exit
    cmp #player_right_exit_col
    bne .player_not_at_right_exit
    lda #entrance_left
    rts
.player_not_at_right_exit
    lda data_player_hero_row
    cmp #player_near_exit_coordinate
    bne .player_not_at_top_exit
    lda #entrance_bottom
    rts
.player_not_at_top_exit
    cmp #player_bottom_exit_row
    bne .player_has_not_exited_room
    lda #entrance_top
    rts
.player_has_not_exited_room
    lda #no_room_exit
    rts

;-----------------------------------------------------------------------------------
; Calculate robot X's direction towards the player using the close aiming tolerance.
;
; This wrapper is shared by robot firing and movement. It preserves aim_robot_at_player's return
; convention: Z set/A=0 when the robot or player is inactive; Z clear/A nonzero otherwise. For an
; active pair it also leaves robot_direction set and robot_will_not_fire indicating whether the
; player is sufficiently aligned for a shot. The movement caller uses the direction regardless of
; the firing decision.
;
; Original dead-code quirk: aim_robot_at_player always stores one of eight nonzero directions for an
; active pair. The LDA/BNE below must therefore return, making the second call with tolerance 14
; unreachable in normal execution. It looks like a remnant of an earlier version which could leave
; robot_direction zero. The effective tolerance is always 3; the dormant code is retained unchanged.
prepare_robot_aim_towards_player
    lda #close_robot_aim_tolerance
    sta robot_aim_tolerance
    jsr aim_robot_at_player
    bne .active_pair_was_aimed
.end_robot_aim_preparation
    rts

.active_pair_was_aimed
    lda robot_direction  ;always one of the eight nonzero active-low direction masks
    bne .end_robot_aim_preparation

.unreachable_wide_tolerance_retry
    lda #unused_wide_robot_aim_tolerance
    sta robot_aim_tolerance
    jsr aim_robot_at_player
    rts

;-----------------------------------------------------------------------------------
; Count down to, then give one robot its round-robin opportunity to fire.
;
; run_room_transition_pause starts every room with a 112-frame delay. After the first opportunity, the delay
; normally becomes approximately 61 + game_level - next_screen_offset frames. Higher room offsets
; therefore make firing progressively more frequent, while the decreasing game_level adds a smaller
; increase after each completed four-room cycle.
;
; Original carry quirk: neither the entry nor the ADC is preceded by CLC. Because the sum cannot
; overflow, the following SBC sees carry clear, making the exact reload value:
;
;   60 + game_level - next_screen_offset + carry_on_entry
;
; Carry arrives from update_soprano_sound (and sometimes ultimately the screen-buffer CMP), so the
; interval can differ by one frame. This timing jitter is preserved.
;
; On expiry, a self-modified immediate operand advances through the eight active robot records. Its
; initial value is 112, making offset 120 the first candidate, followed by 128..152 and 96..112. The
; selected index persists across rooms/lives. A failed opportunity— inactive player/robot, unsuitable
; aim, or an existing bullet—is not offered to another robot; selection resumes at the next expiry.
update_robot_firing
    dec robot_fire_delay
    beq .reload_robot_fire_delay
    rts

.reload_robot_fire_delay
    lda #robot_fire_delay_bias
    adc game_level
    sbc next_screen_offset  ;stored room offsets are $00, $10, $20 and $30
    sta robot_fire_delay

    ; Advance the embedded previous index by one record and wrap before the inactive ninth robot.
    clc
.previous_firing_robot_index
    lda #robot_data_index+2*object_record_size  ;self-modified previous robot index; initially 112
    adc #object_record_size
    cmp #inactive_robot_data_index
    bne .store_firing_robot_index
    lda #robot_data_index
.store_firing_robot_index
    sta .previous_firing_robot_index+1
    tax
    jsr prepare_robot_aim_towards_player
    beq .end_robot_firing_update
    lda robot_will_not_fire
    bne .end_robot_firing_update
    jsr fire_bullet_if_ok
.end_robot_firing_update
    rts

!byte $00

;-----------------------------------------------------------------------------------
; Handle the transition from the player's completed destruction countdown to a respawn or game over.
;
; Collision handling first turns the player yellow and loads a destruction countdown. The object
; updater eventually clears the player's row; on the following frame that zero row reaches this
; routine and costs one life.
;
; With lives remaining, play returns to the first room while retaining the score, difficulty and
; current entrance edge. One jiffy-selected room pair is shuffled before all robots, bullets and the
; player are reinitialised. The changed layout data persists into later lives and new games.
;
; At zero lives, poll_difficulty_selection is called once per frame: F1 cycles the next game's
; difficulty and F7 restarts. Because the inactive player remains at row zero, subsequent frames enter
; this routine
; again; DEC changes lives from 0 to $ff and the BMI/INC pair clamps it back to zero. Restart resets
; lives, score and room offset, and applies game_select_level, but deliberately retains the current
; entrance edge, shuffled layouts, firing selector and other persistent state.
handle_player_death
    lda data_player_hero_row
    beq .consume_player_life
    rts

.consume_player_life
    dec player_lives
    beq .poll_game_over_input
    bmi .restore_zero_lives

    ; A nonfinal death always restarts from the current contents of room record zero.
    lda #0
    sta next_screen_offset
    jsr shuffle_room_layout_pair_using_jiffy
    jsr setup_robots_and_player
    rts

.restore_zero_lives
    inc player_lives
.poll_game_over_input
    jsr poll_difficulty_selection
    cmp #f7_key_code
    bne .game_over_input_complete

    lda #starting_player_lives
    sta player_lives
    lda #0
    sta score_hundreds
    sta score_tens
    sta next_screen_offset
    lda game_select_level
    sta game_level
    jsr setup_robots_and_player
.game_over_input_complete
    rts

!byte $00, $00, $00, $00, $00, $00, $00

;-----------------------------------------------------------------------------------
; Select the hidden screen buffer, retarget the drawing code, and construct the next complete frame.
;
; Amok rebuilds the entire 22-by-23 display every frame, including clearing 512 screen bytes, clearing
; 512 colour bytes, redrawing the room and compositing the software sprites. Doing that directly in
; the displayed buffer would expose the clear-and-redraw process as visible flicker. Instead, this
; routine alternates drawing between the 512-byte buffers at $1c00 and $1e00. main_frame_loop changes
; VIC register $9002 only after drawing finishes, exposing the completed buffer in one page flip.
;
; The renderer addresses the chosen buffer in two ways:
;
;   - Fast bulk clear/border loops use absolute indexed stores. Their embedded high address bytes are
;     self-modified here for the selected screen's two pages and corresponding colour-RAM pages.
;   - Walls, gates, objects and score rendering use calculated/indirect addresses. Those routines read
;     draw_screen_high, so storing the selected base page there retargets them without further patches.
;
; draw_screen_high is not explicitly initialised at program start. Any initial value other than $1e
; selects hidden buffer 2 for the first frame as intended; an initial value of $1e instead selects the
; currently visible buffer 1 for that first build. Subsequent calls always alternate correctly.
build_next_frame_in_hidden_buffer

    lda draw_screen_high
    cmp #screen_buffer_2_high
    bne .select_draw_buffer_2
    lda #screen_buffer_1_high
    bne .apply_draw_buffer_addresses  ;always branch
.select_draw_buffer_2
    lda #screen_buffer_2_high
.apply_draw_buffer_addresses
    sta draw_screen_high

    ; Patch operands which address the first 256-byte screen page.
    sta draw_vertical_borders_loop+7
    sta clear_horizontal_exits+2
    sta clear_horizontal_exits+5
    sta clear_draw_buffer_loop+2
    sta draw_horizontal_borders_loop+2
    sta draw_vertical_borders_loop+4

    ; Advance to and patch operands which address the second screen page.
    clc
    adc #1
    sta clear_draw_buffer_loop+5
    sta draw_horizontal_borders_loop+5
    sta draw_vertical_borders_loop+10
    sta draw_vertical_borders_loop+13
    sta clear_horizontal_exits+8
    sta clear_horizontal_exits+11

    ; Convert screen page+1 into the corresponding first colour-RAM page. The -1 compensates for the
    ; page increment above; a final increment selects the second colour page.
    clc
    adc #_SCREEN_TO_COLOUR_HIGH_OFFSET-1
    sta clear_draw_buffer_loop+8
    clc
    adc #1
    sta clear_draw_buffer_loop+11

    ; Construct the complete frame while the VIC continues displaying the previous one.
    jsr draw_screen_and_start_game_action
    rts

end_code2
