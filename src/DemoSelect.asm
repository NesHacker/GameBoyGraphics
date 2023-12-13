INCLUDE "main.inc"
INCLUDE "hardware.inc"

; Number of demos that can be selected.
def NUM_DEMOS equ 5

; Y-Position for the cursor when selecting the first demo
def CURSOR_Y_START EQU 64

SECTION "Demo Select", ROM0

; ------------------------------------------------------------------------------
; `func DemoSelectInit()`
;
; Initializes the demo select.
; ------------------------------------------------------------------------------
DemoSelectInit::
  ; Initialize the objects we want to use for the demo
  ld bc, len_ObjectData
  ld de, ObjectData
  ld hl, pSpriteOAM
  call CopyData
  ; Load the demo select tiles into the shared page.
  ld hl, $8800
  ld bc, $800
  ld de, TileData + offset_TilesDemoSelect
  call CopyData
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call CopyData
  ; Draw the background for the select screen
  ld hl, $9800
  ld bc, 32 * 32
  ld de, DemoSelectTilemap
  call CopyData
  ; Turn on the display and begin rendering the background and objects.
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJ8 | LCDCF_OBJON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func DemoSelectLoop()`
;
; Executes game loop logic for the demo select.
; ------------------------------------------------------------------------------
DemoSelectLoop::
  ld a, [bJoypadPressed]
  ld b, a
  and a, BUTTON_A | BUTTON_START
  jr nz, .load_demo
  ld a, b
  and a, BUTTON_B | BUTTON_SELECT
  jr nz, .return_to_title
.continue
  call HandleCursor
  call DMATransfer
  ret
.load_demo
  ld a, [bDemoSelectCursor]
  cp a, 4
  jr z, .demo5
  cp a, 3
  jr z, .demo4
  cp a, 2
  jr z, .demo3
  cp a, 1
  jr z, .demo2
.demo1
  call LoadDemo1
  ret
.demo2
  call LoadDemo2
  ret
.demo3
  call LoadDemo3
  ret
.demo4
  call LoadDemo4
  ret
.demo5
  call LoadDemo5
  ret
.return_to_title
  call LoadTitle
  ret

; ------------------------------------------------------------------------------
; `func HandleCursor()`
;
; Reads joypad input and updates the cursor position.
; ------------------------------------------------------------------------------
HandleCursor:
  ld a, [bJoypadPressed]
  ld b, a
  and a, BUTTON_UP
  jr nz, .up
  ld a, b
  and a, BUTTON_DOWN
  jr z, .continue
.down
  ld a, [bDemoSelectCursor]
  inc a
  cp a, NUM_DEMOS
  jr nz, :+
  ld a, 0
: ld [bDemoSelectCursor], a
  jr .continue
.up
  ld a, [bDemoSelectCursor]
  dec a
  cp a, %11111111
  jr nz, :+
  ld a, NUM_DEMOS - 1
: ld [bDemoSelectCursor], a
.continue
  ld a, [bDemoSelectCursor]
  sla a
  sla a
  sla a
  add CURSOR_Y_START
  ld [pSpriteOAM], a
  ret

; ------------------------------------------------------------------------------
; `binary data ObjectData`
;
; Initial OAM data for the demo select screen.
; ------------------------------------------------------------------------------
ObjectData:
  DB CURSOR_Y_START, 40, $8B, 0

; Number of object data bytes used by the demo select screen.
DEF len_ObjectData EQU 4

; ------------------------------------------------------------------------------
; `binary data DemoSelectTilemap`
;
; Background tilemap for the demo select screen.
; ------------------------------------------------------------------------------
DemoSelectTilemap: INCBIN "bin/DemoSelect_32x32.tilemap"
