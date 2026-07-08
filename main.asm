; Amok for the Commodore Vic20 (unexpanded)
; Note: References in comments apply to COMPUTE! Mapping the VIC (MTV)

; The screen address is fixed at location $1c00 (see end near of program)
; It is not the default unexpanded screen location, see _VICCR5 setting below.
;_SCREEN_ADDR = $1c00  ;7168
_COLOUR_SCREEN_ADDR = $9400  ;37888
_BACKGROUND_BORDER_COLOUR = $900f  ;36879
_SOUND3      = $900c  ;36876
_NOISE       = $900d  ;36877
_VOLUME      = $900e  ;36878
_JOYSTICK    = $9111  ;37137
_KEYB_ROWS   = $9120  ;37152
_DATADIR_B   = $9122  ;37154
_VICCR2      = $9002  ;36866
_VICCR5      = $9005  ;36869
_CASEURV     = $8400  ;33792 reversed characters MTV page 118

;-----------------------------------------------------------------------------------
;Zero page addresses

screen_or_shadow_high = $60  ;holds screen or shadow screen high byte
map_address_low = $61  ;screen position low byte
map_address_high = $62  ;screen position high byte
colour_address_low = $67  ;colour map low
colour_address_high = $68  ;colour map high
robot_fire_bullet_indicator = $68  ;[reused] 0 is will fire, 1 will not
key_press = $69  ;key / joystick directions and fire
robot_direction_finder = $69  ;pointer to next robot direction
obstacle_count = $6f  ;count of obstacles next to robot to determine movement direction
next_screen_offset = $71  ;used to point to the next screen
entrance_gate_position = $72  ;values are 0,1,2,3,255
play_sound_duration = $73
score_hundreds = $74
score_tens = $75
player_lives = $76
game_level = $77
game_select_level = $78
one_jiffy = $a2
game_speed = $a4  ;is a delay which depends on the level and screen (higher values are slower)
robot_speed = $a5  ;robot movement speed

;-----------------------------------------------------------------------------------
;Colours
black = 0
white = 1
red = 2
cyan = 3
purple = 4
green = 5
blue = 6
yellow = 7

;Other
screen_high_byte = 28  ;$1c
shadow_screen_high_byte = 30  ;$1e
screen_colour_map_offset = 120  ;screen to colour map offset (high byte)
player_data_index = 168
player_animate_up_down_offset = 80
player_animate_left_offset = 32
player_animate_right_offset = 56

;Sprites
bullet_character = 1
robot_head1 = 24
robot_tail1 = 25
player_head1 = 26
player_tail1 = 27
wall_character = 28
robot_head2 = 29
robot_tail2 = 30
gate_character = 31

;-----------------------------------------------------------------------------------
;Allow the program to run on either an unexpanded or 8K+ expanded VIC20
;Value defined in build script
;USE_8k_MEMORY_LAYOUT = 0  ;0 = unexpanded memory layout or 1 = 8K+ expanded memory layout

;-----------------------------------------------------------------------------------
!if USE_8k_MEMORY_LAYOUT = 1 {

;--------------------------------------------------------------------------------
* = $1201
!byte $0c,$10,$0a,$00,$9e,$20,$34,$36,$32,$32,$00,$00,$00
;Note                 sys       4   6   2   2            is sys4622 to start_of_program

;--------------------------------------------------------------------------------
!source "code1.asm"

* = $1800
!source "spr.asm"

;Used to align low byte addresses so they're the same as the unexpanded layout
!fill 208, 0
!source "code2.asm"

* = $1c00
!source "screen.asm"

;Used to align low byte addresses so they're the same as the unexpanded layout
;An extra 2 pages are needed because memory beyond the screen memory map is used
!fill 512+47, 0
!source "code3.asm"

extras_8k
    lda #240  ;254 = 1111 1110
    sta _VICCR5
    jsr title_screen_select_option
    jmp extras_8k_done

} else {

;--------------------------------------------------------------------------------
* = $1001
!byte $0c,$10,$0a,$00,$9e,$20,$34,$31,$31,$30,$00,$00,$00
;Note                 sys       4   1   1   0            is sys4110 to start_of_program

;--------------------------------------------------------------------------------
!source "code1.asm"
!source "code2.asm"

* = $1800
!source "spr.asm"

!source "code3.asm"

* = $1c00
!source "screen.asm"

}

end_of_program