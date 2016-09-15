.include "header.inc"

.segment "STARTUP"

.segment "CODE"

reset:
  sei               ; Disable IRQs
  cld               ; Disable decimal mode
  ldx #$40
  stx $4017         ; Disable APU frame IRQ
  ldx #$ff
  txs               ; Set up stack
  inx               ; Now X = 0
  stx $2000         ; Disable NMI
  stx $2001         ; Disable rendering
  stx $4010         ; Disable DMC IRQs

; Wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clrmem:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$fe
  sta $0300, x
  inx
  bne clrmem

; Wait for second vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

  lda #%10000000    ; Intensify blues
  sta $2001

forever:
  jmp forever

nmi:
  rti

.segment "VECTORS"

  .word 0, 0, 0     ; Unused, but needed to advance PC to $fffa.
  .word nmi
  .word reset
  .word 0           ; IRQ, unused

.segment "CHARS"
