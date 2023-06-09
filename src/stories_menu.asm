MODULE _main
PUBLIC storiesMenu
EXTERN storyNames
EXTERN storyCount
EXTERN __thisDoesntExist__

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"

SECTION rodata_compiler
chooseAStory:
    defm "Choose a story to continue:",0
SECTION bss_compiler

SECTION code_compiler

; inputs: none
; returns HL = pointer to selected item
.storiesMenu
    call scrClr

    ld hl,chooseAStory
    xor a
    call vWrapS

    call newLine
    ld d,0 ; current array index

.nextStory
    ld a,(storyCount)
    cp d

    jr z,donePrintStories

    ld a,d
    add 'a'

    ; Print the number
    push de
    rst 0x28
    defw _VPutMap

    ; Print a paren
    ld a, ')'
    rst 0x28
    defw _VPutMap
    pop af
    push af ; The current index

    add a
    ld hl,storyNames
    add l
    ld l,a

    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ex de,hl ; HL = pointer to string length

    xor a
    ld c,(hl) ; C = string length
    cp c
.nextChar
    jr z,doneChar
    dec hl
    ld a,(hl)
    rst 0x28
    defw _VPutMap
    dec c
    jr nextChar
.doneChar
    pop de
    inc d

    xor a
    ld (penCol),a
    ld a,(penRow)
    add 6
    ld (penRow),a
    jr nextStory
.donePrintStories

.getStorySelection
; Get key and convert to array index
    call getKeyOrQuit
    sub kCapA
    ld b,a

    ; Make sure it's not greater than the end of the list
    ld a,(storyCount)
    cp b

    jr c,getStorySelection
    jr z,getStorySelection

    ld a,b
    add a
    ld hl,storyNames
    add l
    ld l,a
.gotStorySelection
    push hl

    call scrClr

    pop hl
    ret
