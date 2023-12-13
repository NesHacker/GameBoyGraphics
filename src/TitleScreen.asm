INCLUDE "main.inc"
INCLUDE "hardware.inc"

; Scroll position for "further" top mountains
DEF bMountainTopScroll EQU $C010

; Timer for handling scroll updates for "further" top mountains
DEF bMountainTopTimer EQU $C011

; Scroll position for the "closer" bottom mountains.
DEF bMountainBottomScroll EQU $C012

; Timer for scroll updats to the "closer" bottom mountains.
DEF bMountainBottomTimer EQU $C013

; Selects the scroll position to use in the parallax interrupt handler.
DEF bScrollSelect EQU $C014

; Timer for the game boy display static animation.
DEF bStaticTimer EQU $C015

; Frame for the game boy display static animation.
DEF bStaticFrame EQU $C016

; State of the left game boy.
DEF bGameBoyLeftState EQU $C017

; Stae transition timer for the left game boy.
DEF bGameBoyLeftTimer EQU $C018

; Frame for the left game boy.
DEF bGameBoyLeftFrame EQU $C019

; State of the right game boy.
DEF bGameBoyRightState EQU $C01A

; State transition timer for the right game boy.
DEF bGameBoyRightTimer EQU $C01B

; Frame for the right game boy.
DEF bGameBoyRightFrame EQU $C01C

; Delay in frames between updates for the "further" top mountain scroll.
DEF MountainTopScrollDelay EQU 4

; Delay in frames between updates for the "closer" bottom mountains.
DEF MountainBottomScrollDelay EQU 2

; State that represents when a game boy is diplaying an image frame.
DEF GB_STATE_FRAME EQU 0

; State that represents when a game boy is displaying static.
DEF GB_STATE_STATIC EQU 1

; Number of system frames to delay between static animation keyframes.
DEF StaticFrameDelay EQU 8

; Number of system frames to hold when showing an image frame on a game boy.
DEF GameBoyDiplayDuration EQU 120

; Number of system frames to hold when static on a game boy.
DEF GameBoyStaticDuration EQU 32

SECTION "Stat Interrupt Handler", ROM0[$48]

; ------------------------------------------------------------------------------
; `func StatInterruptHandler()`
;
; Handles the `STAT` interrupt for the sytem. This is configured to fire only on
; the title screen using the `LY == LYC` check as defined in the initializtion
; routine.
; ------------------------------------------------------------------------------
StatInterruptHandler:
  jp ParallaxScroll

SECTION "Title Screen", ROM0

; ------------------------------------------------------------------------------
; `func ParallaxScroll()`
;
; `STAT` interrupt handler that changes the screen's X-scroll at a two scanlines
; (`LY == 119` & `LY == 127`) to create the parallax scrolling mountains at the
; bottom of the title screen.
;
; This is one of the "advanced" background programming techniques I briefly
; mention in the "Game Boy Graphics and How to Code Them" video.
; ------------------------------------------------------------------------------
ParallaxScroll::
  push af
  ld a, [bScrollSelect]
  and 1
  jr nz, .bottom
.top
  ld a, [bMountainTopScroll]
  ld [rSCX], a
  ld a, 1
  ld [bScrollSelect], a
  ld a, 127
  ld [rLYC], a
  pop af
  reti
.bottom
  ld a, [bMountainBottomScroll]
  ld [rSCX], a
  pop af
  reti

; ------------------------------------------------------------------------------
; `func TitleInit()`
;
; Initializes the title screen.
; ------------------------------------------------------------------------------
TitleInit::
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call MemCopy
  ; Load the title specific graphics into shared tiles page in VRAM.
  ld hl, $8800
  ld bc, $800
  ld de, TileData + offset_TilesTitle
  call MemCopy
  ; Load title screen
  ld hl, $9800
  ld de, TitleScreenTilemap
  ld bc, 32 * 32
  call MemCopy
  ; Initialize the animation state for the game boy displays
  ld a, StaticFrameDelay
  ld [bStaticTimer], a
  ld a, GameBoyDiplayDuration
  ld [bGameBoyLeftTimer], a
  ld [bGameBoyRightTimer], a
  ld a, 0
  ld [bStaticFrame], a
  ld [bGameBoyLeftState], a
  ld [bGameBoyLeftFrame], a
  ld [bGameBoyRightState], a
  ld [bGameBoyRightFrame], a
  ; Initialize parallax scroll timers
  ld a, 0
  ld [bMountainBottomScroll], a
  ld [bMountainTopScroll], a
  ld a, MountainTopScrollDelay
  ld [bMountainTopTimer], a
  ld a, MountainBottomScrollDelay
  ld [bMountainBottomTimer], a
  ; Set the LCD-y Compare register to line 119
  ld a, 119
  ld [rLYC], a
  ; Set STAT interrupt to fire when LY == LCY
  ld a, %01000000
  ld [rSTAT], a
  ; Enable LCD interrupts
  ld a, %00000010
  ld [rIE], a
  ; Global interrupt enable
  ei
  ; Set up the LCD and start rendering
  ld a, LCDCF_ON | LCDCF_BGON
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func TitleLoop()`
;
; Executes game loop logic for the title screen.
; ------------------------------------------------------------------------------
TitleLoop::
  ld a, [bJoypadDown]
  and a, BUTTON_START
  jr z, .continue
  call LoadDemoSelect
  ret
.continue
  call UpdateParallaxScroll
  call UpdateGameBoyDisplays
  ret

; ------------------------------------------------------------------------------
; `func UpdateParallaxScroll()`
;
; Handles timers and variables for the parallax mountain scroll along the bottom
; of the title screen.
; ------------------------------------------------------------------------------
UpdateParallaxScroll:
  ; Set the default scroll position of 0
  ld a, 0
  ld [rSCX], a
  ; Update timers and scroll positions for the parallax scroll mountains
.top_timer
  ld hl, bMountainTopTimer
  ld a, [bMountainTopTimer]
  dec a
  ld [bMountainTopTimer], a
  jr nz, .bottom_timer
  ld hl, bMountainTopScroll
  inc [hl]
  ld a, MountainTopScrollDelay
  ld [bMountainTopTimer], a
.bottom_timer
  ld a, [bMountainBottomTimer]
  dec a
  ld [bMountainBottomTimer], a
  jr nz, .done
  ld hl, bMountainBottomScroll
  inc [hl]
  ld a, MountainBottomScrollDelay
  ld [bMountainBottomTimer], a
.done
  ; Reset interrupt handler variables (for parallax scrolling)
  ld a, 0
  ld [bScrollSelect], a
  ld a, 119
  ld [rLYC], a
  ret

; ------------------------------------------------------------------------------
; `func UpdateGameBoyDisplays()`
;
; Handles the keyframe animations for the game boy displays.
; ------------------------------------------------------------------------------
UpdateGameBoyDisplays:
  ; Update the static keyframe animation
  ld a, [bStaticTimer]
  dec a
  ld [bStaticTimer], a
  jr nz, .update_left_display
  ld a, StaticFrameDelay
  ld [bStaticTimer], a
  ld a, [bStaticFrame]
  xor a, 1
  ld [bStaticFrame], a
.update_left_display
  ld a, [bGameBoyLeftTimer]
  dec a
  ld [bGameBoyLeftTimer], a
  jr nz, .update_left_tiles
  ld a, [bGameBoyLeftState]
  xor 1
  ld [bGameBoyLeftState], a
  jr nz, .left_static_duration
.update_left_frame
  ld a, [bGameBoyLeftFrame]
  inc a
  and %11
  ld [bGameBoyLeftFrame], a
  ld a, GameBoyDiplayDuration
  ld [bGameBoyLeftTimer], a
  jr .update_left_tiles
.left_static_duration
  ld a, GameBoyStaticDuration
  ld [bGameBoyLeftTimer], a
.update_left_tiles
  ld a, [bGameBoyLeftState]
  cp a, GB_STATE_FRAME
  jr nz, .draw_left_static
  ld a, [bGameBoyLeftFrame]
  ld hl, RenderFramesLeft
  jr .draw_left_tiles
.draw_left_static
  ld a, [bStaticFrame]
  ld hl, StaticFrames
.draw_left_tiles
  ld b, 0
  ld c, a
  add hl, bc
  ld a, [hl]
  ld hl, $9800 + 8 * 32 + 3
  ld [hli], a
  inc a
  ld [hl], a
  ld hl, $9800 + 9 * 32 + 4
  add a, $10
  ld [hld], a
  dec a
  ld [hl], a
.update_right_display
  ld a, [bGameBoyRightTimer]
  dec a
  ld [bGameBoyRightTimer], a
  jr nz, .update_right_tiles
  ld a, [bGameBoyRightState]
  xor 1
  ld [bGameBoyRightState], a
  jr nz, .right_static_duration
.update_right_frame
  ld a, [bGameBoyRightFrame]
  inc a
  and %11
  ld [bGameBoyRightFrame], a
  ld a, GameBoyDiplayDuration
  ld [bGameBoyRightTimer], a
  jr .update_right_tiles
.right_static_duration
  ld a, GameBoyStaticDuration
  ld [bGameBoyRightTimer], a
.update_right_tiles
  ld a, [bGameBoyRightState]
  cp a, GB_STATE_FRAME
  jr nz, .draw_right_static
  ld a, [bGameBoyRightFrame]
  ld hl, RenderFramesRight
  jr .draw_right_tiles
.draw_right_static
  ld a, [bStaticFrame]
  ld hl, StaticFrames
.draw_right_tiles
  ld b, 0
  ld c, a
  add hl, bc
  ld a, [hl]
  ld hl, $9800 + 8 * 32 + 15
  ld [hli], a
  inc a
  ld [hl], a
  ld hl, $9800 + 9 * 32 + 16
  add a, $10
  ld [hld], a
  dec a
  ld [hl], a
  ret

; Top-left tile frames for the animated game boy display on the left.
RenderFramesLeft:  DB $A6, $A8, $AA, $D6

; Top-left tile frames for the animated game boy display on the right.
RenderFramesRight:  DB  $AA, $D6, $A6, $A8

; Two frame static animation that's shown between display frames.
StaticFrames: DB $AC, $AE

; Background titlemap for the title screen.
TitleScreenTilemap: INCBIN "bin/TitleScreen_32x32.tilemap"
