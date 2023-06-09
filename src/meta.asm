MODULE _main

PUBLIC dynMemNameLength
PUBLIC dynMemNameOP1
PUBLIC dynMemName
PUBLIC dynMemOffset

PUBLIC stackNameLength
PUBLIC stackNameOP1
PUBLIC stackName

PUBLIC screenBufferNameLength
PUBLIC screenBufferNameOP1
PUBLIC screenBufferName

PUBLIC headerBegin
PUBLIC headerEnd
PUBLIC headerForwardBegin
PUBLIC headerForwardEnd
PUBLIC headerVersion
PUBLIC headerStaticStart
PUBLIC headerPCStart
PUBLIC headerGlobalStart
PUBLIC headerObjectStart
PUBLIC headerAbbrevStart

INCLUDE "Ti83p.def"

SECTION data_compiler
dynMemNameLength:
    defb 0
dynMemNameOP1:
    defb AppVarObj
dynMemName:
    defs 9

stackNameLength:
    defb 0
stackNameOP1:
    defb AppVarObj
stackName:
    defs 9

screenBufferNameLength:
    defb 0
screenBufferNameOP1:
    defb AppVarObj
screenBufferName:
    defs 9

SECTION bss_compiler
dynMemOffset:
    defs 2

SECTION bss_story_header

; In reverse order
headerBegin:
headerRevision:
    defs 2 ; 0x32
headerUnimplemented:
    defs 20 ; 0x1e
headerFileChecksum:
    defs 2 ; 0x1c
headerFileLength:
    defs 2 ; 0x1a
headerAbbrevStart:
    defs 2 ; 0x18
headerUnknown2:
    defs 7 ; 0x11
headerFlags2:
    defs 1 ; 0x10
headerStaticStart:
    defs 2 ; 0x0e
headerGlobalStart:
    defs 2 ; 0x0c
headerObjectStart:
    defs 2 ; 0x0a
headerDictionaryStart:
    defs 2 ; 0x08
headerPCStart:
    defs 2 ; 0x06
headerHiMemoryBase:
    defs 2 ; 0x04
headerUnknown:
    defs 2 ; 0x02
headerFlags:
    defs 1 ; 0x01
headerVersion:
    defs 1 ; 0x00
headerEnd:

headerForwardBegin:
    defs 0x34
headerForwardEnd:
