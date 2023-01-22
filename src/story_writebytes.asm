MODULE _main
PUBLIC storyWriteA
PUBLIC storyWriteDE
PUBLIC storyWritebytes

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"

SECTION rodata_compiler
SECTION bss_compiler
SECTION code_compiler

; inputs HL = address to check
; returns NC = address too high
.checkValidDynAddr
    ld bc,(headerStaticStart)

    ; If the address is in static memory, return
    or a
    sbc hl,bc
    add hl,bc
    ret

; Writes value in A to an address in dynamic memory
; inputs A = the value to write
;        HL = the address to write to
.storyWriteA
    call checkValidDynAddr
    ret nc

    ld bc,(dynMemOffset)
    add hl,bc
    ld (hl),a
    ret

; Writes LITTLE endian value in DE to an address in dynamic memory
; as BIG endian
; inputs DE = the LITTLE endian value to write
; inputs HL = the address to write as BIG endian
.storyWriteDE
    call checkValidDynAddr
    ret nc

    ld bc,(dynMemOffset)
    add hl,bc
    ; Endian swap
    ld (hl),d
    inc hl
    ld (hl),e
    ret

.storyWritebytes
    ; FIXME
    ret
