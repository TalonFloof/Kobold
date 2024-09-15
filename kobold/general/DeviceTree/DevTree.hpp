#pragma once
#include "smoldtb.hpp"
#include "../Common.hpp"

namespace Kobold::DeviceTree {
    #ifndef _DEVTREE_IMPL
    extern u64 CpuSpeed;
    #endif
    void ScanTree(void* deviceTree);
}