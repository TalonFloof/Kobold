#pragma once
#include "Thread.hpp"
#include "../Lock.hpp"

namespace Kobold::Userspace {
    struct ScheduleQueue {
        Thread* head;
        Thread* tail;
        Kobold::Lock lock = {0,false,false};

        void AddToQueue(Thread* t);
        Thread* PullFromQueue();
    }
}