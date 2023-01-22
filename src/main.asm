MODULE _main
PUBLIC _main

EXTERN findStories
EXTERN storiesMenu
EXTERN confirmSlices
EXTERN storyReadbytes
EXTERN initDynmem
EXTERN initStack
EXTERN processInstruction

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/state.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
stopped:
    defm "STOPPED AT ",0
sliceMissing:
    defm "There is a story slice missing!",0
anyKey:
    defm "Press the any key to continue.",0
SECTION bss_compiler
SECTION code_compiler

._main
    ld (quitSP),SP

    xor a ; We don't want to search for a specific story
    ld (OP1),a
    call findStories

    call storiesMenu ; HL = pointer to selected story

    ; Save story name length elsewhere
    ld e,(hl)
    inc hl
    ld d,(hl)
    dec hl

    ld a,(de)
    ld (storyNameLength),a

    ld de,storyName

    call copyNameToForward

    ld hl,storyNameOP1

    rst rMOV9TOOP1

    call findStories

    call confirmSlices ; Make sure all slices exist, in case one got missed in transfer
    ; IX = last two bytes of last story filename

    jr z,succeedSlices
.failedSlices
    ld hl,sliceMissing
    call vWrapS

    call getKeyOrQuit
    ret

.succeedSlices
    ; We have everything we need. Now initialize the VM

    ; Create and initialize the dynamic memory AppVar
    call initDynmem
    jr nz,doneMain
.dynMemInitted

    call initStack
    jr nz,doneMain
.stackInitted

    ; FIXME This must be correctly persisted
    ; Setup PC
    ld de,(headerPCStart)
    ld (storyPC),de

.storyLoop
    call processInstruction
    jr z,storyLoop

    call newLine

    ld hl,stopped
    call vWrapS

    ld hl,(storyPC)
    call vWrapN

    ld a,':'
    rst 0x28
    defw _VPutMap

    ld a,(opcodeNumber)
    ld h,0
    ld l,a
    call vWrapN

.doneMain
    call getKeyOrQuit
    ret
