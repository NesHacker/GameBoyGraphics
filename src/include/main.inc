; ------------------------------------------------------------------------------
; `macro WaitForVblank()`
;
; Loops until the LCD enters the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblank
: ld a, [rLY]
  cp a, 144
  jr c, :-
ENDM

; ------------------------------------------------------------------------------
; `macro WaitForVblankEnd()`
;
; Loops until the LCD exits the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblankEnd
: ld a, [rLY]
  cp 144
  jr nc, :-
ENDM

; ------------------------------------------------------------------------------
; `func DMATransfer()`
;
; Transfers sprites from WRAM to VRAM using the DMA.
; ------------------------------------------------------------------------------
DEF DMATransfer EQU $FF80

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------

; Holds the current game state. See the `STATE_*` variables in `main.inc`.
DEF bGameState EQU $C000

; Holds the cursor position for the demo select menu.
DEF bDemoSelectCursor EQU $C001

; Bitfield that stores current buttons being pressed on the Game Boy's joypad.
;
; - Bit 0 (`BUTTON_RIGHT`) - Right D-PAD
; - Bit 1 (`BUTTON_LEFT`) - Left D-PAD
; - Bit 2 (`BUTTON_LEFT`) - Up D-PAD
; - Bit 3 (`BUTTON_LEFT`) - Down D-PAD
; - Bit 4 (`BUTTON_A`) - A
; - Bit 5 (`BUTTON_B`) - B
; - Bit 6 (`BUTTON_SELECT`) - Select
; - Bit 7 (`BUTTON_START`) - Start
DEF bJoypadDown EQU $C020

; Bitfield that stores the buttons that were pressed as of the last joypad read.
;
; - Bit 0 (`BUTTON_RIGHT`) - Right D-PAD
; - Bit 1 (`BUTTON_LEFT`) - Left D-PAD
; - Bit 2 (`BUTTON_LEFT`) - Up D-PAD
; - Bit 3 (`BUTTON_LEFT`) - Down D-PAD
; - Bit 4 (`BUTTON_A`) - A
; - Bit 5 (`BUTTON_B`) - B
; - Bit 6 (`BUTTON_SELECT`) - Select
; - Bit 7 (`BUTTON_START`) - Start
DEF bJoypadPressed EQU $C021

; WRAM location for Object (Sprite) OAM data that is transferred to VRAM via DMA
; at the end of each frame during the VBLANK period.
DEF pSpriteOAM EQU $C100

; ------------------------------------------------------------------------------
; Constants
; ------------------------------------------------------------------------------

; Button mask for the right D-PAD button.
DEF BUTTON_RIGHT  EQU 1 << 0

; Button mask for the left D-PAD button.
DEF BUTTON_LEFT   EQU 1 << 1

; Button mask for the up D-PAD button.
DEF BUTTON_UP     EQU 1 << 2

; Button mask for the down D-PAD button.
DEF BUTTON_DOWN   EQU 1 << 3

; Button mask for the A button.
DEF BUTTON_A      EQU 1 << 4

; Button mask for the B button.
DEF BUTTON_B      EQU 1 << 5

; Button mask for the select button.
DEF BUTTON_SELECT EQU 1 << 6

; Button mask for the start button.
DEF BUTTON_START  EQU 1 << 7

; 128 tiles that hold common background elements such as colors and window
; borders along with a limited ASCII font.
DEF offset_TilesCommon EQU 0

; Holds the graphics used on the title and main menu screens.
DEF offset_TilesTitle EQU $800

; Tiles for building RPG maps in various demos.
DEF offset_TilesRpgMaps EQU $1000

; Tiles used to draw RPG objects and characters.
DEF offset_TilesRpgObjects EQU $1800

; Tiles used for the demo select menu.
DEF offset_TilesDemoSelect EQU $2000

; Tiles for the 8x16 object mode demo
DEF offset_Tiles8x16 EQU $2800

; Game state representing the title screen.
DEF STATE_TITLE       EQU 0

; Game state representing the demo selection screen.
DEF STATE_DEMO_SELECT EQU 1

; Game state representing the background demo.
DEF STATE_DEMO1       EQU 2

; Game state representing the objects demo.
DEF STATE_DEMO2       EQU 3

; Game state representing the window demo.
DEF STATE_DEMO3       EQU 4

; Game state representing the scrolling demo.
DEF STATE_DEMO4       EQU 5

; Game state representing the 8x16 objects demo.
DEF STATE_DEMO5       EQU 6
