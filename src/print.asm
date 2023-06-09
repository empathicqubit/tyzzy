MODULE _main
PUBLIC loadAndPrintZString
PUBLIC ztextBuffer
PUBLIC ztextBufferWordCount
PUBLIC printZCharacter

EXTERN storyReadbytes

INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/screen_buffer.inc"
INCLUDE "Ti83p.def"

DEFC ztextBufferWordCount = 32
DEFC abbrevBufferWordCount = 8

SECTION bss_compiler
; Start character of abbreviation
abbrevChar:
    defs 1
; shifts into next row: 32 or 64
shiftValue:
    defs 1
ztextBuffer:
    defs ztextBufferWordCount*2
abbrevBuffer:
    defs abbrevBufferWordCount*2

SECTION code_compiler

; Print a single 10-bit ZSCII character
; Inputs HL = Pointer to the ZSCII code to print
.printZCharacter
    ; FIXME incomplete
    jp screenBufferWrite

; Print at most n words from Z String
; Inputs DEHL = Z-address of string
;        IX = Text buffer location
;        BC = Text buffer word count
; Returns C register = number of unconsumed words
;         HL = the byte after the end of the Z string
.loadAndPrintZString

.nextPrintBlock
    ; Queue bytes
    push de
    push bc ; word count

    push hl
    ld hl,bc
    add hl,hl
    ld bc,hl ; byte count
    pop hl

    push ix
    push bc
    push hl
.readPrintBlock
    call storyReadbytes
.doneReadPrintBlock
    pop hl
    pop bc

    ; Next block address
    add hl,bc

    pop ix
    pop bc
    push bc
    push ix
    push hl
    ld hl,ix
    call nprintZString
    jr nz,finishPrintBlock
    pop hl
    pop ix
    pop bc
    pop de
    jr nextPrintBlock
.finishPrintBlock
    ; throw out the stack
    pop hl
    pop de
    pop de
    pop de
    ret

; Print at most n words from Z String
; Inputs C = count of words to print
;        HL = source
; Returns Z = Reached end of input before string terminated
.nprintZString

.nextPrintWord
    ; Load word
    ld d,(hl)
    inc hl
    ld e,(hl)
    inc hl
.printWordLoaded

    ; Shift out end bit
    ld ixh,d ; Preserve end bit
    ld ixl,3
.nextPrintChar
    ; Mask z-char
    ld a,d
    rra
    rra
    and 0x1f
.printCharLoaded

    push bc
    push hl

    ex af,af'
    ld a,(abbrevChar)
    or a
    jp z,noAbbrevChar
.loadAbbreviation

    ; (a - 1) * 32
    dec a
    ld l,a
    ld h,0
    add hl,hl ; 2
    add hl,hl ; 4
    add hl,hl ; 8
    add hl,hl ; 16
    add hl,hl ; 32

    xor a
    ld (abbrevChar),a

    ; + b
    ex af,af'
    ld c,a
    ld b,0
    add hl,bc

    ; to bytes
    add hl,hl

    push de
    push ix

    ld de,(headerAbbrevStart)
    add hl,de

    ; get reference
    ld ix,abbrevBuffer
    ld bc,2
    ld de,0
    push de
    call storyReadbytes

    ld hl,(abbrevBuffer)
    HLTOLH
    add hl,hl
.abbrevRefLoaded

    pop de
    ld ix,abbrevBuffer
    ld bc,abbrevBufferWordCount
    call loadAndPrintZString

    pop ix
    pop de

    xor a
    ld (abbrevChar),a
.noAbbrevChar
    ex af,af'

    ; Handle or ignore special chars
    or a
    jr z,notSpecial
    cp 7
    jr z,printNewline
    cp 4
    jr z,shiftOne
    jr c,abbreviation
    cp 5
    jr z,shiftTwo
    jr noShift
.printNewline
    ld hl,newlineChar
    jr doPrintPutChar
.abbreviation
    ld (abbrevChar),a
    jr skipPrintPutMap
.shiftTwo
    ld a,32*2
    ld (shiftValue),a
    jr skipPrintPutMap
.shiftOne
    ld a,32
    ld (shiftValue),a
    jr skipPrintPutMap
.noShift
    cp 6
    jr nc,notSpecial
    ld a,31
.notSpecial

    ; Seek into alpha table
    ld c,a
    ld b,0
    ld hl,alphaTableV2
    add hl,bc
    ld a,(shiftValue)
    ld c,a
    add hl,bc

.doPrintPutChar
    push de
    push ix
    call screenBufferWrite
.popPrintPutMap
    pop ix
    pop de
.donePrintPutChar
    ; Reset shift
    xor a
    ld (shiftValue),a

.skipPrintPutMap
    ld c,5
.nextPrintBit
    rl e
    rl d
    dec c
    jr nz,nextPrintBit

    pop hl
    pop bc

    dec ixl
    jp nz,nextPrintChar
    ; Test word end
    ld a,ixh
    bit 7,a

    ret nz

    dec c
    jp nz,nextPrintWord
    ret

SECTION rodata_compiler
newlineChar:
    defb 0x0a

alphaTable:
    defm ' ',1,2,3,4,5,"abcdefghijklmnopqrstuvwxyz"
    defm ' ',1,2,3,4,5,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    defm ' ',1,2,3,4,5," 0123456789.,!?_#'\"/\\<-:()"

alphaTableV2:
    defm ' ',1,2,3,4,5,"abcdefghijklmnopqrstuvwxyz"
    defm ' ',1,2,3,4,5,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    defm ' ',1,2,3,4,5,' ',7,"0123456789.,!?_#'\"/\\-:()"
