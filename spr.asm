;--------------------------------------------------------------------------------------------------
; VIC custom-character data at $1800-$192f: 38 characters, eight bytes each.
;
; Static characters are followed by runtime workspaces used for shifted software sprites and by the
; six score/lives characters immediately before code3 in the original memory layout.
data_custom_characters
; Character 0: blank.
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

; Character 1: bullet source bitmap.
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

; Adding an object's primary workspace offset to this address reaches the corresponding right-hand
; column, 24 bytes (three characters) beyond its left-hand dynamic-character column.
data_custom_characters_right_column
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

; Character 24: robot head, design 1.
!byte %00000000
!byte %00011000
!byte %00111100
!byte %01100110
!byte %00111100
!byte %00011000
!byte %11111111
!byte %10111101

; Character 25: robot body, design 1.
!byte %10111101
!byte %10111101
!byte %00111100
!byte %00111100
!byte %00111100
!byte %00011000
!byte %00000000
!byte %00000000

data_player_custom_characters
; Character 26: player head.
!byte %00000000
!byte %00001000
!byte %00011100
!byte %00001000
!byte %00011100
!byte %00101010
!byte %00101010
!byte %00001000

; Character 27: player body.
!byte %00010100
!byte %00010100
!byte %00010100
!byte %00110110
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

; Character 28: wall block.
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

; Character 29: robot head, design 2.
!byte %00000000
!byte %00011000
!byte %00111100
!byte %01100110
!byte %00111100
!byte %00011000
!byte %11111111
!byte %10111101

; Character 30: robot body, design 2.
!byte %10111101
!byte %10111101
!byte %00111100
!byte %00111100
!byte %00111100
!byte %00011000
!byte %00000000
!byte %00000000

; Character 31: entrance gate.
!byte %00000000
!byte %01010100
!byte %00101010
!byte %01010100
!byte %00101010
!byte %01010100
!byte %00101010
!byte %00000000

data_score_custom_characters
; Characters 32-35: four score-digit workspaces, redefined every frame from the VIC character ROM.
!byte %00100000
!byte %00110000
!byte %00110000
!byte %00100000
!byte %00000101
!byte %00000101
!byte %00100000
!byte %00110001

; Character 33: score-digit workspace.
!byte %00111001
!byte %00000001
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

; Character 34: score-digit workspace.
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

; Character 35: score-digit workspace.
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

; Character 36: fixed reverse-video `#` lives marker.
!byte %11011011
!byte %11011011
!byte %00000000
!byte %11011011
!byte %11011011
!byte %00000000
!byte %11011011
!byte %11011011

; Character 37: lives-digit workspace, redefined every frame from the VIC character ROM.
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
