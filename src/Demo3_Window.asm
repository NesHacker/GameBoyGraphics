INCLUDE "main.inc"
INCLUDE "hardware.inc"

; State used to indicate that the window is closed.
DEF STATE_CLOSED EQU 0

; State used to indicate that window is opening.
DEF STATE_OPENING EQU 1

; State used to indicate that the window is open.
DEF STATE_OPEN EQU 2

; State used to indicate that the window is closing.
DEF STATE_CLOSING EQU 3

; Y position for the window when it's fully open.
DEF WINDOW_OPEN_Y EQU 0

; Y position for the window when it's fully closed.
DEF WINDOW_CLOSED_Y EQU 128

; Holds the current window state.
DEF bWindowState EQU $C010

; Current Y position for the window.
DEF bWindowY EQU $C012

SECTION "Demo 3: The Window", ROM0

; ------------------------------------------------------------------------------
; `func Demo3Init()`
;
; Initializes the demo.
; ------------------------------------------------------------------------------
Demo3Init::
  ; Setup the window animation state
  ld a, STATE_CLOSED
  ld [bWindowState], a
  ld a, WINDOW_CLOSED_Y
  ld [bWindowY], a
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call CopyData
  ; Draw the background graphics
  ld bc, 32 * 32
  ld de, BackgroundTiles
  ld hl, $9800
  call CopyData
  ; Draw the window graphics
  ld bc, 32 * 32
  ld de, WindowTiles
  ld hl, $9C00
  call CopyData
  ; Set the window x & y position
  ld a, 7
  ld [rWX], a
  ld a, [bWindowY]
  ld [rWY], a
  ; Turn on the display and begin rendering the background.
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_WINON | LCDCF_WIN9C00
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func Demo3Loop()`
;
; Executes game loop logic for the demo.
; ------------------------------------------------------------------------------
Demo3Loop::
  ld a, [bJoypadPressed]
  and a, BUTTON_SELECT | BUTTON_B
  jr z, .continue
.to_demo_select
  call LoadDemoSelect
  ret
.continue
  ; Update the window position
  ld a, [bWindowY]
  ld [rWY], a
  ; Handle behavior based on window state
  ld a, [bWindowState]
  cp a, STATE_CLOSED
  jr z, .closed
  cp a, STATE_OPENING
  jr z, .opening
  cp a, STATE_CLOSING
  jr z, .closing
.open
  ld a, [bJoypadPressed]
  and a, BUTTON_START
  jr nz, .toggle_closing
  ret
.toggle_closing
  ld a, STATE_CLOSING
  ld [bWindowState], a
  ret
.opening
  ld a, [bWindowY]
  dec a
  ld [bWindowY], a
  cp a, WINDOW_OPEN_Y
  jr z, .finish_opening
  ret
.finish_opening
  ld a, STATE_OPEN
  ld [bWindowState], a
  ret
.closing
  ld a, [bWindowY]
  inc a
  ld [bWindowY], a
  cp a, WINDOW_CLOSED_Y
  jr z, .finish_closing
  ret
.finish_closing
  ld a, STATE_CLOSED
  ld [bWindowState], a
  ret
.closed
  ld a, [bJoypadPressed]
  and a, BUTTON_START
  jr nz, .toggle_opening
  ret
.toggle_opening
  ld a, STATE_OPENING
  ld [bWindowState], a
  ret

; Tiles to draw in the normal background.
BackgroundTiles: INCBIN "bin/WindowDemoBG_32x32.tilemap"

; Tiles to draw in the window.
WindowTiles: INCBIN "bin/WindowDemoWindow_32x32.tilemap"
