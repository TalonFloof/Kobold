#include "../IArchitecture.hpp"
#include "../../general/Logging.hpp"
#include "SBI.hpp"
#include "../../general/DeviceTree/DevTree.hpp"

using namespace Kobold;

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

namespace Kobold::Architecture {
    int UseLegacyConsole = 1;

    void EarlyInitialize() {
        // Check if the Debug Console SBI Extension is available, if its not, use the legacy console functions
        SBIReturn hasDebugCon = SBICall1(0x10,3,0x4442434E);
        if(hasDebugCon.value) {
            UseLegacyConsole = 0;
        }
    }

    void Initialize(void* deviceTree) {
        Kobold::DeviceTree::ScanTree(deviceTree);
    }

    void Log(const char* s, size_t l) {
        if(UseLegacyConsole) {
            size_t i;
            for(i = 0; i < l; i++) {
                SBICallLegacy1(1,s[i]);
            }
        } else {
            SBICall3(0x4442434E,0,l,((usize)s) & 0xFFFFFFFF,((usize)s) >> 32);
        }
    }

    void InterruptControl(IntAction action) {
        if(action == YIELD_UNTIL_INTERRUPT) {
            asm volatile("wfi");
        }
    }
}