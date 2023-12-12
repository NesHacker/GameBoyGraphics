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

; Delay in frames between updates for the "further" top mountain scroll.
DEF MountainTopScrollDelay EQU 48

; Delay in frames between updates for the "closer" bottom mountains.
DEF MountainBottomScrollDelay EQU 16

SECTION "Stat Interrupt Handler", ROM0[$48]
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
; `module TitleScreen`
;
; Module for handling the game's title screen.
; ------------------------------------------------------------------------------
TitleScreen::

; ------------------------------------------------------------------------------
; `func .init()`
;
; Initializes the title screen.
; ------------------------------------------------------------------------------
.init::
  ; Load common background tiles into VRAM in the dedicated BG page.
  ld hl, $9000
  ld bc, $800
  ld de, TileData + offset_TilesCommon
  call CopyData
  ; Load the title specific graphics into shared tiles page in VRAM.
  ld hl, $8800
  ld bc, $800
  ld de, TileData + offset_TilesTitle
  call CopyData
  ; Load title screen
  ld hl, $9800
  ld de, tilemap_TitleScreen_32x32
  ld bc, 32 * 32
  call CopyData
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
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
  ld [rLCDC], a
  ret

; ------------------------------------------------------------------------------
; `func .loop()`
;
; Executes game loop logic for the title screen.
; ------------------------------------------------------------------------------
.loop::
  WaitForVblank

  ; TODO Check controller inputs and change game state if needed...

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
  ; WaitForVblankEnd
  ret





SECTION "Title Screen Data", ROM0

; 32x32 full background title screen tilemap.
tilemap_TitleScreen_32x32: INCBIN "bin/TitleScreen_32x32.tilemap"
