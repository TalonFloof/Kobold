use alloc::alloc::Layout;
use alloc::alloc::GlobalAlloc;

struct StubAllocator {

}

unsafe impl GlobalAlloc for StubAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        return core::ptr::null_mut();
    }
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        
    }
}

#[global_allocator]
static ALLOCATOR: StubAllocator = StubAllocator {};