#define _DEVTREE_IMPL
#include "DevTree.hpp"
#include "../Memory.hpp"
#include "../Logging.hpp"
#include "../Common.hpp"
#include "../Memory/PFN.hpp"

using namespace Kobold;

extern void* __KERNEL_BEGIN__;
extern void* __KERNEL_END__;

namespace Kobold::DeviceTree {
    u64 CpuSpeed = 0;
    void print_node(dtb_node* node, size_t indent)
{
    const size_t indent_scale = 2;
    if (node == NULL)
        return;

    char indent_buff[indent + 1];
    for (size_t i = 0; i < indent; i++)
        indent_buff[i] = ' ';
    indent_buff[indent] = 0;
    
    dtb_node_stat stat;
    dtb_stat_node(node, &stat);
    Logging::Log("%s| %s: %lu siblings, %lu children, %lu properties.", 
        indent_buff, stat.name, stat.sibling_count, stat.child_count, stat.prop_count);

    for (size_t i = 0; i < stat.prop_count; i++)
    {
        dtb_prop* prop = dtb_get_prop(node, i);
        if (prop == NULL)
            break;
        //NOTE: DO NOT DO THIS! This is a hack for testing purposes for I can make print pretty
        //trees and check all properties are read correctly. There's a reason these structs are
        //opaque to calling code, and their underlying definitions can change at any time.
        const char* name = *(const char**)prop;
        Logging::Log("%s  | %s", indent_buff, name);
    }

    //if(dtb_get_parent(node) == NULL) {
        dtb_node* child = dtb_get_child(node);
        while (child != NULL)
        {
            print_node(child, indent + indent_scale);
            child = dtb_get_sibling(child);
        }
    //}
}

    void GetCellSize(dtb_node* node, size_t* o1, size_t* o2) {
        size_t acSize = 2;
        size_t scSize = 1;
        dtb_prop* p;
        dtb_node* parent = dtb_get_parent(node);
        if(parent != NULL) {
            p = dtb_find_prop(parent,"#address-cells");
            if(p != NULL)
                dtb_read_prop_values(p,1,&acSize);
            p = dtb_find_prop(parent,"#size-cells");
            if(p != NULL)
                dtb_read_prop_values(p,1,&scSize);
        }
        *o1 = acSize;
        *o2 = scSize;
    }

    int FindFirstFree(dtb_pair* freeMemory, int length) {
        for(int i=0; i < length; i++) {
            if(freeMemory[i].a == 0 && freeMemory[i].b == 0)
                return i;
        }
        return -1;
    }

    void Reserve(dtb_pair* freeMemory, int length, dtb_pair reserve) {
        for(int i=0; i < length; i++) {
            if(reserve.a == freeMemory[i].a && reserve.b == freeMemory[i].b) {
                freeMemory[i].a = 0;
                freeMemory[i].b = 0;
                return;
            } else if(freeMemory[i].a < reserve.a && freeMemory[i].b == reserve.b) {
                freeMemory[i].b = reserve.a;
                return;
            } else if(freeMemory[i].a == reserve.a && freeMemory[i].b > reserve.b) {
                freeMemory[i].a = reserve.b;
                return;
            } else if(freeMemory[i].a < reserve.a && freeMemory[i].b > reserve.b) {
                size_t oldEnd = freeMemory[i].b;
                freeMemory[i].b = reserve.a;
                freeMemory[FindFirstFree(freeMemory,length)] = {reserve.b, oldEnd};
                return;
            }
        }
    }

    void ScanTree(void* deviceTree) {
        if(!dtb_init((usize)deviceTree,DeviceTreeOps)) {
            Panic("No Device Tree");
        }
        dtb_node* node = dtb_find("/");
        node = dtb_get_child(node);
        dtb_pair freeMemory[64];
        for(int i=0; i < 64; i++) {
            freeMemory[i].a = 0;
            freeMemory[i].b = 0;
        }
        while (node != NULL) {
            dtb_node_stat stat;
            dtb_stat_node(node, &stat);
                
            if(strncmp(stat.name,"memory",6) == 0) {
                // Memory
                size_t acSize, scSize;
                GetCellSize(node,&acSize,&scSize);
                dtb_prop* ranges = dtb_find_prop(node,"reg");
                int entryCount = dtb_read_prop_pairs(ranges,(dtb_pair) {acSize,scSize},NULL);
                dtb_pair entries[entryCount];
                dtb_read_prop_pairs(ranges,(dtb_pair) {acSize,scSize},(dtb_pair*)&entries);
                for(int i=0; i < entryCount; i++) {
                    freeMemory[FindFirstFree((dtb_pair*)&freeMemory,64)] = {entries[i].a, (entries[i].a+entries[i].b)};
                }
            } else if(strncmp(stat.name,"reserved-memory",15) == 0) {
                // Reserved Memory
                dtb_node* res = dtb_get_child(node);
                while(res != NULL) {
                    size_t acSize, scSize;
                    GetCellSize(res,&acSize,&scSize);
                    dtb_prop* ranges = dtb_find_prop(res,"reg");
                    if(ranges != NULL) {
                        int entryCount = dtb_read_prop_pairs(ranges,(dtb_pair) {acSize,scSize},NULL);
                        dtb_pair entries[entryCount];
                        dtb_read_prop_pairs(ranges,(dtb_pair) {acSize,scSize},(dtb_pair*)&entries);
                        for(int i=0; i < entryCount; i++) {
                            Reserve((dtb_pair*)&freeMemory,64,(dtb_pair) {entries[i].a, (entries[i].a+entries[i].b)});
                        }
                    }
                    res = dtb_get_sibling(res);
                }
            }
            node = dtb_get_sibling(node);
        }
        usize begin = (usize)(&__KERNEL_BEGIN__);
        usize end = (usize)(&__KERNEL_END__);
        Reserve((dtb_pair*)&freeMemory,64,(dtb_pair) {begin,end}); // kernel
        Reserve((dtb_pair*)&freeMemory,64,(dtb_pair) {(usize)deviceTree - 0xffff800000000000, (usize)deviceTree+ALIGN_UP(dtb_query_total_size((usize)deviceTree),4096) - 0xffff800000000000}); // device tree
        for(int i=0; i < 64; i++) {
            if(freeMemory[i].a != 0 && freeMemory[i].b != 0) {
                Logging::Log("mem [%x-%x] Usable", freeMemory[i].a, freeMemory[i].b-1);
            }
        }
        // Now we have constructed a memory map of all of the usable areas, construct our pfn using this
        Memory::Initialize((dtb_pair*)&freeMemory,64);
        node = dtb_find("/cpus");
        u64 freq;
        {
            dtb_prop* p = dtb_find_prop(node,"timebase-frequency");
            dtb_read_prop_values(p,dtb_read_prop_size(p)/4,(size_t*)&freq);
        }
        Logging::Log("Machine Timer @ %i.%i MHz",freq/1000000,(freq/1000)%1000);
        CpuSpeed = freq;
    }
}