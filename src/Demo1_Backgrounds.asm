INCLUDE "main.inc"
INCLUDE "hardware.inc"

SECTION "Demo 1: Backgrounds", ROM0

; ------------------------------------------------------------------------------
; `binary data (string) str_HelloWorld`
;
; Bytes for the string to print to the background. We can easily print strings
; by converting the default ASCII character values directly to tiles since the
; default background graphics are set up to be interpreted this way.
;
; In other words: each of the letters is represented by a numeric ASCII value
; and the background tiles are set up to draw the correct character based on
; ASCII standard.
; ------------------------------------------------------------------------------
str_HelloWorld: DB "HELLO WORLD!", 0

; ------------------------------------------------------------------------------
; `func Demo1Init()`
;
; Initializes the demo.
; ------------------------------------------------------------------------------
Demo1Init::
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call MemCopy
  ; Clear the background graphics
  ld hl, $9800
  ld bc, 32 * 32
  call MemClear
  ; Draw the message to the screen
  call DrawMessage
  ; Turn on the display and begin rendering the background.
  ld a, LCDCF_ON | LCDCF_BGON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func DrawMessage()`
;
; Loops through the data for the "HELLO WORLD!" message and writes the tiles
; to display the message to the screen by updating the background memory.
; ------------------------------------------------------------------------------
DrawMessage:
  ; The HL register holds the "current" position in video memory.
  ;
  ; Since we want to print the message on row 8 and column 4, here's how the
  ; value is initialized:
  ;
  ;   $9800 (start address for the background data in VRAM)  +
  ;   32 * 8 (skip the data for 8 full rows of 32 tiles) +
  ;   4 (skip the first four tiles of that row to roughly center the message)
  ld hl, $9800 + (32 * 8) + 4
  ; The BC register holds the current position in the "HELLO WORLD!" message
  ; as we work through the loop.
  ld bc, str_HelloWorld
  ; The loop reads the next character in the message, then writes it to VRAM and
  ; increments the position in both VRAM and in the message. If it ever finds a
  ; value of "0" (aka the "null terminator") then it exits the loop.
.printLoop
  ld a, [bc]
  or 0
  jr z, .done
  ld [hli], a
  inc bc
  jr .printLoop
.done
  ret

; ------------------------------------------------------------------------------
; `func Demo1Loop()`
;
; Executes game loop logic for the demo.
; ------------------------------------------------------------------------------
Demo1Loop::
  ld a, [bJoypadPressed]
  and a, BUTTON_SELECT | BUTTON_B
  jr z, .continue
.to_demo_select
  call LoadDemoSelect
  ret
.continue
  ret
