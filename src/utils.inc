; byte swapping macros
macro HLTOED
    ld e,h
    ld d,l
endm

macro HLTOCB
    ld c,h
    ld b,l
endm

macro DETOLH
    ld l,d
    ld h,e
endm

macro DETOCB
    ld c,d
    ld b,e
endm

macro BCTOLH
    ld l,c
    ld h,b
endm

macro BCTOED
    ld e,b
    ld d,c
endm

; longer in-place versions
macro DETOED
    ld a,d
    ld d,e
    ld e,a
endm

macro BCTOCB
    ld a,b
    ld b,c
    ld c,a
endm

macro HLTOLH
    ld a,h
    ld h,l
    ld l,a
endm

EXTERN mult10
EXTERN mult26
EXTERN newLine
EXTERN copyNameToForward
EXTERN copyReverseToForward
EXTERN getKeyOrQuit
EXTERN quitSP
EXTERN scrClr
EXTERN vWrapS
EXTERN vWrapN
EXTERN vWrapMap
