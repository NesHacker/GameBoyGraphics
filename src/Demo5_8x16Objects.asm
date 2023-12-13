INCLUDE "main.inc"
INCLUDE "hardware.inc"

; The current animation frame for the coins.
DEF bAnimationFrame EQU $C010

; Timer that counts down to frame transitions.
DEF bTimer EQU $C011

; Delay between animation frames for the coins.
DEF FrameDelay EQU 14

SECTION "Demo 5: 8x16 Objects", ROM0

; ------------------------------------------------------------------------------
; `func Demo5Init()`
;
; Initializes the demo.
; ------------------------------------------------------------------------------
Demo5Init::
  ; Initialize the animations
  ld a, FrameDelay
  ld [bTimer], a
  ld a, 0
  ld [bAnimationFrame], a
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call MemCopy
  ; Load the 8x16 object tiles into the dedicated object page.
  ld hl, $8000
  ld bc, $800
  ld de, TileData + offset_Tiles8x16
  call MemCopy
  ; Clear the background graphics
  ld hl, $9800
  ld bc, 32 * 32
  call MemClear
  ; Copy the Initial OAM data
  ld hl, pSpriteOAM
  ld bc, len_ObjectData
  ld de, ObjectData
  call MemCopy
  call DMATransfer
  ; Turn on the display and begin rendering the background.
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJ16 | LCDCF_OBJON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func Demo5Loop()`
;
; Executes game loop logic for the demo.
; ------------------------------------------------------------------------------
Demo5Loop::
  ld a, [bJoypadPressed]
  and a, BUTTON_SELECT | BUTTON_B
  jr z, .continue
.to_demo_select
  call LoadDemoSelect
  ret
.continue
  ld a, [bTimer]
  dec a
  jr nz, .done
.update_frame
  ld a, [bAnimationFrame]
  inc a
  and %11
  ld [bAnimationFrame], a
  ld b, 0
  ld c, a
  ld hl, ObjectFrames
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*0], a
  ld bc, 4
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*1], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*2], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*3], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*4], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*5], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*6], a
  add hl, bc
  ld a, [hl]
  ld [pSpriteOAM + 2 + 4*7], a
  ld a, FrameDelay
.done
  ld [bTimer], a

  ld bc, 4
  ld hl, pSpriteOAM

  inc [hl]
  add hl, bc
  inc [hl]

  add hl, bc
  dec [hl]
  add hl, bc
  dec [hl]

  add hl, bc
  inc [hl]
  add hl, bc
  inc [hl]

  add hl, bc
  dec [hl]
  add hl, bc
  dec [hl]

  call DMATransfer
  ret

; Initial object data for the demo
ObjectData:
  DB 75, 32, $00, %00000000
  DB 75, 40, $02, %00000000
  DB 95, 62, $04, %00000000
  DB 95, 70, $06, %00000000
  DB 75, 92, $08, %00000000
  DB 75, 100, $0A, %00000000
  DB 95, 122, $04, %00000000
  DB 95, 130, $06, %00000000

; Number of objects that will be rendered.
DEF num_Objects EQU 8

; Number objects in the initial object data.
DEF len_ObjectData EQU 4 * num_Objects

; Animation tile frames for each object
ObjectFrames:
  DB $00, $04, $08, $04
  DB $02, $06, $0A, $06
  DB $04, $08, $04, $00
  DB $06, $0A, $06, $02
  DB $08, $04, $00, $04
  DB $0A, $06, $02, $06
  DB $04, $00, $04, $08
  DB $06, $02, $06, $0A
