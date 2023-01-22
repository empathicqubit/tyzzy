MODULE _main
PUBLIC opcodeNumber
PUBLIC instructionBuffer

PUBLIC opcode
PUBLIC operandTypes
PUBLIC instructionRest
PUBLIC twoOPResult
PUBLIC oneOPResult

PUBLIC zOPcount

PUBLIC zOPs
PUBLIC zOP1
PUBLIC zOP2
PUBLIC zOP3
PUBLIC zOP4
PUBLIC zOP5
PUBLIC zOP6
PUBLIC zOP7
PUBLIC zOP8

PUBLIC zVARs
PUBLIC zVARcount

PUBLIC storyPC

PUBLIC writeVariable
PUBLIC readVariable
PUBLIC doBranch
PUBLIC parseBranchBytes
PUBLIC objectSeek

EXTERN storyWriteDE
EXTERN storyReadbytes
EXTERN failProcessInstruction

INCLUDE "../../src/stack.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/opcodes.inc"

SECTION bss_compiler

; The opcode "number", which is the opcode minus type info
opcodeNumber:
    defs 1

; The bytes at PC
instructionBuffer:
opcode:
    defs 1
operandTypes:
    defs 1
instructionRest:
    defs 8

zOPcount:
    defs 1
zOPs:
zOP1:
    defs 2
oneOPResult:
zOP2:
    defs 2
twoOPResult:
zOP3:
    defs 2
zOP4:
    defs 2
zOP5:
    defs 2
zOP6:
    defs 2
zOP7:
    defs 2
zOP8:
    defs 2

storyPC:
    defs 2

; This should be next to the vars so routine loads are faster
zVARcount:
    defs 1
; These are 15 words
zVARs:
    defs 30

SECTION code_compiler

; Reads a variable
; Inputs C = the variable number to read
;        DE = the destination of the variable contents
.readVariable
    xor a
    or c
    jr nz,notStack
.stack
    call popWord

    ; Save to ops
    ex de,hl ; HL = OPs
    ld (hl),c
    inc hl
    ld (hl),b
    inc hl
    ex de,hl
    ret
.notStack
    cp 0x10
    jr c,local
.global
    ; Get index into globals
    ld b,0
    ld hl,(headerGlobalStart)
    add hl,bc
    add hl,bc

    ; Subtract local value
    ld bc,0x20
    or a
    sbc hl,bc

    ; Read global from the story
    ld ix,de
    ld c,2
    push de
    ld de,0
    call storyReadbytes

    ; Flip the bytes to little endian
    pop hl

    ld d,(hl)
    inc hl
    ld e,(hl)

    ld (hl),d
    dec hl
    ld (hl),e

    ex de,hl
    inc de
    inc de
    ret
.local
    ; Make sure we're not requesting a local that doesn't exist
    ld a,(zVARcount)
    cp c
    ret c

    ; Get index into current variables
    ld hl,zVARs
    ld b,0
    dec c
    add hl,bc
    add hl,bc

    ; Load variable to operand
    ldi
    ldi

    ret

; Inputs: DE = The value to write
;         C = The variable number
; If you thought this code looks a lot like the above read code, you'd be correct
.writeVariable
    xor a
    or c
    jr nz,notWriteStack
.writeStack
    jp pushWord
.notWriteStack
    cp 0x10
    jr c,writeLocal
.writeGlobal
    ; Get index into globals
    ld b,0
    ld hl,(headerGlobalStart)
    add hl,bc
    add hl,bc

    ; Subtract local value
    ld bc,0x20
    or a
    sbc hl,bc

    jp storyWriteDE
.writeLocal
    ; Make sure we're not requesting a local that doesn't exist
    ld a,(zVARcount)
    cp c
    ret c

    ; Get index into current variables
    ld hl,zVARs
    ld b,0
    dec c
    add hl,bc
    add hl,bc

    ld (hl),e
    inc hl
    ld (hl),d
    ret


; Inputs: BC = branch destination without meta bits
; Destroys: BC, HL
.doBranch
    ; Move sign bit
    bit 5,b
    jr z,branchNoSignBit
    ; two's complement
    set 7,b
    set 6,b
.branchNoSignBit
    ld a,b
    or c
    jr z,branchReturnFalse
    ld hl,1
    sbc hl,bc
    add hl,bc
    jr nz,branchNotZeroOne
.branchReturnTrue
    jp op_rtrue
.branchReturnFalse
    jp op_rfalse
.branchNotZeroOne
    ld hl,(storyPC)
    add hl,bc
    dec hl
    dec hl
    ld (storyPC),hl
.doneBranch
    ret


; Gets the branch bytes from current PC
; Inputs: DE = branch byte position
; Returns: BC = The branch bytes without the 2nd byte bit, true/false moved to top bit
; Destroys: HL, BC, DE
.parseBranchBytes
    ld hl,storyPC
    inc (hl)

    ; The branch byte
    ld a,(de)

    ; Check for second branch byte
    bit 6,a
    res 6,a

    jr nz,jeNoSecondBranchByte
    ld b,a
    inc (hl)
    inc de
    ld a,(de)
    ld c,a
    jr doneSecondBranchByte
.jeNoSecondBranchByte
    ; Keep the true/false bit in the hi byte
    ld c,a
    res 7,c
    and 0x80
    ld b,a
.doneSecondBranchByte
    ret

; Inputs: BC = object number
;         DE = header object start
; Returns: HL = Pointer to object
.objectSeek
    dec bc ; Object 0 has no table entry
    ld hl,bc
    add hl,hl ; 2
    add hl,hl ; 4
    add hl,hl ; 8
    add hl,bc ; 9
    inc bc

    push de
    ; Seek to header location
    add hl,de

    ; Skip property defaults table
    ld de,31*2
    add hl,de

    pop de
    ret
