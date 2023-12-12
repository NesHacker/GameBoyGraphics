INCLUDE "main.inc"
INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
  jp Main
  ds $150 - @, 0  ; Header space. RGBFIX requires that it be zero filled.

SECTION "Main", ROM0

; ------------------------------------------------------------------------------
; `func Main()`
;
; Main function for the game. Loads data, initializes RAM, and then enters the
; main game loop.
; ------------------------------------------------------------------------------
Main:
  di

  ; Disable audio
  ld a, 0
  ld [rNR52], a

  ; Disable the LCD
  WaitForVblank
  ld a, 0
  ld [rLCDC], a

  ; Zero out the RAM
  call ClearWRAM

  ; Initialize the DMA routine
  call WriteDMARoutine
  call DMATransfer

  ; Clear the active tileset
  ld hl, $9000
  ld bc, $1800
: ld a, 0
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, :-

  ; Clear both backgrounds
  ld hl, $9800
  ld bc, $800
: ld a, 0
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, :-

  ; Initialize palettes
  ld a, %11100100
  ld [rBGP], a
  ld [rOBP0], a
  ld [rOBP1], a

  ; TODO: Abstract this to handle separate game state controllers for each of
  ;       the demos.
  call TitleScreen.init


; ------------------------------------------------------------------------------
; `func GameLoop()`
;
; The main loop for the game that handles all logic and rendering.
; ------------------------------------------------------------------------------
GameLoop:
  call TitleScreen.loop
  jr GameLoop

; ------------------------------------------------------------------------------
; `func ClearWRAM()`
;
; Clears all working RAM from `$C000` through `$DFFF` by setting each byte to 0.
; ------------------------------------------------------------------------------
ClearWRAM:
  ld bc, $2000
  ld hl, $C000
.clear_loop
  ld a, 0
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, .clear_loop
  ret

; ------------------------------------------------------------------------------
; `func WriteDMARoutine()`
;
; Writes the DMA transfer routine into memory starting at address $FF80. For
; more information see the explanation in the documentation for the
; `DMATransferRoutine` function below.
; ------------------------------------------------------------------------------
WriteDMARoutine:
  ld b, DMATransferRoutineEnd - DMATransferRoutine
  ld de, DMATransferRoutine
  ld hl, DMATransfer
.load_loop
  ld a, [de]
  inc de
  ld [hli], a
  dec b
  jr nz, .load_loop
  ret

; ------------------------------------------------------------------------------
; `func DMATransferRoutine()`
;
; This is the DMA transfer routine used to quickly copy sprite object data from
; working RAM to video RAM.
;
; **IMPORTANT:** This routine should not be called directly, in order to prevent
; bus conflicts the Game Boy only executes instructions between $FF80-$FFFE
; during a DMA transfer. As such this routine is copied to that memory region
; and you should call it using the `DMATransfer` routine label instead.
; ------------------------------------------------------------------------------
DMATransferRoutine:
  di
  ld a, $C1
  ld [rDMA], a
  ld a, 40
.wait_loop
  dec a
  jr nz, .wait_loop
  ei
  ret
DMATransferRoutineEnd:

; ------------------------------------------------------------------------------
; `func ReadJoypad()`
;
; Reads the joypad buttons and saves their values to `bJoypadDown`. Also
; records which buttons were pressed as of this call to `bJoypadPressed`.
; ------------------------------------------------------------------------------
ReadJoypad::
  ; Read the "down" mask from the last frame
  ld a, [bJoypadDown]
  ld c, a
  ; Read the current controller buttons and store them into the "down" mask
  ld a, $20
  ld [rP1], a
  ld a, [rP1]
  ld a, [rP1]
  and $0F
  ld b, a
  ld a, $10
  ld [rP1], a
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  sla a
  sla a
  sla a
  sla a
  or b
  xor $FF
  ld [bJoypadDown], a
  ; Update the "just pressed" mask
  ld b, a
  ld a, c
  xor b
  and b
  ld [bJoypadPressed], a
  ret

; ------------------------------------------------------------------------------
; `func FreeMoveCamera()`
;
; Tests the joypad masks by moving the viewport in response to d-pad input.
; ------------------------------------------------------------------------------
FreeMoveCamera::
  ld hl, rSCX
  ld a, [bJoypadDown]
  ld b, a
  and BUTTON_RIGHT
  jr z, .check_left
  inc [hl]
  inc [hl]
  jr .check_up
.check_left
  ld a, b
  and BUTTON_LEFT
  jr z, .check_up
  dec [hl]
  dec [hl]
.check_up
  ld hl, rSCY
  ld a, b
  and BUTTON_UP
  jr z, .check_down
  ld a, [rSCY]
  cp 0
  jr z, .done
  dec [hl]
  dec [hl]
  jr .done
.check_down
  ld a, b
  and BUTTON_DOWN
  jr z, .done
  ld a, [rSCY]
  cp 112
  jr z, .done
  inc [hl]
  inc [hl]
.done
  ret

SECTION "Tile Data", ROMX, BANK[1]

; ------------------------------------------------------------------------------
; `binary data TileData`
;
; All of the tile data used by various demos in the game. The binary file is
; organized into eight 128 tile pages that can be swapped in and out as needed
; by the game's various demos and screens.
;
; * **Page 1** (`offset_TilesCommon = +$0000`) - Common Backgound & ASCII
; * **Page 2** (`offset_TilesTitle = +$0800`) - Title Screen
; * **Page 3** (`offset_TilesRpgMaps = +$1000`) - RPG Backgrounds
; * **Page 4** (`offset_TileRpgObjects = +$1800`) - RPG Objects
;
; Pages 5 through 8 are left blank so you can experiment with making and loading
; your own graphics.
; ------------------------------------------------------------------------------
TileData:: INCBIN "bin/tiles.gb"