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

loadpalettes:
  lda $2002         ; Read PPU status to reset the high/low latch
  lda #$3F
  sta $2006         ; Write the high byte of $3F00 address
  lda #$00
  sta $2006         ; Write the low byte of $3F00 address
  LDX #$00
@loop:
  lda palette, x    ; Load palette byte
  sta $2007         ; Write to PPU
  inx               ; Set index to next byte
  cpx #$20
  bne @loop         ; If x = $20, 32 bytes copied so we're all done

  lda #$80
  sta $0200         ; Put sprite 0 in center ($80) of screen vert
  sta $0203         ; Put sprite 0 in center ($80) of screen horiz
  lda #$00
  sta $0201         ; Tile number = 0
  sta $0202         ; Color = 0, no flipping

  lda #%10000000    ; Enable NMI, sprites from Pattern Table 0
  sta $2000

  lda #%00010000    ; Enable sprites
  sta $2001

forever:
  jmp forever

nmi:
  lda #$00
  sta $2003         ; Set the low byte (00) of the RAM address
  lda #$02
  sta $4014         ; Set the high byte (02) of the RAM address to start the transfer

  rti

palette:
  ; Background
  .byte $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F

  ; Sprite palette
  .byte $0F,$16,$27,$18,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

.segment "VECTORS"

  .word nmi
  .word reset
  .word 0           ; IRQ, unused

.segment "CHARS"

  .incbin "sprites.chr"
