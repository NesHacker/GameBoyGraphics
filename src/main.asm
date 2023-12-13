INCLUDE "main.inc"
INCLUDE "hardware.inc"

; ------------------------------------------------------------------------------
; `macro SetGameState(state_value)`
;
; Disables the LCD and all interrupts then sets the given game state.
; ------------------------------------------------------------------------------
MACRO SetGameState
  di
  ld a, 0
  ld [rLCDC], a
  call InitDisplayState
  ld a, \1
  ld [bGameState], a
ENDM

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
  ; Global interrupt disable
  di
  ; Disable audio
  ld a, 0
  ld [rNR52], a
  ; Disable the LCD
  WaitForVblank
  ld a, 0
  ld [rLCDC], a
  ; Zero out the RAM
  ld bc, $2000
  ld hl, $C000
  call ClearData
  ; Initialize the state of the LCD
  call InitDisplayState
  ; Initialize the DMA routine
  call WriteDMARoutine
  ; Set the initial game state
  ld a, STATE_TITLE
  ld [bGameState], a
  ; Execute the title screen's initialization routine
  call TitleInit
  jp GameLoop

; ------------------------------------------------------------------------------
; `func InitDisplayState()`
;
; Initializes the display so that it is in a consistent state prior to loading
; a new screen for the game.
; ------------------------------------------------------------------------------
InitDisplayState:
  ; Disable LCD interrupts and reset the scroll position
  ld a, 0
  ld [rSTAT], a
  ld [rIE], a
  ld [rSCX], a
  ld [rSCY], a
  ; Clear the active tileset and both backgrounds
  ld hl, $9000
  ld bc, $2000
  call ClearData
  ; Clear the OAM
  ld bc, 40 * 4
  ld hl, pSpriteOAM
  ld d, $FF
  call FillData
  ; Reset palettes
  ld a, %11100100
  ld [rBGP], a
  ld [rOBP0], a
  ld [rOBP1], a
  ret

; ------------------------------------------------------------------------------
; `func GameLoop()`
;
; The main loop for the game that handles all logic and rendering.
; ------------------------------------------------------------------------------
GameLoop:
  WaitForVblank
  call ReadJoypad
  ld a, [bGameState]
  cp a, STATE_DEMO_SELECT
  jr z, .demo_select
  cp a, STATE_DEMO1
  jr z, .demo1
  cp a, STATE_DEMO2
  jr z, .demo2
  cp a, STATE_DEMO3
  jr z, .demo3
  cp a, STATE_DEMO4
  jr z, .demo4
  cp a, STATE_DEMO5
  jr z, .demo5
.title
  call TitleLoop
  jr .done
.demo_select
  call DemoSelectLoop
  jr .done
.demo1
  call Demo1Loop
  jr .done
.demo2
  call Demo2Loop
  jr .done
.demo3
  call Demo3Loop
  jr .done
.demo4
  call Demo4Loop
  jr .done
.demo5
  call Demo5Loop
.done
  WaitForVblankEnd
  jr GameLoop

; ------------------------------------------------------------------------------
; `func LoadTitle()`
;
; Transitions the game state and loads the title screen.
; ------------------------------------------------------------------------------
LoadTitle::
  SetGameState STATE_TITLE
  call TitleInit
  ret

; ------------------------------------------------------------------------------
; `func LoadDemoSelect()`
;
; Transitions the game state and loads the demo select screen.
; ------------------------------------------------------------------------------
LoadDemoSelect::
  SetGameState STATE_DEMO_SELECT
  call DemoSelectInit
  ret

; ------------------------------------------------------------------------------
; `func LoadDemo1()`
;
; Loads the first demo.
; ------------------------------------------------------------------------------
LoadDemo1::
  SetGameState STATE_DEMO1
  call Demo1Init
  ret

; ------------------------------------------------------------------------------
; `func LoadDemo2()`
;
; Loads the second demo.
; ------------------------------------------------------------------------------
LoadDemo2::
  SetGameState STATE_DEMO2
  call Demo2Init
  ret

; ------------------------------------------------------------------------------
; `func LoadDemo3()`
;
; Loads the third demo.
; ------------------------------------------------------------------------------
LoadDemo3::
  SetGameState STATE_DEMO3
  call Demo3Init
  ret

; ------------------------------------------------------------------------------
; `func LoadDemo4()`
;
; Loads the fourth demo.
; ------------------------------------------------------------------------------
LoadDemo4::
  SetGameState STATE_DEMO4
  call Demo4Init
  ret


; ------------------------------------------------------------------------------
; `func LoadDemo5()`
;
; Loads the fifth demo.
; ------------------------------------------------------------------------------
LoadDemo5::
  SetGameState STATE_DEMO5
  call Demo5Init
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
; * **Page 4** (`offset_TilesRpgObjects = +$1800`) - RPG Objects
;
; Pages 5 through 8 are left blank so you can experiment with making and loading
; your own graphics.
; ------------------------------------------------------------------------------
TileData:: INCBIN "bin/tiles.gb"
