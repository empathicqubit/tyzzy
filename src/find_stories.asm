MODULE _main
PUBLIC findStories

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
tyzzy_magic:
    defm 8,"**TYZZY*"
SECTION data_compiler

SECTION code_compiler

; inputs
;   OP1 (optional) = The name of the story file to find splits for. Should start with AppVarObj
; returns Nothing. Fills stories arrays
.findStories
    ; find an entry in the program section and check to see if it ends in 00 and contains the bytes we need
    defc dataPtrLo = -3
    defc dataPtrHi = -4
    defc progPage = -5
    defc nameLength = -6

    di
    ld ix,(progPtr)

    ; Initialize the array
    xor a
    ld (storyCount),a

.forStories
    ld de,(pTemp)
    dec de

    ; check if we're past the beginning of the symbol table
    ld hl,ix
    or a
    sbc hl,de
    adc hl,de
    jp z,doneStories
    jp c,doneStories

.moveNextStory
    ld a,(ix+nameLength)
    add -nameLength+1
    ld c,a
    ld b,0
    ld hl,ix
    ld iy,ix
    or a
    sbc hl,bc
    ld ix,hl

.checkRomPage
    ld a,(iy+progPage)
    or a
    jr z,forStories

    ld b,a ; For byte check later
    ld c,0

.checkTwoCharacters
    ld a,(iy+nameLength)
    cp 2
    jr c,forStories

.checkNameMatch
    ld l,a ; save name length

    ld a,(OP1) ; Skip the check if we didn't ask for it
    cp AppVarObj
    jr nz,checkDoubleZero

    push bc ; to save ROM page
    push de

    ld c,l
    ld b,0

    ld hl,ix
    add hl,bc ; Add the name length to ix and scan backwards
    dec c ; skip the last two characters
    dec c

    ld de,OP1+1
.nextByteNameMatch
    ld a,(de) ; Get current test string byte

    cpd ; Test against current filename byte
    jr nz,invalidNameMatch
    jp po,validNameMatch
    inc de

    jr nextByteNameMatch

.invalidNameMatch
    pop de
    pop bc
    jr forStories ; continue

.validNameMatch
    pop de
    pop bc
    jr checkTyzzyHeader

.checkDoubleZero
    ld a,(ix+1)
    cp '0'
    jr nz,forStories
    cp (ix+2) ; other byte is equal
    jr nz,forStories

.checkTyzzyHeader
    in a,(6)
    push af ; Save the current page

    ld a,b ; rom page from earlier
    out (6),a ; Set memory page
    ex af,af' ; save page

    ; skip the symbol table header copy
    ; iy-ix = current header length
    ld hl,iy
    ld bc,ix
    or a
    sbc hl,bc

    ; Load the rom pointer
    ld c,(iy+dataPtrLo)
    ld b,(iy+dataPtrHi)

.romPointerLoaded
    add hl,bc

    ; skip three extra bytes before repeated symbol entry and size header
    ld bc,5
    add hl,bc

    ex de,hl

    ld hl,tyzzy_magic
    ld c,(hl) ; string length
    inc hl ; string pointer
.nextTyzzyHeaderByte
    ld a,(de) ; Load byte of ROM string

    cpi ; Compare byte of magic string
    jr nz,invalidTyzzyHeader
    ; I hate these flag names. It's too easy to confuse p with po/pe
    jp po,validTyzzyHeader

    push bc

    ; if == $8000, reset to $4000 and add page
    inc de ; next byte of ROM string

    ld a,0x80
    cp d

    pop bc
    jr nz,nextTyzzyHeaderByte

.incrementTyzzyHeaderPage
    ld de,0x4000
    ex af,af' ; increment page
    inc a
    out (6),a
    ex af,af'
    jr nextTyzzyHeaderByte

.invalidTyzzyHeader
    pop af ; Get original rom page
    out (6),a
    jp forStories ; continue
.validTyzzyHeader
    pop af ; Get original page
    out (6),a

.addToStoryList
    push de
    ex af,af'
    push af

    ld hl,iy
    ld bc,-nameLength
    or a
    sbc hl,bc
    ex de,hl

    ; Don't order by the name if we're not loading the series of stories
    ld a,(OP1)
    cp AppVarObj
    jr nz,skipNameOrdering

    ; convert name bytes to value
    ld hl,ix
    inc hl
    inc hl

    ld a,(hl)
    sub '0'
    call mult10
    dec hl

    add (hl)
    sub '0'

    jr finishedNameOrdering

.skipNameOrdering
    ; Push into the story list array
    ld a,(storyCount)
.finishedNameOrdering
    add a
    ld hl,storyNames
    add l
    ld l,a
    ld (hl),de

    ; Persist new ROM page
    add a,storySize*2
    ld l,a
    pop bc
    ld (hl),b

    ; Persist new offset
    add a,storySize*2
    ld l,a
    pop de
    inc de
    ld (hl),de

    ld hl,storyCount
    inc (hl)

    jp forStories

.doneStories
    ld iy,_IY_TABLE
    ei
    ret
