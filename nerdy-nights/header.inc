.segment "HEADER"

  .byte "NES", $1A  ; iNES header identifier
  .byte 2           ; 2x 16KB PRG code
  .byte 1           ; 1x  8KB CHR data
  .byte $01, $00    ; vertical mirroring, mapper 0 (NROM, ie: no mapper)
