;_SCREEN_ADDR = $1c00 to $1e01 (7168 to 7681)
;64 x 8 = 512 + 1 bytes
;The title screen text is already in screen memory on program load and is only displayed once
;The screen then gets used for the game display
_SCREEN_ADDR
!scr "        amok!         "
!scr "                      "
!scr "    copyright 1981    "
!scr "   by roger merritt   "
!scr "                      "
!scr "clear the station of  "
!scr "crazy robots that have"
!scr "run amok! use joystick"
!scr "or keys u,h,j,n and   "
!scr "shift to play.        "
!scr "                      "
!scr "green robots  5 points"
!scr "blue  robots 15 points"
!scr "red   robots 25 points"
!scr "black robots 35 points"
!scr "                      "
!scr "extra man at 1500!    "
!scr "bonus points after    "
!scr "fourth floor!         "
!scr "                      "
!scr "use function key #8 to"
!scr "start.                "
!scr "         option 1     "
!byte $20, $aa, $aa, $aa, $aa, $aa, $20

end_screen