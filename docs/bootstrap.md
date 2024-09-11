All Arguments relating to stage 1 bootstrap is documented within the `BootParameterMap` C Struct

```c++
struct BootParameterMap {
    u64 magic;
    
    u16 mdtLength;
    void* mdtStart[]; // No actual value, but is used to indicate where the MDT starts
};
```

To describe the memory map of the hardware, the `MachineDescriptorTable` C Struct is used

```c++
struct MachineDescriptorTable {
    u32 nodeCount;
    MDNode mdn[];
};

typedef enum {
    USABLE_MEMORY,
    RESERVED_SPACE,
    PAGE_REFERENCE_TABLE,
} MDNodeType;

struct MDNode {
    char devName[32]; // Can be set to something generic if it isn't for a driver
    MDNodeType type;
    usize addrStart;
    usize addrSize;
};
```

> [!NOTE]    
> Nodes cannot have conflicting memory spaces, for instance if I have a reserved node at `0x1000-0x2000` but have usable memory node from `0x0000-0x10000` the table will be invalid. This goes for when the stage 1 code allocates the `PAGE_REFERENCE_TABLE` type as well

