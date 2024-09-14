#include "DevTree.hpp"
#include "../Memory.hpp"
#include "../Logging.hpp"

using namespace Kobold;

namespace Kobold::DeviceTree {
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

    void ScanTree(void* deviceTree) {
        if(!dtb_init((usize)deviceTree,DeviceTreeOps)) {
            Panic("No Device Tree");
        }
        Logging::Log("DevTree @ %x-%x", (usize)deviceTree, (usize)deviceTree+dtb_query_total_size((usize)deviceTree));
        dtb_node* node = dtb_find("/");
        node = dtb_get_child(node);
        while (node != NULL) {
            dtb_node_stat stat;
            dtb_stat_node(node, &stat);
                
            if(strncmp(stat.name,"memory@",7) == 0) {
                // Memory
                size_t acSize, scSize;
                GetCellSize(node,&acSize,&scSize);
                u64 addr;
                u64 size;
            } else if(strncmp(stat.name,"reserved_memory",15) == 0) {
                // Reserved Memory
            }
            node = dtb_get_sibling(node);
        }
    }
}