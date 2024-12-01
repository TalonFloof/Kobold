const std = @import("std");
const hal = @import("../hal.zig");
const limine = @import("limine");
const apic = @import("apic.zig");
const io = @import("io.zig");

export var rsdp_request: limine.RsdpRequest = .{};

const RSDP = extern struct {
    signature: [8]u8 align(1),
    checksum1: u8 align(1),
    OEMID: [6]u8 align(1),
    revision: u8 align(1),
    RSDT: u32 align(1),
    length: u32 align(1),
    XSDT: u64 align(1),
    checksum2: u8 align(1),
    reserved: [3]u8 align(1),

    comptime {
        if (@sizeOf(@This()) != 36) {
            @compileError("RSDP has improper sizing!");
        }
    }
};

pub const Header = extern struct {
    signature: u32 align(1),
    length: u32 align(1),
    revision: u8 align(1),
    checksum: u8 align(1),
    OEM_ID: [6]u8 align(1),
    OEM_table_ID: [8]u8 align(1),
    OEM_revision: u32 align(1),
    creator_ID: u32 align(1),
    creator_revision: u32 align(1),

    comptime {
        if (@sizeOf(@This()) != 0x24) {
            @compileError("ACPI Header has improper sizing!");
        }
    }
};

pub const FADTTable = extern struct {
    acpiHeader: Header align(1),
    facs: u32 align(1),
    dsdt: u32 align(1),

    reserved: u8 align(1),

    preferredManageProfile: u8 align(1),
    sciInt: u16 align(1),
    smiCmdPort: u32 align(1),
    acpiEnable: u8 align(1),
    acpiDisable: u8 align(1),
    s4biosReq: u8 align(1),
    pStateCtrl: u8 align(1),
    pm1aEventBlock: u32 align(1),
    pm1bEventBlock: u32 align(1),
    pm1aCtrlBlock: u32 align(1),
    pm1bCtrlBlock: u32 align(1),
    pm2CtrlBlock: u32 align(1),
    pmTimerBlock: u32 align(1),
    gpe0Block: u32 align(1),
    gpe1Block: u32 align(1),
    pm1EventLength: u8 align(1),
    pm1ControlLength: u8 align(1),
    pm2ControlLength: u8 align(1),
    pmTimerLength: u8 align(1),
    gpe0Length: u8 align(1),
    gpe1Length: u8 align(1),
    gpe1Base: u8 align(1),
    cStateControl: u8 align(1),
    worstC2Latency: u16 align(1),
    worstC3Latency: u16 align(1),
    flushSize: u16 align(1),
    flushStride: u16 align(1),
    dutyOffset: u8 align(1),
    dutyWidth: u8 align(1),
    dayAlarm: u8 align(1),
    monthAlarm: u8 align(1),
    century: u8 align(1),

    bootArchFlags: u16 align(1),

    reserved2: u8 align(1),
    flags: u32 align(1),

    resetAddress: ACPIgas align(1),

    resetValue: u8 align(1),
    reserved3: [3]u8 align(1),
};

pub const ACPIgas = extern struct {
    addrSpaceID: u8 align(1),
    regBitWidth: u8 align(1),
    regBitOffset: u8 align(1),
    addrSize: u8 align(1),
    address: u64 align(1),
};

pub const HPETTable = extern struct {
    acpiHeader: Header align(1),
    hardwareRevId: u8 align(1),
    timerFlags: u8 align(1),
    pciVendorId: u16 align(1),
    addressSpaceId: u8 align(1),
    registerBitWidth: u8 align(1),
    registerBitOffset: u8 align(1),
    reserved2: u8 align(1),
    address: u64 align(1),
    hpetNumber: u8 align(1),
    minimumTick: u16 align(1),
    pageProtection: u8 align(1),
};

pub const MADTTable = extern struct {
    acpiHeader: Header align(1),
    lapicAddr: u32 align(1),
    flags: u32 align(1),
    firstEntry: MADTRecordHeader align(1),
};

pub const MADTRecordHeader = extern struct {
    recordType: u8 align(1),
    recordLength: u8 align(1),
    recordData: u8 align(1), // Is used to get the pointer of the data, this shouldn't be used for any other purpose.
};

pub const MADTIOApicRecord = extern struct {
    id: u8 align(1),
    reserved: u8 align(1),
    addr: u32 align(1),
    gsiBase: u32 align(1),
};

pub const MADTIRQRedirectRecord = extern struct {
    busSource: u8 align(1),
    irqSource: u8 align(1),
    gsi: u32 align(1),
    flags: u16 align(1),
};

pub var usingXSDT: bool = false;
pub var acpiEntries: ?[]align(1) u32 = null;
pub var FADTAddr: ?*FADTTable = null;
pub var MADTAddr: ?*MADTTable = null;
pub var HPETAddr: ?*HPETTable = null;

pub const acpi_log = std.log.scoped(.ACPI);

pub fn init() void {
    hal.debug.NewDebugCommand("shutdown", "Shuts off your device (using a hacky method with ACPI)", &shutdownCommand);
    hal.debug.NewDebugCommand("reboot", "Reboots your device", &rebootCommand);
    if (rsdp_request.response) |rsdp_response| {
        if (@intFromPtr(rsdp_response.address) == 0) {
            hal.HALOops("System does not support ACPI!");
        }
        const rsdp: *RSDP = @as(*RSDP, @ptrCast(rsdp_response.address));
        var rsdt = @as(*Header, @ptrFromInt(@as(usize, @intCast(rsdp.RSDT)) + 0xffff800000000000));
        if (rsdp.revision >= 2) {
            rsdt = @as(*Header, @ptrFromInt(@as(usize, @intCast(rsdp.XSDT)) + 0xffff800000000000));
            usingXSDT = true;
        }
        acpi_log.info("RSDP 0x{x:0>16} (v{d:0>2} {s: <6})", .{ @intFromPtr(rsdp_response.address), rsdp.revision, rsdp.OEMID });
        acpiEntries = @as([*]align(1) u32, @ptrFromInt(@intFromPtr(rsdt) + @sizeOf(Header)))[0..((rsdt.length - @sizeOf(Header)) / 4)];
        acpi_log.info("{s: <4} 0x{x:0>16} (v{d:0>2} {s: <6} {s: <8})", .{ @as([*]u8, @ptrCast(&rsdt.signature))[0..4], @intFromPtr(rsdt), rsdt.revision, rsdt.OEM_ID, rsdt.OEM_table_ID });
        var i: usize = 0;
        while (i < acpiEntries.?.len) {
            const ptr = if (usingXSDT) (@as(usize, @intCast(acpiEntries.?[i])) | (@as(usize, @intCast(acpiEntries.?[i + 1])) << 32)) else @as(usize, @intCast(acpiEntries.?[i]));
            const entry: *Header = @as(*Header, @ptrFromInt(@as(usize, @intCast(ptr)) + 0xffff800000000000));
            acpi_log.info("{s: <4} 0x{x:0>16} (v{d:0>2} {s: <6} {s: <8})", .{ @as([*]u8, @ptrCast(&entry.signature))[0..4], @intFromPtr(entry), entry.revision, entry.OEM_ID, entry.OEM_table_ID });
            if (entry.signature == 0x43495041) {
                MADTAddr = @as(*MADTTable, @ptrCast(entry));
            } else if (entry.signature == 0x54455048) {
                HPETAddr = @as(*HPETTable, @ptrCast(entry));
            } else if (entry.signature == 0x50434146) {
                FADTAddr = @as(*FADTTable, @ptrCast(entry));
            }
            i += if (usingXSDT) 2 else 1;
        }
    } else {
        hal.HALOops("System does not support ACPI!");
    }
    if (MADTAddr) |madt| {
        var entry = &madt.firstEntry;
        while (@intFromPtr(entry) < @intFromPtr(madt) + madt.acpiHeader.length) : (entry = @as(*MADTRecordHeader, @ptrFromInt(@intFromPtr(entry) + entry.recordLength))) {
            if (entry.recordType == 1) { // I/O APIC Record
                const data = @as(*MADTIOApicRecord, @ptrCast(&entry.recordData));
                if (data.gsiBase == 0) {
                    apic.ioapic_regSelect = @as(*allowzero u32, @ptrFromInt(@as(usize, @intCast(data.addr))));
                    apic.ioapic_ioWindow = @as(*allowzero u32, @ptrFromInt(@as(usize, @intCast(data.addr)) + 0x10));
                }
            } else if (entry.recordType == 2) { // I/O APIC IRQ Redirect
                const data = @as(*MADTIRQRedirectRecord, @ptrCast(&entry.recordData));
                apic.ioapic_redirect[data.gsi] = @as(u8, @intCast(data.irqSource));
                if (data.irqSource != data.gsi) {
                    apic.ioapic_redirect[data.irqSource] = 0xff;
                }
                if ((data.flags & 2) != 0) {
                    apic.ioapic_activelow[data.gsi] = true;
                }
                if ((data.flags & 4) != 0) {
                    apic.ioapic_leveltrig[data.gsi] = true;
                }
            }
        }
        if (@intFromPtr(apic.ioapic_regSelect) == 0) {
            hal.HALOops("No I/O APIC was specified in the MADT!");
        }
    } else {
        hal.HALOops("ACPI didn't provide an MADT and we don't know how to parse the MP table (if it even exist!)");
    }
    apic.setup();
}

pub fn rebootCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    _ = iter;
    // Attempt to reboot using ACPI
    if (FADTAddr) |fadt| {
        if (fadt.resetAddress.regBitOffset == 0 and fadt.resetAddress.regBitWidth == 8) {
            if (fadt.resetAddress.addrSpaceID == 0) {
                (@as(*volatile u8, @ptrFromInt(fadt.resetAddress.address))).* = fadt.resetValue;
            } else if (fadt.resetAddress.addrSpaceID == 1) {
                io.outb(@truncate(fadt.resetAddress.address), fadt.resetValue);
            }
        }
    }
    var good: u8 = 0x02; // Attempt reboot using the 8042 gate
    while (good & 0x02 != 0) {
        good = io.inb(0x64);
    }
    io.outb(0x64, 0xFE);
    // That didn't work, try triple faulting
    std.log.debug("If you're seeing this, it's because rebooting failed, please hold the power button until your device turns off.\n", .{});
    hal.arch.memModel.changeTable.?(0);
    (@as(*allowzero volatile u8, @ptrFromInt(0))).* = 0; // For sanity, just in case the table switch didn't work
    while (true) {
        hal.arch.waitForInt();
    }
}

pub fn shutdownCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    _ = iter;
    // The way this works is sort of hacky, we retrieve the data relating to ACPI Sleep State 5 and attempt to follow the instructions for what to do
    // This may not work on all hardware, and is by no means the best way to do this
    const dsdt: *Header = @ptrFromInt(@as(usize, @intCast(FADTAddr.?.dsdt)));
    var count: usize = @sizeOf(Header);
    var slpTypA: u16 = 0;
    var slpTypB: u16 = 0;
    var found: bool = false;
    while (count < dsdt.length) : (count += 1) {
        const ptr = @as([*]u8, @ptrFromInt(@intFromPtr(dsdt)));
        if (std.mem.eql(u8, ptr[count .. count + 4], "_S5_")) {
            if (((ptr[count - 1] == 0x08) or
                ((ptr[count - 2] == 0x08) and
                (ptr[count - 1] == '\\'))) and
                (ptr[count + 4] == 0x12))
            {
                // Skip past the _S5_ and packageOp
                count += 5;
                // Calculate pkgLength size
                count += (((ptr[count] & 0xC0) >> 6) + 2);
                if (ptr[count] == 0x0A)
                    // Skip byte prefix
                    count += 1;
                slpTypA = (@as(u16, @intCast(ptr[count])) << 10);
                count += 1;

                if (ptr[count] == 0x0A)
                    // Skip byte prefix
                    count += 1;

                slpTypB = (@as(u16, @intCast(ptr[count])) << 10);

                found = true;
            }
            break;
        }
    }
    if (found) {
        io.outw(@truncate(FADTAddr.?.pm1aCtrlBlock), (0x2000 | slpTypA));
        if (FADTAddr.?.pm1bCtrlBlock != 0)
            io.outw(@truncate(FADTAddr.?.pm1bCtrlBlock), (0x2000 | slpTypB));
    }
    std.log.debug("(hacky) ACPI Shutdown Failure\n", .{});
}
