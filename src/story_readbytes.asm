MODULE _main
PUBLIC storyReadbytes

EXTERN storyRomPages
EXTERN l_divu_32_32x16

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/story_slices.inc"

SECTION rodata_compiler
SECTION bss_compiler
SECTION code_compiler

; Copies BC bytes from DEHL Z-address to (IX)
; inputs IX = destination RAM address
;        BC = count of bytes to read
;        DE = Z-address MSB
;        HL = Z-address LSBs
; Note: Based on the function overhead it's most efficient to read 64 bytes at a
; time. I may do this later if I have performance issues, but I won't waste time
; on it now.
.storyReadbytes
    ; Return if zero count
    ld a,b
    or c
    ret z
.haveReadCount

    di
    push ix
    push bc

    ; If DE is non-zero we can't be in dynamic memory
    ld a,d
    or e
    jr nz,skipDynMemOffset

    ; If the dynamic memory is already loaded,
    ; return from DM if the address is low enough
    ld bc,(dynMemOffset)
    ld a,b
    or c
    jr z,skipDynMemOffset

    ; Is the address less than the start of static memory?
    ld de,(headerStaticStart)

    or a
    sbc hl,de
    add hl,de
    jr nc,noDynMemOffset

.getDynMem
    add hl,bc

    pop bc
    pop de
    ldir
    ret

.noDynMemOffset
    ld de,0
.skipDynMemOffset

    ld bc,sliceSize
    call l_divu_32_32x16 ; dehl / bc

    ; L = result, HL' = remainder
    push hl

    ; Preserve the ROM page in AF' and swap in the remainder in HL'
    in a,(6)
    ex af,af'
    exx
    ld bc,hl

    pop iy
    ; IY = story slice, BC = remainder offset
.nextStorySlice
    ; Load ROM page
    ld a,iyl
    add a
    ld hl,storyRomPages
    add l
    ld l,a
    ld a,(hl)

    ; Set ROM page
    out (6),a

    ; Load ROM offset
    ld a,l
    add storySize*2
    ld l,a

    ld e,(hl)
    inc hl
    ld d,(hl)

    ; Remaining byte count for this slice
    ld hl,sliceSize
    or a
    sbc hl,bc
    ld ix,hl

    ; Add remainder to ROM offset
    ex de,hl
    add hl,bc

.popReadCount

    ; Test if read page >= $8000
    ld de,0x8000
    or a
    sbc hl,de
    add hl,de

    pop bc ; count

    jr c,skipIncrementReadPage
.incrementReadPage
    ld de,$4000
    or a
    sbc hl,de

    in a,(6)
    inc a
    out (6),a
.skipIncrementReadPage
    pop de ; dest

.nextStoryByte
    ldi

    ; Test if finished
    jp po,doneStoryReadbytes

    ; Test if we've reached the end of the slice
    dec ix
    ld a,ixl
    or ixh
    jr nz,skipStorySlice
.incrementStorySlice
    push de
    push bc
    ld bc,0
    inc iyl
    jr nextStorySlice
.skipStorySlice

    ; Test if offset == 0x8000 and reset page
    ld a,0x80
    cp h
    jr nz,nextStoryByte
    ld hl,0x4000
    in a,(6)
    inc a
    out (6),a
    jr nextStoryByte

.doneStoryReadbytes
    ; Restore ROM page
    ex af,af'
    out (6),a
    ld iy,_IY_TABLE
    ei
    ret
