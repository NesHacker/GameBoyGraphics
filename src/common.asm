SECTION "Common Routines", ROM0

; ------------------------------------------------------------------------------
; `func CopyData(bc, de, hl)`
;
; * `bc` - Number of bytes to copy.
; * `de` - Start address of the source data.
; * `hl` - Start address for the destination.
;
; Copies bytes from one location in memory to another.
; ------------------------------------------------------------------------------
CopyData::
  ld a, [de]
  inc de
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, CopyData
  ret

; ------------------------------------------------------------------------------
; `func FillData(hl, bc, d)`
;
; * `hl` - Start address for the data to fill.
; * `bc` - Number of bytes to fill.
; * `d` - The value to fill for each byte.
;
; Fills data in RAM with the specified value.
; ------------------------------------------------------------------------------
FillData::
  ld a, d
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, FillData
  ret

; ------------------------------------------------------------------------------
; `func ClearData(hl, bc, d)`
;
; * `hl` - Start address for the data to clear.
; * `bc` - Number of bytes to clear.
;
; Clears bytes in RAM starting at the given address with the specified number of
; zeros.
; ------------------------------------------------------------------------------
ClearData::
  ld a, 0
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, ClearData
  ret
