;Data = $1800 to $1930 (6144 to 6448)
;38 x 8 = 304 bytes
data_custom_characters
;0 blank character
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;1 bullet character
!byte %10000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00100100
!byte %11111111
!byte %00100100
!byte %11111111
!byte %00100100
!byte %00100100

DATA_CUSTOM_CHAR_UNKNOWN
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00100100
!byte %11111111
!byte %00100100
!byte %11111111
!byte %00100100
!byte %00100100

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00100000
!byte %01110000
!byte %00100000
!byte %01110000
!byte %10101000

!byte %10101000
!byte %00100000
!byte %01010000
!byte %01010000
!byte %01010000
!byte %11011000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00001100
!byte %00011110
!byte %00110011
!byte %00011110
!byte %00001100
!byte %01111111
!byte %01011110

!byte %01011110
!byte %01011110
!byte %00011110
!byte %00011110
!byte %00011110
!byte %00001100
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %10000000
!byte %10000000

!byte %10000000
!byte %10000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %10000000

!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;24 robot character head 1
!byte %00000000
!byte %00011000
!byte %00111100
!byte %01100110
!byte %00111100
!byte %00011000
!byte %11111111
!byte %10111101

;25 robot character tail 1
!byte %10111101
!byte %10111101
!byte %00111100
!byte %00111100
!byte %00111100
!byte %00011000
!byte %00000000
!byte %00000000

data_player_custom_characters
;26 player character head 1
!byte %00000000
!byte %00001000
!byte %00011100
!byte %00001000
!byte %00011100
!byte %00101010
!byte %00101010
!byte %00001000

;27 player character tail 1
!byte %00010100
!byte %00010100
!byte %00010100
!byte %00110110
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;28 block character used for walls
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

;29 robot character head 2
!byte %00000000
!byte %00011000
!byte %00111100
!byte %01100110
!byte %00111100
!byte %00011000
!byte %11111111
!byte %10111101

;30 robot character tail 2
!byte %10111101
!byte %10111101
!byte %00111100
!byte %00111100
!byte %00111100
!byte %00011000
!byte %00000000
!byte %00000000

;31 gate character used for blocking entrance
!byte %00000000
!byte %01010100
!byte %00101010
!byte %01010100
!byte %00101010
!byte %01010100
!byte %00101010
!byte %00000000

data_score_custom_characters
;32 score character (is redefined when score is plotted on screen)
!byte %00100000
!byte %00110000
!byte %00110000
!byte %00100000
!byte %00000101
!byte %00000101
!byte %00100000
!byte %00110001

;33 score character (is redefined when score is plotted on screen)
!byte %00111001
!byte %00000001
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;34 score character (is redefined when score is plotted on screen)
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;35 score character (is redefined when score is plotted on screen)
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;36 reverse hash
!byte %11011011
!byte %11011011
!byte %00000000
!byte %11011011
!byte %11011011
!byte %00000000
!byte %11011011
!byte %11011011

;37 player lives (is redefined when score is plotted on screen)
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
