MODULE _main
PUBLIC initScreenBuffer

INCLUDE "Ti83p.def"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/screen_buffer.inc"

SECTION rodata_compiler
scConst:
    defm "SC",0
screenBufferArchived:
    defm "The SC AppVar is archived.",0
SECTION bss_compiler
SECTION code_compiler

; Create or open the screen buffer AppVar for this game
; and load the header
; returns Z = completed successfully
.initScreenBuffer
    ; Copy story name and change to end in SC
    ld hl,screenBufferNameLength
    ld de,screenBufferNameLength

    ld a,(hl) ; This won't copy the last three bytes "00\0" because we copy the length and appvar bytes
    ld c,a
    ld b,0
    ldir

    ld hl,scConst
    ld bc,3
    ldir

    ld hl,screenBufferNameOP1

    rst rMOV9TOOP1

    rst 0x28
    defw _ChkFindSym

    jr c, screenBufferDoesntExist
    ; DE = pointer to RAM data

    inc de
    inc de

    ; FIXME actual pointer
    ld (screenBufferOffset),de
    ld (screenBufferCursor),de
    ld (screenBufferView),de

    xor a
    cp b

    jr z,screenBufferCreated

    ld hl,screenBufferArchived
    xor a
    call vWrapS

    ; Reset flags before return
    xor a
    inc a

    ret

.screenBufferDoesntExist
    ; Create the screen buffer memory AppVar
    ld hl,screenBufferSize

    rst 0x28
    defw _CreateAppVar

    inc de
    inc de

    ld (screenBufferOffset),de
    ld (screenBufferCursor),de
    ld (screenBufferView),de

.screenBufferZeroMemory
    ; Zero memory
    ; Set first byte to space
    ex de,hl
    ld a,' '
    ld (hl),a
    ld de,hl

    ; Destination is one after
    inc de

    ld bc,screenBufferSize
    dec bc

    ldir

.screenBufferCreated
    xor a ; Set zero flag
    ret
