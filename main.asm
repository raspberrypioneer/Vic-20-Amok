; Amok for the Commodore VIC-20 (unexpanded)
; Programmed by Roger L. Merritt and released by United Microware Industries (UMI) in 1981/1982.
;
; Amok! is a clone of the classic arcade sci-fi game Berzerk. In this game the player guides a
; human character through dangerous, maze-like rooms inside a space station to destroy rampaging
; killer robots.
;
; Highlights:
;   Rendering uses two 512-byte screen pages at $1c00 and $1e00.
;   While one page is displayed, the complete next frame is constructed in the other.
;   VIC register $9002 bit 7 then selects the completed page for display.
;
;   This prevents the player seeing the screen being cleared and rebuilt. A frame redraw
;   includes the borders, maze, robots, software sprites, score and colours, so drawing
;   directly into the visible screen would cause considerable flicker.
;
;   The custom character set is shared by both screen pages. Double buffering protects
;   the character-cell layout, while the software-sprite routines rewrite character
;   bitmaps for pixel-positioned player and bullet graphics. Shifted bitmap rows are
;   composited with existing characters, providing both drawing and pixel-level collision.
;
;   Memory is used particularly economically. Robots, the player and bullets share one
;   object-record format; zero-page workspace has routine-specific aliases; and several
;   tables intentionally overlap unused portions of other data. Self-modified operands
;   select screen pages, animation paths, character sources and round-robin objects.
;
; This disassembly explains how this well-crafted game works in detail.
; An 8K+ expanded version is also included. Other than its memory layout, it is identical
; to the original unexpanded version and is provided for modern VIC-20 configurations that
; commonly have at least 8K of expansion RAM.
;
; Note: References in comments apply to COMPUTE! Mapping the VIC (MTV)

;--------------------------------------------------------------------------------------------------

_SCREEN_BUFFER_1 = $1c00
_SCREEN_BUFFER_2 = $1e00
_SCREEN_BUFFER_SIZE = 512
_SCREEN_COLUMNS = 22
_SCREEN_ROWS = 23
_BOTTOM_SCREEN_ROW = (_SCREEN_ROWS-1)*_SCREEN_COLUMNS  ;484
_RIGHT_SCREEN_COLUMN = _SCREEN_COLUMNS-1  ;21
_LOWER_SIDE_WALLS = 13*_SCREEN_COLUMNS  ;286: resume side walls after the three-row opening
_VIC_CR2_SCREEN_BUFFER_1 = %00010110  ;22 columns, screen-address bit 9 clear
_VIC_CR2_SCREEN_BUFFER_2 = %10010110  ;22 columns, screen-address bit 9 set
; screen to colour map offset (high byte) = $78
; for screen buffer 1: $1c + $78 = $94 or for screen buffer 2: $1e + $78 = $96
_SCREEN_TO_COLOUR_HIGH_OFFSET = 120
_COLOUR_SCREEN_ADDR    = $9400  ;37888 colour memory

_VIC_CR2               = $9002  ;36866 bit 7 to switch screen buffer (see program comments)
                                ;      bit 6-0: for characters per column
_VIC_CR5               = $9005  ;36869 provides the screen and pixel bitmap memory addresses
_VIC_SOUND_SOPRANO     = $900c  ;36876 audio frequency generator 3
_VIC_SOUND_NOISE       = $900d  ;36877 audio frequency generator 4
_VIC_VOLUME_AUX_COLOUR = $900e  ;36878 bit 7-4 for aux colour, bit 3-0 for no volume
_VIC_BG_BORDER_COL     = $900f  ;36879 bit 7-4 for background, bit 3-0 for border
_VIA_JOYSTICK          = $9111  ;37137 port A I/O register
_VIA_KEYB_ROWS         = $9120  ;37152 port B I/O register
_VIA_DATADIR_B         = $9122  ;37154 data direction register for port B
_VIC_CASEURV           = $8400  ;33792 reversed characters, see MTV page 118

;--------------------------------------------------------------------------------------------------
; Zero page addresses

; $60-$70 are a shared transient workspace. Aliases are valid only within
; their respective routines; values are not expected to survive subroutine calls.
draw_screen_high = $60  ;holds screen buffer high byte
map_address_low = $61  ;screen position low byte
map_address_high = $62  ;screen position high byte

; Routine-specific aliases for $63-$64.
colour_map_address_low = $63
colour_map_address_high = $64
custom_char_address_low = $63
custom_char_address_high = $64
obstacle_address_low = $63
obstacle_address_high = $64

source_char_address_low = $65
source_char_address_high = $66
robot_position_adjustment = $65

screen_colour_address_low  = $67
screen_colour_address_high = $68
robot_will_not_fire = $68  ;0 = may fire, nonzero = do not fire

input_bits = $69  ;keyboard/joystick directions and fire
robot_direction = $69  ;active-low direction-table index for robot aiming/movement
custom_char_clear_count = $69
current_object_index = $69

bitmap_rows_remaining = $6a
player_robot_y_delta = $6a
shifted_bitmap_overflow = $6b
robot_half_y = $6b
saved_object_index = $6c
player_half_y = $6c
player_robot_x_delta = $6d
nonzero_sprite_row_count = $6e
robot_half_x = $6e
collision_row_count = $6f
player_half_x = $6f
absolute_x_delta = $6f
obstacle_count = $6f  ;count of obstacles next to robot to determine movement direction
next_score_display_character = $6f
wall_position_adjustment = $70
robot_aim_tolerance = $70
custom_char_bytes_remaining = $70
screen_character_column = $70

next_screen_offset = $71  ;level-data offset: $00, $10, $20 or $30
                          ;adding $10 after floor four produces $40, which triggers
                          ;the level-complete bonus and is replaced with zero
entrance_gate_position = $72  ;one of entrance_left/top/right/bottom
timed_sound_countdown = $73
; The four-digit score uses packed binary-coded decimal (BCD), with one decimal digit in each four-bit
; nibble. For example, a displayed score of 1234 is held as score_hundreds=$12 and score_tens=$34.
; Thus byte $15 represents decimal digits "15", even though ordinary binary interprets it as 21.
; Score additions run with the 6502 decimal flag set (SED), making ADC carry from 9 to the next nibble;
; rendering instead masks and shifts each nibble to recover its individual digit. CLD restores normal
; binary arithmetic after an update.
score_hundreds = $74  ;packed BCD thousands and hundreds digits
score_tens = $75  ;packed BCD tens and units digits
player_lives = $76
game_level = $77  ;movement delay/difficulty value. 9 is easiest; 1 is hardest
game_select_level = $78  ;title-screen option retained for restarting after game over

one_jiffy = $a2
input_poll_delay = $a3
robot_fire_delay = $a4  ;frames until the next robot is given an opportunity to fire
robot_speed = $a5  ;robot movement speed
unused_starting_lives_copy = $a6  ;written with 3 on the title screen; never read by the game
robot_direction_seed = $a7
collision_scratch_marker = $00ad  ;write-only collision marker; no later read exists in the game

_CURRENT_KEY_CODE = $cb  ;matrix coordinate of current key pressed, 64 if none
_KEYBOARD_MODIFIER_FLAGS = $028d  ;keyboard Shift/Control flag

;--------------------------------------------------------------------------------------------------
; Colours
black = 0
white = 1
red = 2
cyan = 3
purple = 4
green = 5
blue = 6
yellow = 7

; Game constants
screen_buffer_1_high = 28  ;$1c
screen_buffer_2_high = 30  ;$1e
object_record_size = 8
object_record_count = 20  ;nine robot-shaped records, player, nine robot bullets and player bullet
pixels_per_character = 8
pixel_subposition_mask = pixels_per_character-1
room_wall_count = 8
room_layout_size = 16  ;eight wall bytes followed by eight robot bytes
rooms_per_cycle = 4
completed_cycle_room_offset = rooms_per_cycle*room_layout_size
room_shuffle_partner_offset = 2*room_layout_size
room_shuffle_jiffy_mask = %00110000  ;select record offset 0, 16, 32 or 48
entrance_left = 0
entrance_top = 1
entrance_right = 2
entrance_bottom = 3
player_near_exit_coordinate = 1
player_right_exit_col = 168
player_bottom_exit_row = 170
no_room_exit = $ff
close_robot_aim_tolerance = 3
unused_wide_robot_aim_tolerance = 14
room_initial_delay_and_sound_off = 112  ;also disables VIC voices because bit 7 is clear
robot_fire_delay_bias = 61
room_transition_jiffy_addend = 24  ;effective delay is 25 because the sole caller supplies carry set
room_transition_colour = 8
normal_game_colour = 30
robot_direction_seed_mask = $0f
obstacle_one_right_offset = 1
obstacle_down_right_offset = 23
obstacle_two_down_right_offset = 45
obstacle_up_right_biased_offset = 234  ;negative path converts this to -21
obstacle_one_up_biased_offset = 233  ;negative path converts this to -22
obstacle_one_left_biased_offset = 254  ;negative path converts this to -1
obstacle_down_left_offset = 21
obstacle_two_down_left_offset = 43
obstacle_up_left_biased_offset = 232  ;negative path converts this to -23
obstacle_two_down_offset = 44
first_blocking_screen_character = 7
starting_player_lives = 3
f1_key_code = 39
f7_key_code = 63
difficulty_option_count = 9
difficulty_digit_screen_code_base = 58  ;10 more than the screen code for digit 0
title_option_digit_offset = _BOTTOM_SCREEN_ROW+16
active_robot_count = 8
robot_data_index = 96
inactive_robot_data_index = 160
player_data_index = 168
robot_bullet_data_index = 176
player_bullet_data_index = 248
input_right = %00000001  ;active-low input bits: zero means pressed
input_up    = %00000010
input_down  = %00000100
input_left  = %00001000
input_fire  = %00010000
input_directions = %00001111
input_idle = %00011111
direction_right = input_directions XOR input_right
direction_up = input_directions XOR input_up
direction_down = input_directions XOR input_down
direction_left = input_directions XOR input_left
direction_up_right = input_directions XOR (input_up OR input_right)
direction_down_right = input_directions XOR (input_down OR input_right)
direction_up_left = input_directions XOR (input_up OR input_left)
direction_down_left = input_directions XOR (input_down OR input_left)
input_poll_interval = 3
bullet_sound_frequency = 248
bullet_sound_stop_frequency = 218
hit_sound_duration = 15
floor_cycle_bonus_hundreds = 1  ;one unit in score_hundreds represents 100 points
extra_life_score_high_bcd = $15  ;packed BCD thousands/hundreds pair for 1500 points
collision_scratch_value = $f7
colliding_object_countdown = 24
hit_target_countdown = 14
solid_wall_bitmap_row = $ff
game_audio_volume = 14
player_animation_frame_size = 12
custom_character_memory_high = $18
character_bitmap_size = 8
software_sprite_workspace_size = 48  ;six characters: two columns by three rows
software_sprite_column_size = 24  ;three vertically adjacent characters
bullet_workspace_size = 8
first_bullet_workspace_offset = $70
player_animate_up_down_offset = 80
player_animate_left_offset = 32
player_animate_right_offset = 56
player_standing_offset = 104
packed_bcd_high_nibble_mask = $f0
packed_bcd_low_nibble_mask = $0f
rom_digit_zero_bitmap_offset = 48*character_bitmap_size
first_score_character = 32
lives_marker_character = 36
first_score_screen_column = 1
lives_marker_screen_column = 19
lives_digit_custom_bitmap_offset = (lives_marker_character+1-first_score_character)*character_bitmap_size

; Custom character numbers
bullet_character = 1
robot_character_1 = 24  ;head; tail is character 25
player_character  = 26  ;head; tail is character 27
wall_character = 28
robot_character_2 = 29  ;head; tail is character 30
gate_character = 31

;--------------------------------------------------------------------------------------------------
; Allow the program to run on either an unexpanded or 8K+ expanded VIC-20
; Value defined in build script
; USE_8k_MEMORY_LAYOUT = 0  ;0 = unexpanded memory layout or 1 = 8K+ expanded memory layout
;
; The memory map for the original unexpanded is:
;   $1001  BASIC loader
;   $100e  code1 and code2
;   $1800  custom character set
;   $1930  code3
;   $1c00  title screen / first screen buffer
;   $1e00  second screen buffer at runtime
;
; The memory map for the 8K expanded version is:
;   $1201  BASIC loader
;   $120e  code1
;   $1800  custom character set
;   $19f8  8K compatibility helper
;   $1a00  code2
;   $1c00  title screen / first screen buffer
;   $1e00  second screen buffer
;   $2030  code3

;--------------------------------------------------------------------------------------------------
!if USE_8k_MEMORY_LAYOUT = 1 {

;--------------------------------------------------------------------------------------------------
* = $1201  ;basic loader
!byte $0c,$10,$0a,$00,$9e
!scr " 4622"  ;start address for sys 4622 to start_of_program
!byte $00,$00,$00

;--------------------------------------------------------------------------------------------------
!source "code1.asm"

* = $1800
!source "spr.asm"  ;sprite custom characters

!fill 200, 0  ;used to align low byte addresses so they're the same as the unexpanded layout

extras_8k
    ; The expanded VIC does not have the unexpanded machine's usable power-on memory setup.
    ; Select screen buffer 1 at $1c00 and the VIC ROM character set for the title screen.
    lda #%11110000  ;$f0: screen base $1c00, ROM character set
    sta _VIC_CR5
    jmp initialise_title_screen_and_wait_for_start  ;tail call: RTS returns through extras_8k's caller

!source "code2.asm"

* = _SCREEN_BUFFER_1
!source "screen.asm"  ;includes an extra byte (original is 513 bytes), hence the +1 / -1 adjustments
* = _SCREEN_BUFFER_2+1  ;an extra 2 pages are needed for the second screen buffer
!fill _SCREEN_BUFFER_SIZE-1, 0

!fill 48, 0  ;used to align low byte addresses so they're the same as the unexpanded layout
!source "code3.asm"

} else {

;--------------------------------------------------------------------------------------------------
* = $1001  ;basic loader
!byte $0c,$10,$0a,$00,$9e
!scr " 4110"  ;start address for sys 4110 to start_of_program
!byte $00,$00,$00

;--------------------------------------------------------------------------------------------------
!source "code1.asm"
!source "code2.asm"

* = $1800  ;sprite custom characters
!source "spr.asm"

!source "code3.asm"

* = _SCREEN_BUFFER_1
!source "screen.asm"
; The second screen buffer _SCREEN_BUFFER_2 of _SCREEN_BUFFER_SIZE bytes resides here

}

end_of_program
