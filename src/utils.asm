MODULE _main
PUBLIC mult10
PUBLIC mult26

PUBLIC oldLine
PUBLIC newLine

PUBLIC copyNameToForward
PUBLIC getKeyOrQuit
PUBLIC quitSP
PUBLIC scrClr
PUBLIC vWrapS
PUBLIC vWrapN
PUBLIC vWrapMap
PUBLIC copyReverseToForward

PUBLIC rstCur
PUBLIC rstCurBottom
PUBLIC rstCurCol

INCLUDE "Ti83p.def"

SECTION bss_compiler
quitSP:
    defs 2

SECTION code_compiler

; destroys a,b
.mult10
    or a
    ret z
    ld b,a
    add a ; *2
    add a ; *4
    add a ; *8
    add b ; *9
    add b ; *10
    ret

; destroys a,b
.mult26
    or a
    ret z
    call mult10
    add b
    add b
    add b ; *13
    add a ; *26
    ret

.lineClr

.scrClr
    rst 0x28
    defw _ClrScrn

    jp rstCur

.rstCur
    xor a
    ld (penCol),a
    ld a,10
    ld (penRow),a
    ret

.rstCurCol
    xor a
    ld (penCol),a
    ret

.rstCurBottom
    xor a
    ld (penCol),a
    ld a,64-6
    ld (penRow),a
    ret

; inputs HL = pointer to null-terminated string
;        A = max number of times to wrap
; Returns C = character didn't fit
.vWrapS
    ld c,a
.vWrapSNext
    ld a,(hl)
    or a
    ret z
    cp 0x0a
    ret z

    rst 0x28
    defw _VPutMap
    jr nc,charFits
.vWrappedS
    dec c
    ret z
    call newLine
    jr vWrapSNext
.charFits
    inc hl
    jr vWrapSNext

; Wrap a single character
; Inputs HL = pointer to the character to put on the screen
; Destroys: everything that VPutMap destroys
.vWrapMap
    ld a,(hl)
    rst 0x28
    defw _VPutMap
    ret nc
    call newLine
    jr vWrapMap

; Prints a number and wraps at the edge of the screen
; Inputs HL = the number to display
; FIXME Doesn't wrap
.vWrapN
    rst 0x28
    defw _SetXXXXOP2

    rst 0x28
    defw _OP2ToOP1

    ld a,8
    rst 0x28
    defw _DispOP1A
    ret

.oldLine
    xor a
    ld (penCol),a
    ld a,(penRow)
    sub 6
    ld (penRow),a
    ret

.newLine
    xor a
    ld (penCol),a
    ld a,(penRow)
    adc 6
    cp 64
    jp nc,rstCur
    ld (penRow),a
    ret

.getKeyOrQuit
    res indicOnly, (IY + indicFlags)

    res lwrCaseActive, (IY + appLwrCaseFlag)
    set shiftAlpha, (IY + shiftFlags)
    set shiftALock, (IY + shiftFlags)
    res shiftLwrAlph, (IY + shiftFlags)

    rst 0x28
    defw _GetKey

    res lwrCaseActive, (IY + appLwrCaseFlag)
    res shiftAlpha, (IY + shiftFlags)
    res shiftALock, (IY + shiftFlags)
    res shiftLwrAlph, (IY + shiftFlags)

    cp kMode
    jr z,quit
    cp kQuit
    ret nz
.quit
    ld sp,(quitSP)
    ret

; Copy the name from the symbol table
; inputs
;   HL = pointer to size of string
;   DE = destination
.copyNameToForward
    push de

    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl ; String pointer

    ld c,(hl) ; String length
    ld b,0

    dec hl

    pop de
    ; Load name of story into OP1
    call copyReverseToForward

    ; Terminate string
    xor a
    ld (de),a
    ret


; Takes a backwards sequence of bytes from the end and writes it forward to a
; new memory location
; inputs
;   BC = length of string
;   HL = pointer to string
;   DE = destination
; outputs DE = the address after the write
.copyReverseToForward
    ldi
    dec hl
    dec hl
    jp pe,copyReverseToForward
    ret
