MODULE _main
PUBLIC initDynmem

EXTERN storyReadbytes

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
dmConst:
    defm "DM",0
dynMemArchived:
    defm "The DM AppVar is archived.",0
SECTION bss_compiler
SECTION code_compiler

; Create or open the dynamic memory AppVar for this game
; and load the header
; returns Z = completed successfully
.initDynmem

    ; Load the header
    ld de,0
    ld hl,0
    ld ix,headerForwardBegin
    ld bc,headerForwardEnd-headerForwardBegin
    call storyReadbytes

    ld hl,headerForwardEnd-1
    ld de,headerBegin
    ld bc,headerEnd-headerBegin
    call copyReverseToForward
.storyHeaderLoaded

    ; Copy story name and change to end in DM
    ld hl,storyNameLength
    ld de,dynMemNameLength

    ld a,(hl) ; This won't copy the last three bytes "00\0" because we copy the length and appvar bytes
    ld c,a
    ld b,0
    ldir

    ld hl,dmConst
    ld bc,3
    ldir

    ld hl,dynMemNameOP1

    rst rMOV9TOOP1

    rst 0x28
    defw _ChkFindSym

    jr c, dynmemDoesntExist

    inc de
    inc de

    ld (dynMemOffset),de
    xor a
    cp b

    jr z,dynmemCreated

    ld hl,dynMemArchived
    call vWrapS

    ; Reset flags before return
    xor a
    inc a

    ret

.dynmemDoesntExist
    ; Create the dynamic memory AppVar
    ld hl,(headerStaticStart)
    ld bc,hl

    rst 0x28
    defw _CreateAppVar

    inc de
    inc de

    ; Fill dynamic memory with data
    ; BC comes from headerStaticStart
    push de

    ld ix,de
    ld de,0
    ld hl,0
    call storyReadbytes

    pop de
    ld (dynMemOffset),de

.dynmemCreated
    xor a ; Set zero flag
    ret
