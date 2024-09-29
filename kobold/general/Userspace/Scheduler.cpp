#include "Scheduler.hpp"

namespace Kobold::Userspace {
    ScheduleQueue schedQueues[16]; // Priorities go from 0-15.

    void ScheduleQueue::AddToQueue(Thread* t) {
        this->lock.Acquire();
        t->nextQueue = NULL;
        if(this->tail != NULL)
            this->tail->nextQueue = t;
        t->prevQueue = this->tail;
        this->tail = t;
        if(this->head == NULL)
            this->head = t;
        this->lock.Release();
    }

    Thread* ScheduleQueue::PullFromQueue() {
        if(this->head == NULL) // Run an initial check before acquiring the lock, this speeds up the process since if it is empty, then an atomic operation can be skipped
            return NULL;
        this->lock.Acquire();
        if(this->head == NULL)
            return NULL;
        Thread* t = this->head;
        t->nextQueue->prevQueue = NULL;
        this->head = t->nextQueue;
        if(this->head == NULL)
            this->tail = NULL;
        t->nextQueue = NULL;
        t->prevQueue = NULL;
        this->lock.Release();
        return t;
    }

    void SaveContext(Architecture::Frame* f, Architecture::FloatFrame *ff) {
        Hart* h = Architecture::GetHartInfo();
        memcpy(&(((Thread*)h->activeThread)->frame),f,sizeof(Architecture::Frame));
        if(ff != NULL)
            memcpy(&(((Thread*)h->activeThread)->floatFrame),ff,sizeof(Architecture::FloatFrame));
    }

    Thread* Schedule() {
        Thread* t;
        for(int i=15; i >= 0; i--) {
            t = schedQueues[i].PullFromQueue();
            if(t == NULL)
                continue;
            Hart* h = Architecture::GetHartInfo();
            h->activeSyscallStack = ((usize)t) + 4096;
            h->activeThread = t;
            Architecture::SwitchPageTable((usize)(t->addrSpace.pointer));
            return t;
        }
        Panic("Schedule Failed");
    }
}