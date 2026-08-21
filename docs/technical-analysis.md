# Amok technical analysis

Amok is a compact 6502 game for the unexpanded Commodore VIC-20. The source can also build an 8K+
version whose code is relocated while preserving the original game bytes and behaviour. This document
provides the architectural context needed before reading the individual routines.

## Program structure

The BASIC stub enters `start_of_program`, which displays the preloaded title, accepts the difficulty
selection and changes from the VIC ROM character set to the game's custom characters. Gameplay then
uses one main loop, with room changes returning through `start_new_room` to reinitialise the objects.

```text
BASIC SYS stub
    |
    v
start_of_program
    -> initialise_title_screen_and_wait_for_start
       -> poll_difficulty_selection until F7
    -> select custom character memory
    |
    v
start_new_room
    -> setup_robots_and_player
       -> run_room_transition_pause
    |
    v
main_frame_loop
    -> build_next_frame_in_hidden_buffer
       -> draw_screen_and_start_game_action
          -> clear hidden screen and colour RAM
          -> draw borders, exits, inner walls and entrance gate
          -> handle_robot_player_and_bullets
          -> get_user_input
          -> handle_player_death
          -> update_object_movement_and_destruction
          -> update_robot_movement_scheduler
          -> render_score_and_lives
    -> expose the completed screen buffer
    -> update_soprano_sound
    -> update_robot_firing
    -> handle_player_room_exit
       -> main_frame_loop, or start_new_room for the next room
```

The frame renderer draws current object positions before input and movement update the records. Those
new positions therefore appear in the following frame. Collision detection occurs while object
bitmaps are composited, and death handling runs before the later movement/destruction update.

## Memory maps

The two builds keep custom characters and both runtime screen buffers at the same addresses. Code is
reordered around those fixed VIC-visible regions for the expanded configuration.

| Purpose | Unexpanded | 8K+ expanded |
|---|---:|---:|
| BASIC stub | `$1001-$100d` | `$1201-$120d` |
| `code1.asm` | `$100e-$15ff` | `$120e-$17ff` |
| `code2.asm` | `$1600-$17ff` | `$1a00-$1bff` |
| Custom characters (`spr.asm`) | `$1800-$192f` | `$1800-$192f` |
| Expanded-layout helper | — | `$19f8-$19ff` |
| `code3.asm` | `$1930-$1bff` | `$2030-$22ff` |
| Screen buffer 1 / title | `$1c00-$1dff` | `$1c00-$1dff` |
| Screen buffer 2 at runtime | `$1e00-$1fff` | `$1e00-$1fff` |
| Colour RAM for buffer 1 | `$9400-$95ff` | `$9400-$95ff` |
| Colour RAM for buffer 2 | `$9600-$97ff` | `$9600-$97ff` |

`screen.asm` contains 513 bytes starting at `$1c00`. The visible title occupies 506 cells; seven
trailing bytes preserve the original file, with the final byte at `$1e00`. The rest of screen buffer 2
is runtime storage rather than meaningful preloaded display data.

In the expanded build, padding after `spr.asm` places `extras_8k` at `$19f8` and `code2.asm` at
`$1a00`. More padding after the screen data reserves the second buffer and places `code3.asm` at
`$2030`. The helper establishes the VIC memory configuration which the unexpanded machine already has
at power-on.

### Important low-memory state

| Address | Purpose |
|---:|---|
| `$60` | High byte of the currently selected hidden draw buffer |
| `$61-$62` | Calculated screen/map pointer |
| `$63-$70` | Heavily reused routine-local workspace with contextual aliases |
| `$71` | Room-layout offset: `$00`, `$10`, `$20` or `$30` |
| `$72` | Entrance edge: left, top, right or bottom |
| `$73` | Timed sound countdown |
| `$74-$75` | Four-digit packed-BCD score |
| `$76` | Remaining lives |
| `$77-$78` | Active difficulty delay and title selection |
| `$a2` | KERNAL low jiffy-clock byte |
| `$a3-$a7` | Input, robot timing and direction-selection state |

The aliases at `$63-$70` are intentionally overloaded. They represent pointers, counters, coordinate
deltas and sprite-compositing state in different routines and are not preserved across calls.

## Screen buffering and frame construction

The game rebuilds a complete 22-by-23 character display every frame. Drawing directly into the
visible page would reveal the clear-and-redraw sequence, so `$1c00` and `$1e00` alternate as visible
and hidden buffers. VIC register `$9002` bit 7 supplies the screen-address bit which selects between
them. The page is exposed only after construction finishes.

`build_next_frame_in_hidden_buffer` self-modifies the high bytes of the fast absolute stores used for
screen clearing and border drawing. Other routines use `draw_screen_high` and indirect pointers.
Colour RAM follows the same page selection: adding `$78` to screen page `$1c` or `$1e` gives colour
page `$94` or `$96`.

Both screens share the custom-character data at `$1800`. Double buffering therefore protects screen
codes and colours, but not bitmap definitions. This matters for the software sprites and for the score
digits, whose character images are rewritten while either page may reference them.

## Custom characters and software sprites

The VIC-20 has no hardware sprites. Amok obtains pixel-positioned objects by treating custom character
RAM as a set of reusable bitmap workspaces:

- Characters 24-31 contain aligned robots, the player, walls and the entrance gate.
- A character-aligned robot takes a fast path which writes its existing head/body codes directly.
- Misaligned robots, the player and bullets are shifted into private dynamic-character workspaces.
- A full-size object can cover two columns by three character rows, requiring six generated glyphs.
- Bullets use one generated character each.

`plot_software_sprite` clears the object's workspace, enters a compact self-selected shift sequence
according to its pixel X offset, and lets consecutive bitmap rows flow through vertically adjacent
characters. `composite_software_sprite_cell` merges the result with the bitmap already represented by
the destination screen code. Pixel overlap during that merge is also the collision detector, so
drawing, background preservation and collision handling are part of one operation.

## Rooms, objects and progression

Each room record is 16 bytes: eight packed wall positions followed by eight packed robot positions.
For each entry, the high nibble is a base column and the low nibble a base row; the entry number is
added to both. The eight walls alternate horizontal and vertical orientation and are five characters
long. Zero entries omit a wall without disturbing that alternation.

The shared data page contains six room records: four active rooms and two alternatives. On a nonfinal
death, a jiffy-derived selector exchanges one active room with the record 32 bytes later. This mutates
the data in place, so shuffled layouts persist across later lives and new games.

The remainder of that page is twenty eight-byte object records:

| Record offsets | Contents |
|---:|---|
| `96-159` | Eight active robots |
| `160` | Ninth, normally inactive robot-shaped record |
| `168` | Player |
| `176-247` | Nine corresponding robot bullets |
| `248` | Player bullet |

Every record uses the same column, row, status, colour, source character, height, workspace-offset and
bitmap-row fields. Status is context-dependent: normally it is an active-low movement direction, but
a yellow object uses it as its destruction countdown. A row of zero marks an object inactive.

Leaving a room advances `next_screen_offset` by 16. After the fourth room reaches offset `$40`, the
game awards 100 points, returns to room zero and decreases `game_level`; because that value is a delay,
decreasing it makes robots faster. It is clamped at one.

## Robot movement and firing

Robot movement and firing use separate round-robin schedulers. Only one robot is selected when each
scheduler expires, and both selectors persist across rooms and lives.

Movement is assigned only when a robot reaches an eight-pixel character boundary. The robot first
aims towards the player. A jiffy-based event, or an obstruction in that direction, causes alternative
direction values to be tried. `count_obstacle_at_screen_offset` checks all cells on the leading edge;
screen codes below 7 are passable and codes 7 or above block movement.

Negative neighbour offsets use an unusual biased encoding because their path performs `SEC` before
`ADC`: `$fe` means -1, `$ea` means -21, `$e9` means -22 and `$e8` means -23. This compactly adjusts
both bytes of the screen pointer without a general signed-add routine.

The firing scheduler separately aims the chosen robot and permits vertical, horizontal or sufficiently
close 45-degree shots. Each shooter has a corresponding bullet record; an occupied bullet slot causes
that firing opportunity to be lost rather than passed to another robot.

## Input, score and sound

Keyboard and joystick input are normalised into the same active-low five-bit value: fire, left, down,
up and right. The keyboard uses U/H/J/N plus Shift or Control for fire. Input is sampled every three
frames after the first poll, whose timing depends on the pre-existing value of `$a3`.

The four score digits occupy two packed binary-coded decimal bytes. Decimal-mode additions award
5/15/25/35 points for robots and 100 points after four rooms. Reaching exactly 1500 awards an extra
life. The HUD copies only the four required digit glyphs from the reversed VIC ROM character set into
characters 32-35; character 36 is a fixed `#`, and character 37 is redefined as the lives digit. This
saves character RAM compared with retaining all ten numeral glyphs.

Sound uses VIC voice 3 for decaying bullet tones and table-driven hit/bonus effects. Robot hits take
priority through `timed_sound_countdown`; otherwise the bullet frequency falls once per frame until it
is silenced. Voice 4 is written during room setup but remains disabled because bit 7 is clear.

## Preserved anomalies and implementation quirks

The disassembly deliberately retains original behaviour so the rebuilt programs remain byte-identical:

- `start_of_program` initialises `game_select_level` but does not copy it to `game_level`. Pressing F7
  without first cycling F1 therefore leaves the first game's active difficulty dependent on `$77`.
- `draw_screen_high` is not explicitly initialised. An initial value of `$1e` makes the first frame
  build in the visible page; later frames alternate correctly regardless.
- The room-transition delay adds 24 with carry already set by its sole caller, producing 25 jiffies.
- Robot firing performs `ADC`/`SBC` without fully normalising carry, introducing a one-frame timing
  variation dependent on the incoming carry state.
- A second robot-aim attempt using a wider tolerance is unreachable for an active robot because the
  first aiming call always returns a nonzero direction.
- The fallback robot-direction seed is masked to four bits rather than restricted to the eight valid
  direction masks. The tables safely define all 16 entries, including duplicate or stationary cases.
- The ninth robot-shaped record and its bullet are processed by general loops but normally remain
  inactive.
- One object-record height field is stored but never read. The title routine also writes an unused
  second copy of the starting lives, and collision handling writes a marker at `$ad` which is never
  subsequently read.
- Nine bytes before the entrance tables have no identified references and are retained as original
  data rather than assigned a speculative purpose.
- During difficulty selection, the selected digit is also stored in `score_tens`. This is cleared
  before the first game, but during game over it makes the chosen option appear in the score display.

## Source layout and verification

`main.asm` supplies hardware symbols, zero-page aliases, constants and the conditional source layout.
`code1.asm`, `code2.asm` and `code3.asm` contain executable code and tightly coupled data; `spr.asm`
contains custom-character bitmaps/workspaces; and `screen.asm` contains the preloaded title image.

`a_build.bat` assembles both layouts, adds their two-byte PRG load headers and performs binary
comparisons against the original unexpanded program and the tested expanded version. Address-sensitive
self-modifying code and deliberate data aliases make those comparisons especially important after any
source change.
