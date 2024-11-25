pub const XHCICapRegs = extern struct {
    caplength: u8 align(1) = undefined,
    reserved: u8 align(1) = undefined,
    version: u16 align(1) = undefined,
    hcsparams1: u32 align(1) = undefined,
    hcsparams2: u32 align(1) = undefined,
    hcsparams3: u32 align(1) = undefined,
    hccparams1: u32 align(1) = undefined,
    dboff: u32 align(1) = undefined,
    rtsoff: u32 align(1) = undefined,
    hccparams2: u32 align(1) = undefined,
};

pub const XHCIPortRegs = extern struct {
    portsc: u32 align(4) = undefined,
    portpmsc: u32 align(1) = undefined,
    portli: u32 align(1) = undefined,
    reserved: u32 align(1) = undefined,
};

pub const XHCIOperationRegs = extern struct {
    usbcmd: u32 align(8) = undefined,
    usbsts: u32 align(1) = undefined,
    page_size: u32 align(1) = undefined,
    reserved1: [0x14 - 0x0C]u8 align(1) = undefined,
    dnctrl: u32 align(1) = undefined,
    crcr: u64 align(1) = undefined,
    reserved2: [0x30 - 0x20]u8 align(1) = undefined,
    dcbaap: u64 align(1) = undefined,
    config: u32 align(1) = undefined,
    reserved3: [964]u8 align(1) = undefined,
    ports: [256]XHCIPortRegs align(4) = undefined,
};
