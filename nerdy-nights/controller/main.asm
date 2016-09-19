.include "header.inc"

.segment "STARTUP"

.segment "CODE"

.define SPEED $02

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

load_palettes:
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

load_sprites:
  ldx #$00
@loop:
  lda sprites, x
  sta $0200, x
  inx
  cpx #$20
  bne @loop

  lda #%10000000    ; Enable NMI, sprites from Pattern Table 0
  sta $2000

  lda #%00010000    ; Enable sprites
  sta $2001

forever:
  jmp forever

nmi:
  ; Transfer sprites with DMA
  lda #$00
  sta $2003         ; Set the low byte (00) of the RAM address
  lda #$02
  sta $4014         ; Set the high byte (02) of the RAM address to start the transfer

latch_controllers:
  lda #$01
  sta $4016
  lda #$00
  sta $4016         ; Latch data for both controllers

  ; A, B, Select, Start, Up, Down, Left, Right
  lda $4016         ; A
  lda $4016         ; B
  lda $4016         ; Select
  lda $4016         ; Start

up:
  lda $4016         ; Player 1 - A
  and #%00000001    ; Only look at bit 0
  beq up_done     ; Branch to up_done if button is NOT pressed (0)

  ldy #0
  ldx #0
@move:
  lda $0200,X       ; Load sprite Y position
  sec               ; make sure the carry flag is set
  sbc #SPEED        ; A = A - 1
  sta $0200,X       ; Save sprite Y position
  inx
  inx
  inx
  inx
  iny
  cpy #4
  bcc @move

up_done:

down:
  lda $4016         ; Player 1 - B
  and #%00000001    ; Only look at bit 0
  beq down_done    ; Branch to down_done if button is NOT pressed (0)

  ldy #0
  ldx #0
@move:
  lda $0200,X       ; Load sprite X position
  clc               ; make sure the carry flag is clear
  adc #SPEED        ; A = A + 1
  sta $0200,X       ; Save sprite X position
  inx
  inx
  inx
  inx
  iny
  cpy #4
  bcc @move

down_done:

left:
  lda $4016         ; Player 1 - A
  and #%00000001    ; Only look at bit 0
  beq left_done     ; Branch to left_done if button is NOT pressed (0)

  ldy #0
  ldx #0
@move:
  lda $0203,X       ; Load sprite X position
  sec               ; make sure the carry flag is set
  sbc #SPEED        ; A = A - 1
  sta $0203,X       ; Save sprite X position
  inx
  inx
  inx
  inx
  iny
  cpy #4
  bcc @move

left_done:

right:
  lda $4016         ; Player 1 - B
  and #%00000001    ; Only look at bit 0
  beq right_done    ; Branch to right_done if button is NOT pressed (0)

  ldy #0
  ldx #0
@move:
  lda $0203,X       ; Load sprite X position
  clc               ; make sure the carry flag is clear
  adc #SPEED        ; A = A + 1
  sta $0203,X       ; Save sprite X position
  inx
  inx
  inx
  inx
  iny
  cpy #4
  bcc @move

right_done:

  rti

palette:
  ; Background
  .byte $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F

  ; Sprite palette
  .byte $0F,$16,$27,$18,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

sprites:
  ;      Y, tile, attrs, X
  .byte $80, $32, $00, $80
  .byte $80, $33, $00, $88
  .byte $88, $34, $00, $80
  .byte $88, $35, $00, $88

.segment "VECTORS"

  .word 0, 0, 0     ; Unused, but needed to advance PC to $fffa.
  .word nmi
  .word reset
  .word 0           ; IRQ, unused

.segment "CHARS"

  .incbin "sprites.chr"
