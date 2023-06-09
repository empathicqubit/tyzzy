MODULE _main

PUBLIC screenBufferOffset
PUBLIC screenBufferCursor
PUBLIC screenBufferView
PUBLIC screenBufferSize
PUBLIC screenBufferWrite
PUBLIC screenBufferWriteNumber
PUBLIC screenBufferDraw

PUBLIC screenBufferMoveViewUp
PUBLIC screenBufferMoveViewDown

EXTERN l_utoa

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"

defc screenBufferSize = 1024

SECTION rodata_compiler
SECTION bss_compiler
; The offset to the beginning of the screen buffer in memory
screenBufferOffset:
    defs 2
; The beginning/end of the buffer
screenBufferCursor:
    defs 2
; The position the screen is currently focused on
screenBufferView:
    defs 2

SECTION code_compiler
; HL = pointer to character to write
; Destroys BC,DE,HL
.screenBufferWrite
    ; Write next character
    ld de,(screenBufferCursor)
    ldi
    ld (screenBufferCursor),de
    dec de
    ld (screenBufferView),de

    ; Check to see if cursor is greater than buffer size
    ; and reset
    ex de,hl
    ld de,(screenBufferOffset)
    ld bc,screenBufferSize
    or a
    sbc hl,de
    sbc hl,bc
    add hl,bc
    jr c,screenBufferValid

    ; Reset the cursor to the beginning
    ld (screenBufferCursor),de
    dec de
    ld (screenBufferView),de
.screenBufferValid
    ret

; HL = the number to write to the screen buffer
.screenBufferWriteNumber
    ld de,(screenBufferCursor)
    call l_utoa
    ld (screenBufferCursor),de
    dec de
    ld (screenBufferView),de
    ret

; Draw the screen buffer
.screenBufferDraw
    call scrClr
    call rstCurBottom

    ; Don't seek past the beginning
    ld hl,(screenBufferView)
    push hl
    ld de,(screenBufferOffset)
    or a
    sbc hl,de
    ld bc,hl
    pop hl
    ld ixl,1

.screenBufferDrawNext
    ld a,(penRow)
    cp 64
    ret nc

    ld a,0x0a
    cpdr
    ret po

    inc hl
    inc hl
    push bc
    push ix
    push hl
    ld c,ixl
    dec c
    jr z,screenBufferDrawBackedUp
.screenBufferDrawBackup
    call oldLine
    dec c
    jr nz,screenBufferDrawBackup
.screenBufferDrawBackedUp
    ld a,ixl
    call vWrapS
    pop hl
    jr c,screenBufferDrawAgain
.screenBufferDrawSuccess
    push hl
    ; Clear to end of row
    ld a,(penCol)
    ld l,a
    ld a,(penRow)
    ld h,a
    add 6
    ld d,a
    ld e,95
    rst 0x28
    defw _ClearRect
    pop hl

    dec hl
    dec hl
    pop ix
.screenBufferDrawBackupAgain
    call oldLine
    dec ixl
    jr nz,screenBufferDrawBackupAgain
    ld ixl,1
    pop bc
    jr screenBufferDrawNext
.screenBufferDrawAgain
    pop ix
    inc ixl
    pop bc
    jr screenBufferDrawNext

; Shifts the screen up one page
.screenBufferMoveViewUp
    ld hl,(screenBufferView)
    push hl
    ld de,(screenBufferOffset)
    or a
    sbc hl,de
    ld bc,hl
    pop hl

    ld a,0x0a
    cpdr
    ret po

    ld (screenBufferView),hl
    ret

; Shifts the screen down one page
.screenBufferMoveViewDown
    ld hl,(screenBufferView)
    push hl
    ld de,(screenBufferOffset)
    or a
    sbc hl,de
    ex de,hl
    ld hl,screenBufferSize
    or a
    sbc hl,de
    ld bc,hl
    pop hl

    ld hl,(screenBufferView)

    ld a,0x0a
    cpir
    ret po

    ld (screenBufferView),hl
    ret

; To draw the actual screen:
; Start from the end, seeking backwards
; Seek back to a return character from the view cursor
; Calculate the minimum number of screen lines required to render the text line, move back to that screen line.
; Draw the line with wrapping, if the last screen line wraps, move one screen line higher and try again until drawn
; Repeat with the previous text lines until the screen is full
