INCLUDE "main.inc"
INCLUDE "hardware.inc"

; Id for the upper left hero tile.
DEF HERO_TILE1 EQU $00

; Id for the upper right hero tile.
DEF HERO_TILE2 EQU $01

; Id for the lower left hero tile.
DEF HERO_TILE3 EQU $10

; ID for the lower right hero tile.
DEF HERO_TILE4 EQU $11

; Horizontal position for the hero on the screen.
DEF HERO_X EQU 40

; Vertical position for the hero on the screen.
DEF HERO_Y EQU 75

; Id for the upper left chest tile.
DEF CHEST_TILE1 EQU $2C

; Id for the upper right chest tile.
DEF CHEST_TILE2 EQU $2D

; Id for the lower left chest tile.
DEF CHEST_TILE3 EQU $3C

; Id for the lower right chest tile.
DEF CHEST_TILE4 EQU $3D

; Horizontal position for the chest on the screen.
DEF CHEST_X EQU 80

; Vertical position for the chest on the screen.
DEF CHEST_Y EQU 87

; Id for the upper left chest tile.
DEF SLIME_TILE1 EQU $0C

; Id for the upper right chest tile.
DEF SLIME_TILE2 EQU $0D

; Id for the lower left chest tile.
DEF SLIME_TILE3 EQU $1C

; Id for the lower right chest tile.
DEF SLIME_TILE4 EQU $1D

; Horizontal position for the chest on the screen.
DEF SLIME_X EQU 120

; Vertical position for the chest on the screen.
DEF SLIME_Y EQU 75

; Number of render frames to wait before animating the character objects
DEF AnimationDelay EQU 30

; Holds the offset used for the animated characters. This value swaps between
; `0` and `2` shifting the tiles used to draw the characters periodically.
DEF bAnimationTileOffset EQU $C010

; The timer used to count frames between swapping the tile offset.
DEF bAnimationTimer EQU $C011

SECTION "Demo 2: Objects", ROM0

; ------------------------------------------------------------------------------
; `binary data ObjectData`
;
; Initial data to load into the
; ------------------------------------------------------------------------------
ObjectData:
  ; 4 object tiles for the hero
  DB HERO_Y,     HERO_X,     HERO_TILE1, 0
  DB HERO_Y,     HERO_X + 8, HERO_TILE2, 0
  DB HERO_Y + 8, HERO_X,     HERO_TILE3, 0
  DB HERO_Y + 8, HERO_X + 8, HERO_TILE4, 0
  ; 4 objects for the treasure chest
  DB CHEST_Y,     CHEST_X,     CHEST_TILE1, 0
  DB CHEST_Y,     CHEST_X + 8, CHEST_TILE2, 0
  DB CHEST_Y + 8, CHEST_X,     CHEST_TILE3, 0
  DB CHEST_Y + 8, CHEST_X + 8, CHEST_TILE4, 0
  ; 4 objects for the slime
  DB SLIME_Y,     SLIME_X,     SLIME_TILE1, 0
  DB SLIME_Y,     SLIME_X + 8, SLIME_TILE2, 0
  DB SLIME_Y + 8, SLIME_X,     SLIME_TILE3, 0
  DB SLIME_Y + 8, SLIME_X + 8, SLIME_TILE4, 0

; Number of bytes of object data to use to initialize the OAM.
DEF len_ObjectData EQU 3 * 4 * 4

; ------------------------------------------------------------------------------
; `func Demo2Init()`
;
; Initializes the demo.
; ------------------------------------------------------------------------------
Demo2Init::
  ; Initialize the animation variables
  ld a, AnimationDelay
  ld [bAnimationTimer], a
  ld a, 0
  ld [bAnimationTileOffset], a
  ; Setup background and object palettes
  ld a, %00100111
  ld [rBGP], a
  ld a, %11100100
  ld [rOBP0], a
  ; Load the RPG character sprites into the dedicate objects page.
  ld hl, $8000
  ld bc, $800
  ld de, TileData + offset_TileRpgObjects
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
  ; Turn on the display and begin rendering only the objects.
  ld a, LCDCF_ON | LCDCF_OBJ8 | LCDCF_OBJON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func Demo2Loop()`
;
; Executes game loop logic for the demo.
; ------------------------------------------------------------------------------
Demo2Loop::
  ld hl, $C400
  inc [hl]
  call AnimateCharacters
  call DMATransfer
  ret

; ------------------------------------------------------------------------------
; `func AnimateCharacters()`
;
; Handles basic keyframe animation for the hero and the slime.
; ------------------------------------------------------------------------------
AnimateCharacters:
  ; Decrement the animation timer and check if we need to update the frame
  ld hl, bAnimationTimer
  dec [hl]
  ld a, [hl]
  or a, 0
  jr z, .next_frame
  ret
.next_frame
  ; Reset the animation timer
  ld a, AnimationDelay
  ld [hl], a
  ; Toggle the tile offset between 0 and 2
  ld a, [bAnimationTileOffset]
  xor a, 2
  ld [bAnimationTileOffset], a
  ld b, a
  ; Swap out the object tiles based on the new offset
  ld a, HERO_TILE1
  add a, b
  ld [$C100 + 0*4 + 2], a
  ld a, HERO_TILE2
  add a, b
  ld [$C100 + 1*4 + 2], a
  ld a, HERO_TILE3
  add a, b
  ld [$C100 + 2*4 + 2], a
  ld a, HERO_TILE4
  add a, b
  ld [$C100 + 3*4 + 2], a
  ld a, SLIME_TILE1
  add a, b
  ld [$C100 + 8*4 + 2], a
  ld a, SLIME_TILE2
  add a, b
  ld [$C100 + 9*4 + 2], a
  ld a, SLIME_TILE3
  add a, b
  ld [$C100 + 10*4 + 2], a
  ld a, SLIME_TILE4
  add a, b
  ld [$C100 + 11*4 + 2], a
  ret
