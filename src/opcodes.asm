MODULE _main
PUBLIC op_storeb
PUBLIC op_storew
PUBLIC op_loadw
PUBLIC op_loadb
PUBLIC op_call
PUBLIC op_ret
PUBLIC op_add
PUBLIC op_sub
PUBLIC op_je
PUBLIC op_jg
PUBLIC op_jump
PUBLIC op_store
PUBLIC op_insert_obj
PUBLIC op_and
PUBLIC op_print
PUBLIC op_print_num
PUBLIC op_print_char
PUBLIC op_inc_chk
PUBLIC op_new_line
PUBLIC op_rtrue
PUBLIC op_rfalse
PUBLIC op_test_attr
PUBLIC op_jz
PUBLIC op_push
PUBLIC op_pull
PUBLIC op_get_parent
PUBLIC op_test
PUBLIC op_get_child
PUBLIC op_ret_popped
PUBLIC op_get_prop_addr
PUBLIC op_get_sibling
PUBLIC op_sread

EXTERN storyWriteA
EXTERN storyWriteDE
EXTERN storyReadbytes
EXTERN failProcessInstruction
EXTERN loadAndPrintZString
EXTERN ztextBuffer
EXTERN ztextBufferWordCount
EXTERN printZCharacter

EXTERN l_gt

INCLUDE "../../src/state.inc"
INCLUDE "../../src/stack.inc"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "Ti83p.def"

SECTION bss_compiler
sreadLine:
    defs 255 ; FIXME Too big?

SECTION code_compiler

defc attributeByteCount = 4
defc parentObject = attributeByteCount
defc siblingObject = attributeByteCount+1
defc childObject = attributeByteCount+2
defc propertiesPointer = attributeByteCount+3

.op_sread
    call getKeyOrQuit
    sub kCapA-0x41 ; distance between keycodes and ascii codes
    ld bc,(sreadLine)
    ld (hl),a
    call vWrapMap
    jr op_sread

.op_get_prop_addr
    ; Seek to object
    ld bc,(zOP1)
    ld de,(headerObjectStart)
    call objectSeek

    ; Skip to properties pointer
    ld de,propertiesPointer
    add hl,de

    ; Get properties pointer
    ld ix,instructionBuffer+8
    ld bc,2
    ld de,0
    push de
    call storyReadbytes

    ld hl,(instructionBuffer+8)
    HLTOLH

    ; Get text length byte
    ld ix,instructionBuffer+8
    ld bc,1
    pop de
    push hl
    call storyReadbytes
    pop hl

    ; Add text length in words
    ld a,(instructionBuffer+8)
    ld e,a
    ld d,0
    add hl,de
    add hl,de
    inc hl

    ld de,0
    ld bc,1
    ld ix,instructionBuffer+8
    push bc
    push de
    push ix
.nextProperty
    pop ix
    pop de
    pop bc
    push bc
    push de
    push ix

    ; Load size byte
    push hl
    call storyReadbytes
    pop hl

    ; Check if it matches
    ld a,(zOP2)
    ld b,a

    ld a,(instructionBuffer+8)
    ld c,a
    and 0x1f
    jr z,zeroProperty
    cp b
    jr z,doneProperty

    ; Add the property size and continue
    ld a,c
    rlca
    rlca
    rlca
    and 0x07
    ld e,a
    ld d,0

    add hl,de
    inc hl
    inc hl

    jr nextProperty
.zeroProperty
    ld hl,0xffff
.doneProperty
    inc hl

    pop ix
    pop de
    pop bc

    ex de,hl

    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

.done_op_get_prop_addr
    jp writeVariable

.op_get_sibling
    ld de,siblingObject
    jr op_get_object_relation

.op_get_child
    ld de,childObject
    ; Fallthrough

; Inputs DE = The offset of the byte in the object record
.op_get_object_relation
    push de

    ; Seek to object
    ld bc,(zOP1)
    ld de,(headerObjectStart)
    call objectSeek

    ; Skip to child byte
    pop de
    add hl,de

    ; Get child ID
    ld ix,instructionBuffer+8
    ld bc,1
    ld de,0
    call storyReadbytes

    ld a,(instructionBuffer+8)
    ld e,a
    ld d,0

    ; Load storage variable byte
    ld a,(oneOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

    push de
    call writeVariable

    ld de,oneOPResult+1
    call parseBranchBytes

    pop de
    inc e
    dec e
    jr z,objectRelationIsFalse
.objectRelationIsTrue
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.objectRelationIsFalse
    bit 7,b
    res 7,b
    jp z,doBranch
    ret

.op_test
    ld de,twoOPResult
    call parseBranchBytes

    ld hl,(zOP1) ; bitmap
    ld de,(zOP2) ; test flags

    ld a,h
    and d
    cp d
    jr nz,testIsFalse

    ld a,l
    and e
    cp e
    jr nz,testIsFalse
.testIsTrue
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.testIsFalse
    bit 7,b
    res 7,b
    jp z,doBranch
    ret

.op_get_parent
    ; Seek to object
    ld bc,(zOP1)
    ld de,(headerObjectStart)
    call objectSeek

    ; Skip to parent
    ld de,parentObject
    add hl,de

    ld de,0
    ld ix,zOP4
    ld bc,1
    call storyReadbytes

    ; Load storage variable byte
    ld a,(oneOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

    ; Load parent
    ld a,(zOP4)
    ld e,a
    ld d,0
.done_op_get_parent
    jp writeVariable


.op_push
    ld de,(zOP1)
    jp pushWord

.op_pull
    call popWord
    ld de,bc
    ld a,(zOP1)
    ld c,a
    jp writeVariable

.op_test_attr
    ; Load the attribute bytes
    ld bc,(zOP1)
    ld de,(headerObjectStart)
    call objectSeek
.testAttrSeek

    ld de,0
    ld ix,zOP4
    ld bc,attributeByteCount
    call storyReadbytes

    ; rotate to the bit we need
    ld de,(zOP4)
    ld hl,(zOP5)
    ld bc,(zOP2)
    inc c
    dec c
    jr z,skipTestAttrRotate
.testAttrRotate
    ; In big endian order
    rl h
    rl l
    rl d
    rl e
    dec c
    jr nz,testAttrRotate
.skipTestAttrRotate

    push de
    ld de,twoOPResult
    call parseBranchBytes
    pop de

    bit 7,e
    jr z,testAttrIsFalse
.testAttrIsTrue
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.testAttrIsFalse
    bit 7,b
    res 7,b
    jp z,doBranch
    ret

.op_new_line
    jp newLine

.op_print_char
    ld hl,zOP1
    jp printZCharacter

; Increment the variable and test if it's greater
.op_inc_chk
    ; Load the variable reference
    ld hl,zOP1
    ld a,(hl)

    ; read the variable and increment
    ld c,a
    ex de,hl
    push bc
    call readVariable
    ld de,(zOP1)
    inc de

    pop bc
    push de
    call writeVariable

    ld de,twoOPResult
    call parseBranchBytes ; BC = branch bytes

    pop de ; value of variable after inc

    ; Check ops for equality
    ld hl,(zOP2)

    or a
    sbc hl,de
    add hl,de
    jr nc,incChkIsFalse
.incChkIsTrue
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.incChkIsFalse
    bit 7,b
    res 7,b
    jp z,doBranch
    ret

.op_print_num
    ld hl,(zOP1)
    jp vWrapN

.op_print
    ld de,0
    ld hl,(storyPC)
    ld bc,ztextBufferWordCount
    ld ix,ztextBuffer
    call loadAndPrintZString
    ld b,0
    ; FIXME this may wrap weird
    dec c
    or a
    sbc hl,bc
    sbc hl,bc
    ld (storyPC),hl
.done_op_print
    ret

.op_and
    ld hl,(zOP1)
    ld bc,(zOP2)

    ; hi
    ld a,h
    and b
    ld d,a

    ; lo
    ld a,l
    and c
    ld e,a

    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

.done_op_and
    jp writeVariable

; https://www.inform-fiction.org/zmachine/standards/z1point1/sect12.html
; https://www.inform-fiction.org/zmachine/standards/z1point1/sect15.html#insert_obj
.op_insert_obj
    ; Set destination object
    ld bc,(zOP2)
    ld de,(headerObjectStart)

    call objectSeek

    push bc
    push de

    ; Skip to child byte
    ld de,childObject
    add hl,de

    push hl

    ; Get old child ID
    ld ix,instructionBuffer+8
    ld bc,1
    ld de,0
    call storyReadbytes
    pop hl ; Parent: Child ID byte pointer

    ; Set new child ID on parent
    ld bc,(zOP1)
    push bc
    ld a,c
    call storyWriteA

    ; Set sibling and parent on child
    ;;;;;;;;;;;;;;;;;;;;;;
    pop bc ; child object id
    pop de ; header start
    call objectSeek

    ; Skip to parent
    ld de,parentObject
    add hl,de

    pop bc ; Parent ID
    ld d,c

    ; Get old child
    ld a,(instructionBuffer+8)
    ld e,a

    ; Write
.done_op_insert_obj
    jp storyWriteDE

.op_store
    ; Variable number
    ld a,(zOP1)
    ld c,a
    ld de,(zOP2)
    jp writeVariable

.op_storeb
    ; This is duplicated below, but I don't know if it's worth it to make it a call.
    ld hl,(zOP1)
    ld bc,(zOP2)
    add hl,bc

    ld a,(zOP3)
    jp storyWriteA

.op_storew
    ld hl,(zOP1)
    ld bc,(zOP2)
    add hl,bc
    add hl,bc ; word-index*2

    ld de,(zOP3)
    jp storyWriteDE

.op_loadb
    ld hl,(zOP1)
    ld bc,(zOP2)
    add hl,bc

    ld ix,zOP4
    ld bc,1
    ld de,0
    call storyReadbytes
    ld a,(zOP4)
    ld e,a
    ld d,0

    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)
.done_op_loadb
    jp writeVariable

.op_loadw
    ld hl,(zOP1)
    ld bc,(zOP2)
    add hl,bc
    add hl,bc ; word-index*2

    ld ix,zOP3
    ld bc,2
    ld de,0
    call storyReadbytes
    ld de,(zOP3)
    DETOED

    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)
.done_op_loadw
    jp writeVariable

.op_call
    call pushCall

    ; Jump address * 2
    ld hl,(zOP1)
    add hl,hl
    ld (storyPC),hl

    push hl

    ; Read the initial variable values into the variable area
    ld ix,zVARcount
    ld bc,31 ; FIXME should we read all bytes up front or wait to get var count?
    ld de,0
    call storyReadbytes

    pop hl

    ; FIXME zero case?
    ; Fail the call if the number of variables doesn't make sense
    ld a,(zVARcount)
    cp 0x10
    jr c,validVarNum
.invalidVarNum
    pop hl
    ld hl,failProcessInstruction
    push hl
    ret
.validVarNum
    ; Add variable count to storyPC
    ld c,a
    ld b,0
    add hl,bc
    add hl,bc ; They're words
    inc hl ; Variable count byte
    ld (storyPC),hl

    ; Swap all the bytes back
    or a
    jr z,doneInitSwap
    ld hl,zVARs
.nextInitSwap
    ld d,(hl)
    inc hl
    ld e,(hl)

    ld (hl),d
    dec hl
    ld (hl),e

    inc hl
    inc hl

    dec a
    jr nz,nextInitSwap
.doneInitSwap
    ;initialize passed in variables
    ld a,(zOPcount)
    dec a
    ret z
    add a

    ld c,a
    ld b,0
    ld hl,zOP2
    ld de,zVARs
    ldir

.done_op_call
    ret

.op_rtrue
    ld hl,1
    ld (zOP1),hl
    jr op_ret

.op_rfalse
    ld hl,0
    ld (zOP1),hl
    jr op_ret

.op_ret_popped
    call popWord
    ld (zOP1),bc
    jr op_ret

.op_ret
    call popCall

    ; Load storage variable byte
    ld ix,instructionBuffer+8
    ld bc,1
    ld de,0
    ld hl,(storyPC)
    inc hl
    ld (storyPC),hl
    dec hl
    call storyReadbytes

    ld a,(instructionBuffer+8)
    ld c,a
    ld de,(zOP1)
.done_op_ret
    jp writeVariable

.op_add
    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

    ld hl,(zOP1)
    ld de,(zOP2)
    add hl,de
    ex de,hl
.done_op_add
    jp writeVariable

.op_sub
    ; Load storage variable byte
    ld a,(twoOPResult)
    ld c,a
    ld hl,storyPC
    inc (hl)

    ld hl,(zOP1)
    ld de,(zOP2)
    or a
    sbc hl,de
    ex de,hl
.done_op_sub
    jp writeVariable

.op_jump
    ld hl,(storyPC)
    ld de,(zOP1)
    add hl,de
    dec hl
    dec hl
    ld (storyPC),hl
    ret

.op_je
    ; Check ops for equality
    ; If any op is equal with first
    ; then it's true
    ld bc,(zOP1)
    ld de,zOP2

    ld a,(zOPcount)
    ld ixl,a
    dec ixl
    jr z,jeIsFalse
.nextJeOperand
    ex de,hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ex de,hl

    or a
    sbc hl,bc
    add hl,bc
    jr z,jeIsTrue
    dec ixl
    jr nz,nextJeOperand
.jeIsFalse
    ; Uses DE from earlier
    call parseBranchBytes
    bit 7,b
    res 7,b
    jp z,doBranch
    ret
.jeIsTrue
    ; Uses DE from earlier
    call parseBranchBytes
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret

.op_jg
    ld de,twoOPResult
    call parseBranchBytes
    push bc

    ; Check if DE > HL (signed)
    ld de,(zOP1)
    ld hl,(zOP2)

    call l_gt
    ld de,twoOPResult
    jr nc,jgIsFalse
.jgIsTrue
    pop bc
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.jgIsFalse
    pop bc
    bit 7,b
    res 7,b
    jp z,doBranch
    ret

.op_jz
    ld de,zOP2
    call parseBranchBytes

    ; Check op for zero
    ld hl,(zOP1)
    ld a,l
    or h
    jr nz,jzIsFalse
.jzIsTrue
    bit 7,b
    res 7,b
    jp nz,doBranch
    ret
.jzIsFalse
    bit 7,b
    res 7,b
    jp z,doBranch
    ret
