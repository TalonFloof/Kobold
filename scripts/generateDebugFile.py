from sys import stdin
import sys

files = {"kernel": []}
curFile = "kernel"
symbolCount = 0

for line in stdin:
    symbol = line.rstrip("\n").split(" ")
    if len(symbol) == 1:
        curFile = symbol[0].rstrip(":").split("/")[-1]
        if curFile[-2:] == ".o":
            curFile = curFile[:-2]
        if len(curFile) > 0 and files.get(symbol[0]) == None:
            files[curFile] = []
    elif len(symbol) >= 4:
        files[curFile].append([int(symbol[0],16),int(symbol[1],16),symbol[2], " ".join(symbol[3:])])
        symbolCount += 1
    elif len(symbol) == 3:
        files[curFile].append([int(symbol[0],16),-1,symbol[1], " ".join(symbol[2:])])
        symbolCount += 1
    else:
        print("Unknown! ", line)
        sys.exit(0)
    
for file in files.keys():
    syms = files[file]
    for i in range(0,len(syms)):
        if syms[i][1] == -1:
            if i+1 < len(syms):
                syms[i][1] = syms[i+1][0]-syms[i][0]
            else:
                syms[i][1] = 0

fileTable = b""
symbolOffset = len(files)*12
alignmentCorrection = int(symbolOffset / 4.0) != (symbolOffset / 4.0)
symbolTable = b""
stringTableOffset = symbolOffset + symbolCount*16
stringTable = b""

def addToStringTable(s: str) -> int:
    global stringTable, stringTableOffset
    oldOffset = stringTableOffset
    b = s.encode("utf-8") + b"\0"
    stringTable += b
    stringTableOffset += len(b)
    return oldOffset

for file in files.keys():
    fileTable += symbolOffset.to_bytes(4,'little',signed=False)
    fileTable += len(files[file]).to_bytes(4,'little',signed=False)
    fileTable += addToStringTable(file).to_bytes(4,'little',signed=False)
    for sym in files[file]:
        symbolTable += sym[0].to_bytes(8,'little',signed=False)
        symbolTable += sym[1].to_bytes(4,'little',signed=False)
        symbolTable += addToStringTable(sym[3]).to_bytes(4,'little',signed=False)
        symbolOffset += 16

f = open(sys.argv[1],"wb")
f.write(b"\x89KbldDbg"+(len(files).to_bytes(8,'little',signed=False))+fileTable)
if alignmentCorrection:
    f.write(b"\x00\x00\x00\x00")
f.write(symbolTable+stringTable)
f.close()