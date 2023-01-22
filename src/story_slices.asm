MODULE _main
PUBLIC storySize
PUBLIC storyCount
PUBLIC storyNames
PUBLIC storyRomPages
PUBLIC storyOffsets
PUBLIC storyName
PUBLIC storyNameLength
PUBLIC storyNameOP1

INCLUDE "Ti83p.def"

defc storySize = 16
; Total number of items
SECTION bss_compiler
storyCount:
    defs 1
SECTION data_compiler
; First slice name including AppVar byte
storyNameLength:
    defb 0
storyNameOP1:
    defb AppVarObj
storyName:
    defs 9

SECTION bss_story_slices
align 256
; {
    ; Pointers to story name length byte in symbol table. Only names ending in 00
    storyNames: ;^
        defs storySize*2

    ; Used in conjunction with the stories array to index into the actual story files
    ; The low byte contains the page. The high byte can be nonsense
    storyRomPages:
        defs storySize*2

    ; Pointers to the start of the actual story data
    storyOffsets:
        defs storySize*2

    ; FIXME Need start and end zcode addresses
; }
