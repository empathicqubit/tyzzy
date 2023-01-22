MODULE _main
PUBLIC pushCall
PUBLIC pushWord
PUBLIC popCall
PUBLIC popWord

PUBLIC stackEndOffset
PUBLIC stackOffset
PUBLIC stackTopOffset

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/state.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
SECTION bss_compiler
; The offset to the beginning of the stack in memory
stackOffset:
    defs 2

; The end of the stack, which is the byte after the last valid one. Writing here
; or after will require the file to be expanded.
stackEndOffset:
    defs 2

; The top of the stack. The place we'll write the next value
stackTopOffset:
    defs 2

staging:
    defs 37 ; 15 * 2 vars + 4 zero mask + 2 PC + 1 var count
SECTION code_compiler

; stack format:
;   Variables (2B * variable count + ceil(variable count / 4)):
;       Given:
;           (00 00) (01 00) (00 01) (ff ff)
;           (01 00) (01 00)
;       Becomes:
;           () (01) (01) (ff ff) (00100111)
;           (01) (01) (00001010)
;   Variable count (1B) (FIXME: Already maintained by the function?)
;   PC (2B)
;   Size of variable stack (1B) (always zero at start of function)

; Pushes the variable data and return address into the stack file
; The return address is the last byte of the call instruction - the var to store
; No inputs - No outputs
.pushCall
    ; Scan the variables
    ld hl,zVARs
    ld de,staging

    ; Get the byte count rounded up by 8
    ld a,(zVARcount)
    add a
    jr z,doneVarBytes
    ld c,a ; actual byte count
    add 8 - 1
    and 0xf8

    ld ixl,a ; Rounded byte count

    ld b,0
    xor a

.nextVarByte
    or a
    rl b

    ld a,(hl)
    or a
    jr z,varByteIsZero
    ld (de),a
    inc de
    set 0,b
.varByteIsZero
    inc hl

.nextFakeByte
    dec ixl
    ld a,ixl
    and 0x07 ; divisible by 8?
    jr nz,notDivisibleByEight
.divisibleByEight
    ; Insert zero byte and reset
    ld a,b
    ld (de),a
    inc de

    ; Quit if we've reached zero
    ld a,ixl
    or a
    jr z,doneVarBytes
    ld b,0
.notDivisibleByEight

    dec c
    jr nz,nextVarByte
    ; FIXME This isn't incredibly efficient, but I don't care enough to fix it rn
    inc c
    jr nextFakeByte

.doneVarBytes
    ; Save var count
    ld a,(zVARcount)
    ld (de),a
    inc de

    ; Save PC
    ex de,hl
    ld de,(storyPC)
    ld (hl),e
    inc hl
    ld (hl),d
    inc hl

    ; Save new stack count
    xor a
    ld (hl),a
    inc hl

    ; Get length of staging data
    ld de,staging
    or a
    sbc hl,de

.growStackOrWriteData
    push hl ; The size of the data

    ; Add to top of stack
    ld de,(stackTopOffset)
    push de ; Preserve the old offset

    add hl,de
    ld (stackTopOffset),hl

    push hl

    ; Get the number of bytes to add
    ld de,(stackEndOffset)
    or a
    sbc hl,de
    jr c,stackBigEnough
    jr z,stackBigEnough
.stackNotBigEnough
    ; HL = count
    ; DE = stackEndOffset location to insert (the very end)

    rst 0x28
    defw InsertMem

    ; Set new end of stack
    pop hl
    ld (stackEndOffset),hl

    ; Get new length
    ld de,(stackOffset)
    or a
    sbc hl,de

    ex de,hl
    dec hl
    dec hl

    ; Set length indicator
    ld (hl),de
    pop de ; Old top of stack
    jr doneSizingStack
.stackBigEnough
    pop de ; Top of stack
    pop de ; Old top of stack
.doneSizingStack
    pop bc ; The length of the staging area from earlier

    ; Write the bytes to the stack
    ld hl,staging
    ldir
.donePushCall
    ret

; Pops the current stack, variable data, and return address off the stack file
; The return address is the last byte of the call instruction - the var to store
; No inputs - No outputs
.popCall
    ; Get the top byte, which has the stack count
    ld hl,(stackTopOffset)
    dec hl
    ld a,(hl)
    ld e,a
    ld d,0
    or a
    sbc hl,de
    or a
    sbc hl,de

    ; Reset PC
    dec hl
    ld d,(hl)
    dec hl
    ld e,(hl)
    ld (storyPC),de

    ; Reset variable count
    dec hl
    ld a,(hl)
    ld (zVARcount),a

    ; Skip if there's no variables
    ex de,hl
    add a
    jp z,donePopCall

    ; Scan to end of vars and write bytes backwards
    ld ixl,a
    ld c,a
    ld b,0
    ld hl,zVARs
    add hl,bc
    ld c,ixl ; var byte count

.nextMaskByte
    dec de
    ld a,(de)
    ld b,a
.nextMaskBit
    dec hl
    bit 0,b
    jr z,writeZero
.writeByte
    dec de
    ld a,(de)
    ld (hl),a
    jr doneWriteByte
.writeZero
    xor a
    ld (hl),a
.doneWriteByte
    dec c
    jr z,donePopCall
    ld a,c
    and 0x07 ; Divisible by eight?
    jr z,nextMaskByte
    rr b
    jr nextMaskBit

.donePopCall
    ; Save the new stack top
    ld (stackTopOffset),de
    ret


; Push a word onto the stack
; Inputs: DE = The word in little endian
.pushWord
    ld (staging),de
    ; Overwrite the top byte on the stack
    ld hl,(stackTopOffset)
    dec hl
    ld (stackTopOffset),hl

    ; Increment the stack counter at the end of the stack
    ld a,(hl)
    inc a
    ld (staging+2),a

    ld hl,3
    jp growStackOrWriteData

; Pop a word off the stack
; Outputs: BC = The word in little endian
; Destroys HL
.popWord
    ; Load the stack counter
    ld hl,(stackTopOffset)
    dec hl
    ld a,(hl)
    or a
    ret z ; Stack is empty

    dec a
    dec hl
    ld b,(hl)
    dec hl
    ld c,(hl)

    ld (hl),a
    inc hl
    ld (stackTopOffset),hl
.donePopWord
    ret
