MODULE _main
PUBLIC processInstruction
PUBLIC failProcessInstruction

EXTERN storyReadbytes

INCLUDE "Ti83p.def"
INCLUDE "../../src/utils.inc"
INCLUDE "../../src/meta.inc"
INCLUDE "../../src/stack.inc"
INCLUDE "../../src/state.inc"
INCLUDE "../../src/opcodes.inc"

SECTION rodata_compiler
SECTION data_compiler
SECTION bss_compiler
SECTION code_compiler

.processInstruction
    ; reset the operand count
    xor a
    ld (zOPcount),a

    ; Read the instruction
    ld ix,instructionBuffer
    ld bc,10
    ld de,0
    ld hl,(storyPC)
    call storyReadbytes
.instructionBuffered

    ld hl,operandTypes ; The operand byte doesn't exist for non-variable command types
    ld a,(opcode)
    ld e,a
    ; Variable short, or long
    bit 7,e
    jr z,twoOp
    bit 6,e
    jr nz,variableOpcode

.shortOpcode
    ld a,e

    bit 5,e
    jr z,oneOp
    bit 4,e
    jr z,oneOp
.zeroOp
    ; Set the type bits for zero ops
    or 0b00110000
    ld (opcodeNumber),a

    ld de,zOPs ; This is so the ldi doesn't fail later
    jp finishedOperands
.oneOp
    ; Set the type bits for one ops
    res 5,a
    set 4,a
    ld (opcodeNumber),a

    rl e
    rl e
    ld c,1
    ld b,e
    jr doneOpcodeType

.twoOp
    ld a,e
    or 0b01100000
    res 7,a
    ld (opcodeNumber),a

    ld c,2
    ld d,c
    ld b,0xff
.getSecondOp
    scf
    rlc b
    rlc b
    rl e
    bit 7,e
    jr z,twoSmallConstant
.twoVariable
    res 0,b
    jr doneSecondOp
.twoSmallConstant
    res 1,b
.doneSecondOp
    dec c
    jr nz,getSecondOp
.doneTwoOp
    scf
    rlc b
    rlc b
    rlc b
    rlc b
    ld c,d
    jr doneOpcodeType

.variableOpcode
    ld a,e
    ld (opcodeNumber),a

    ld hl,instructionRest ; Skip the operand byte
    ld a,(operandTypes)
    ld b,a
    ld c,4

.doneOpcodeType
    ld de,zOPs ; current op

; Figure out the operand types
; B = identifying bits for each type (4 types * 2 bits)
; C = number of operands
;$$00    Large constant (0 to 65535)    2 bytes
;$$01    Small constant (0 to 255)      1 byte
;$$10    Variable                       1 byte
;$$11    Omitted altogether             0 bytes

.nextOperand
    bit 7,b
    jr z,constants
    bit 6,b
    jp nz,finishedOperands

.variable
    push bc
    ld c,(hl) ; Requested variable
    push hl
    call readVariable
    pop hl
    inc hl
    pop bc
    jr doneOperand
.constants
    bit 6,b
    jr nz,smallConstant
.largeConstant
    ; This is to switch the bytes to little endian
    inc de
    ld a,(hl)
    ld (de),a

    inc hl
    dec de

    ldi
    inc bc

    inc de

    jr doneOperand
.smallConstant
    ldi
    inc bc

    ; Clear high byte
    xor a
    ld (de),a

    inc de

.doneOperand

    ld a,(zOPcount)
    inc a
    ld (zOPcount),a

    rl b
    rl b
    dec c
    jp nz,nextOperand
.finishedOperands
    ; Copy three bytes after into OPs, for commands with a result and/or branch
    ldi
    ldi
    ldi
    dec hl
    dec hl
    dec hl

    ; Increment PC by the number of consumed bytes
    ld de,instructionBuffer
    or a
    sbc hl,de
    ex de,hl

    ld hl,(storyPC)
    add hl,de
    ld (storyPC),hl

    ; Set RET to go to end of tests
    ld hl,doneProcessInstruction
    push hl

.jumpInstruction
    ld a,(opcodeNumber)
    cp 0xe2
    jp z,op_storeb
    cp 0xe0
    jp z,op_call
    cp 0x74
    jp z,op_add
    cp 0x61
    jp z,op_je
    cp 0x75
    jp z,op_sub
    cp 0xe1
    jp z,op_storew
    cp 0x9b
    jp z,op_ret
    cp 0x6f
    jp z,op_loadw
    cp 0x9c
    jp z,op_jump
    cp 0x6d
    jp z,op_store
    cp 0x6e
    jp z,op_insert_obj
    cp 0xc9
    jp z,op_and
    cp 0xb2
    jp z,op_print
    cp 0xe6
    jp z,op_print_num
    cp 0x65
    jp z,op_inc_chk
    cp 0x70
    jp z,op_loadb
    cp 0xe5
    jp z,op_print_char
    cp 0xbb
    jp z,op_new_line
    cp 0xb0
    jp z,op_rtrue
    cp 0x6a
    jp z,op_test_attr
    cp 0x90
    jp z,op_jz
    cp 0xe8
    jp z,op_push
    cp 0xe9
    jp z,op_pull
    cp 0x93
    jp z,op_get_parent
    ; FIXME Variable length store. Should it support 3+ args in some way???
    ; I have not encountered that yet
    cp 0xcd
    jp z,op_store
    cp 0x67
    jp z,op_test
    cp 0x92
    jp z,op_get_child
    cp 0xb8
    jp z,op_ret_popped
    cp 0x72
    jp z,op_get_prop_addr
    cp 0xb1
    jp z,op_rfalse
    cp 0x91
    jp z,op_get_sibling
    cp 0x63
    jp z,op_jg
    cp 0xc1
    jp z,op_je
    cp 0xe4
    jp z,op_sread
.unrecognizedInstruction
    pop hl
    jr failProcessInstruction

.doneProcessInstruction
    xor a
    ret

.failProcessInstruction
    ld a,1
    or a
    ret

;      $00 -- $1f  long      2OP     small constant, small constant
;      $20 -- $3f  long      2OP     small constant, variable
;      $40 -- $5f  long      2OP     variable, small constant
;      $60 -- $7f  long      2OP     variable, variable
;      $80 -- $8f  short     1OP     large constant
;      $90 -- $9f  short     1OP     small constant
;      $a0 -- $af  short     1OP     variable
;      $b0 -- $bf  short     0OP
;      except $be  extended opcode given in next byte
;      $c0 -- $df  variable  2OP     (operand types in next byte)
;      $e0 -- $ff  variable  VAR     (operand types in next byte(s))
