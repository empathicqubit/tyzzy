MODULE _main
PUBLIC initStack

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/stack.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
stConst:
    defm "ST",0
stackArchived:
    defm "The ST AppVar is archived.",0
SECTION bss_compiler
SECTION code_compiler

; Create or open the dynamic memory AppVar for this game
; and load the header
; returns Z = completed successfully
.initStack
    ; Copy story name and change to end in DM
    ld hl,storyNameLength
    ld de,stackNameLength

    ld a,(hl) ; This won't copy the last three bytes "00\0" because we copy the length and appvar bytes
    ld c,a
    ld b,0
    ldir

    ld hl,stConst
    ld bc,3
    ldir

    ld hl,stackNameOP1

    rst rMOV9TOOP1

    rst 0x28
    defw _ChkFindSym

    jr c, stackDoesntExist
    ; DE = pointer to RAM data

    ; We make the top of the stack the end of the file
    ex de,hl ; HL = *RAM
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ; DE = size

    ld (stackOffset),hl

    add hl,de
    ld (stackTopOffset),hl
    ld (stackEndOffset),hl

    xor a
    cp b

    jr z,stackCreated

    ld hl,stackArchived
    call vWrapS

    ; Reset flags before return
    xor a
    inc a

    ret

.stackDoesntExist
    ; Create the stack memory AppVar
    ld hl,1

    rst 0x28
    defw _CreateAppVar

    inc de
    inc de

    ; Stack count byte
    xor a
    ld (de),a

    ld (stackOffset),de

    inc de

    ld (stackTopOffset),de
    ld (stackEndOffset),de

.stackCreated
    xor a ; Set zero flag
    ret
