INCLUDE "main.inc"
INCLUDE "hardware.inc"

; Horizontal Scroll Position (fixed point 8.8)
DEF fScrollX EQU $C010

; Vertical Scroll Position (fixed point 8.8)
DEF fScrollY EQU $C012

; Amount to scroll each frame (fixed point .8)
DEF SCROLL_PER_FRAME EQU $F0


DEF PalAnimationDelay EQU 20

DEF bPalTimer EQU $C014
DEF bPalFrame EQU $C015

SECTION "Demo 4: Scrolling Map", ROM0

; Object data for glowing cardinal arrows
ObjectData:
  DB 18, 80, $40, %0000_0000
  DB 18, 88, $40, %0010_0000
  DB 82, 10, $41, %0000_0000
  DB 90, 10, $41, %0100_0000
  DB 150, 80, $40, %0100_0000
  DB 150, 88, $40, %0110_0000
  DB 82, 158, $41, %0010_0000
  DB 90, 158, $41, %0110_0000

DEF len_ObjectData EQU 8 * 4

; Frame values for the animated OAM palette
PaletteFrames:
  DB %11_10_01_00
  DB %11_11_01_00
  DB %11_10_01_00
  DB %11_01_01_00

; ------------------------------------------------------------------------------
; `func Demo4Init()`
;
; Initializes the demo.
; ------------------------------------------------------------------------------
Demo4Init::
  ; Initialize Palettes & Animation
  ld a, [PaletteFrames]
  ld [rOBP0], a
  ld a, 0
  ld [bPalFrame], a
  ld a, PalAnimationDelay
  ld [bPalTimer], a
  ; Initialize the scroll position
  ld a, 0
  ld [fScrollX], a
  ld [fScrollX + 1], a
  ld [fScrollY], a
  ld [fScrollX + 1], a
  ; Load the RPG character sprites into the dedicate objects page.
  ld hl, $8000
  ld bc, $800
  ld de, TileData + offset_TilesRpgObjects
  call CopyData
  ; Load the RPG map tiles into the share page.
  ld hl, $8800
  ld bc, $800
  ld de, TileData + offset_TilesRpgMaps
  call CopyData
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call CopyData
  ; Load the RPG map into the background
  ld hl, $9800
  ld bc, 32 * 32
  ld de, RpgMap
  call CopyData
  ; Clear the object data in RAM (fill with all $FF)
  ld hl, $C100
  ld bc, 40 * 4
  ld d, $FF
  call FillData
  ; Initialize the objects we want to use for the demo
  ld bc, len_ObjectData
  ld de, ObjectData
  ld hl, $C100
  call CopyData
  ; Transfer over the sprites
  call DMATransfer
  ; Turn on the display and begin rendering the background.
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJ8 | LCDCF_OBJON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func Demo4Loop()`
;
; Executes game loop logic for the demo.
; ------------------------------------------------------------------------------
Demo4Loop::
  ld a, [bJoypadPressed]
  and a, BUTTON_SELECT | BUTTON_B
  jr z, .continue
.to_demo_select
  call LoadDemoSelect
  ret
.continue
  call AnimatePalettes
  call UpdateMapScroll
  call DMATransfer
  ret

; ------------------------------------------------------------------------------
; `func AnimatePalettes()`
;
; Animates the OAM palettes to make the cardinal arrows appear to glow.
; ------------------------------------------------------------------------------
AnimatePalettes:
  ld hl, bPalTimer
  dec [hl]
  ld a, [hl]
  or a, 0
  jr z, .next_frame
  ret
.next_frame
  ld a, PalAnimationDelay
  ld [hl], a
  ld a, [bPalFrame]
  inc a
  cp a, 4
  jr nz, .set_palette
  ld a, 0
.set_palette
  ld [bPalFrame], a
  ld b, 0
  ld c, a
  ld hl, PaletteFrames
  add hl, bc
  ld a, [hl]
  ld [rOBP0], a
  ret

; ------------------------------------------------------------------------------
; `func UpdateMapScroll()`
;
; Checks the D-PAD for input and scrolls the map based on the directions the
; user is pressing.
; ------------------------------------------------------------------------------
UpdateMapScroll:
  ; Check for left & right input
  ld a, [bJoypadDown]
  ld b, a
  and a, BUTTON_LEFT
  jr nz, .left
  ld a, b
  and a, BUTTON_RIGHT
  jr z, .check_up_and_down
.right
  ld a, [fScrollX + 1]
  add a, SCROLL_PER_FRAME
  ld [fScrollX + 1], a
  ld a, [fScrollX]
  adc a, 0
  ld [fScrollX], a
  jr .check_up_and_down
.left
  ld a, [fScrollX + 1]
  sub a, SCROLL_PER_FRAME
  ld [fScrollX + 1], a
  ld a, [fScrollX]
  sbc a, $0
  ld [fScrollX], a
.check_up_and_down
  ld a, b
  and a, BUTTON_UP
  jr nz, .up
  ld a, b
  and a, BUTTON_DOWN
  jr z, .update_scroll
.down
  ld a, [fScrollY + 1]
  add a, SCROLL_PER_FRAME
  ld [fScrollY + 1], a
  ld a, [fScrollY]
  adc a, 0
  ld [fScrollY], a
  jr .update_scroll
.up
  ld a, [fScrollY + 1]
  sub a, SCROLL_PER_FRAME
  ld [fScrollY + 1], a
  ld a, [fScrollY]
  sbc a, $0
  ld [fScrollY], a
.update_scroll
  ld a, [fScrollX]
  ld [rSCX], a
  ld a, [fScrollY]
  ld [rSCY], a
  ret

; ------------------------------------------------------------------------------
; `binary data RpgMap`
;
; Tilemap for the RPG world map that's displayed in the demo.
; ------------------------------------------------------------------------------
RpgMap: INCBIN "RPGMap_32x32.tilemap"
