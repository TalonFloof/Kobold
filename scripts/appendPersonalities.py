import os

koboldEntry = """/Kobold
    comment: Kobold for ${ARCH}
    protocol: limine
    kernel_path: boot():/kernel
    paging_mode: 4level
    kaslr: no

    module_path: boot():/kernel.dbg
    module_cmdline: KernelDebug
"""

file = open("/tmp/kobold_iso/limine.conf","a")
file.write(koboldEntry)
for entry in os.listdir("kobold/zig-out/bin/"):
    if entry[-2:] == ".o":
        file.write("    module_path: boot():/"+entry+"\n")
        file.write("    module_cmdline: "+entry[:-2]+"\n")
file.close()