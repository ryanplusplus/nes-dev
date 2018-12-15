.include "header.inc"

.segment "STARTUP"

.segment "CODE"

.define SPEED $02
.define NSPEED $fe

.define KEYREG $4016

.macro move_sprite addr, offset
  ldy #0
  ldx #0
  @move:
  lda addr,X          ; Load sprite Y position
  clc                 ; make sure the carry flag is clear
  adc #offset
  sta addr,X          ; Save sprite Y position
  inx
  inx
  inx
  inx
  iny
  cpy #4
  bcc @move
.endmacro

.macro brifnkey dst
  lda KEYREG
  and #%00000001    ; Only look at bit 0
  beq dst
.endmacro

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
@vblank_wait:
  bit $2002
  bpl @vblank_wait

clrmem:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$fe
  sta $0200, x      ; Move all sprites off screen
  inx
  bne clrmem

; Wait for second vblank, PPU is ready after this
@vblank_wait:
  bit $2002
  bpl @vblank_wait

clear_nametables:
  lda $2002         ; Read PPU status to reset the high/low latch
  lda #$20
  sta $2006
  lda #$00
  sta $2006
  ldx #$08          ; Prepare to fill 8 pages ($800 bytes)
  ldy #$00          ; X and Y make a 16-bit counter, high byte in x
  lda #$27          ; Fill with tile $27 (a black box)
@loop:
  sta $2007
  dey
  bne @loop
  dex
  bne @loop

load_palettes:
  lda $2002         ; Read PPU status to reset the high/low latch
  lda #$3F
  sta $2006         ; Write the high byte of $3F00 address
  lda #$00
  sta $2006         ; Write the low byte of $3F00 address
  ldx #$00
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
  cpx #$10
  bne @loop

load_background:
  lda $2002         ; Read PPU status to reset the high/low latch
  lda #$20
  sta $2006         ; Write the high byte of $2000 address
  lda #$00
  sta $2006         ; Write the low byte of $2000 address
  ldx #$00
@loop:
  lda background, x ; Load data from address (background + the value in x)
  sta $2007         ; Write to PPU
  inx
  cpx #$80
  bne @loop

load_attribute:
  lda $2002         ; Read PPU status to reset the high/low latch
  lda #$23
  sta $2006         ; Write the high byte of $23C0 address
  lda #$C0
  sta $2006         ; Write the low byte of $23C0 address
  ldx #$00
@loop:
  lda attribute, x  ; Load data from address (attribute + the value in x)
  sta $2007         ; Write to PPU
  inx               ; X = X + 1
  cpx #$08
  bne @loop

  lda #%10010000    ; Enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  sta $2000
  lda #%00011110    ; Enable sprites, enable background
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
  sta KEYREG
  lda #$00
  sta KEYREG        ; Latch data for both controllers

  ; A, B, Select, Start, Up, Down, Left, Right
  lda KEYREG        ; A
  lda KEYREG        ; B
  lda KEYREG        ; Select
  lda KEYREG        ; Start

up:
  brifnkey up_done
  move_sprite $0200, NSPEED
up_done:

down:
  brifnkey down_done
  move_sprite $0200, SPEED
down_done:

left:
  brifnkey left_done
  move_sprite $0203, NSPEED
left_done:

right:
  brifnkey right_done
  move_sprite $0203, SPEED
right_done:

  ; PPU cleanup
  lda #%10010000    ; Enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  sta $2000
  lda #%00011110    ; Enable sprites, enable background
  sta $2001

  lda #$00          ; Tell the PPU that we're not scrolling
  sta $2005
  sta $2005

  rti

palette:
  ; Background
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F

  ; Sprite palette
  .byte $22,$16,$27,$18,$22,$1C,$15,$14,$22,$02,$38,$3C,$22,$1C,$15,$14

background:
  ; Row 1 (sky)
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; Row 2 (sky)
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

  ; Row 3 (brick tops)
  .byte $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24

  ; Row 4 (brick bottoms)
  .byte $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24

attribute:
  .byte %00000000, %00010000, %01010000, %00010000
  .byte %00000000, %00000000, %00000000, %00110000

sprites:
  ;      Y, tile, attrs, X
  .byte $80, $32, $00, $80
  .byte $80, $33, $00, $88
  .byte $88, $34, $00, $80
  .byte $88, $35, $00, $88

.segment "VECTORS"

  .word nmi
  .word reset
  .word 0           ; IRQ, unused

.segment "CHARS"

  .incbin "sprites.chr"
