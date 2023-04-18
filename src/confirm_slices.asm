MODULE _main
PUBLIC confirmSlices

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/story_slices.inc"

SECTION code_compiler

; Make sure all story slices are present
; Inputs: none
; Returns Z = We're good to go
;         IX = The last two bytes of the last story file's name
.confirmSlices
    ; Largest value
    ld ix,0
    ld de,storyNames

    di
    ; Pointer to largest
    ld iy,de
.nextLargeStory
    ; stop past the end
    ld a,(storyCount)
    add a
    ld hl,storyNames
    add l
    ld l,a

    or a
    sbc hl,de
    add hl,de
    jr z,finishedLargeStories
.getItemPointer
    ex de,hl ; get the item pointer
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ex de,hl
.getNameLength
    ld c,(hl) ; Get the length
    ld b,0
    or a
    sbc hl,bc
.getLastTwoCharacters
    ld c,(hl) ; Get the last two characters
    inc hl
    ld b,(hl)
.checkSize
    ; Check to see if we're larger
    ld hl,ix
    or a
    sbc hl,bc
    add hl,bc

    jr nc,nextLargeStory
.foundLargeStory
    ld ix,bc
    ld iy,de
    jr nextLargeStory
.finishedLargeStories
    ; Get the count and make sure that it matches the largest number
    ld a,(storyCount)
    ld c,a

    ; convert name bytes to value
    ld a,ixh
    sub 'A'
    call mult26

    add ixl
    sub 'A' - 1

    ld iy,_IY_TABLE
    ei

    cp c
    ret
