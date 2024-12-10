pub struct Framebuffer {
    pub mut ptr: *mut u32,
    pub mut width: usize,
    pub height: usize,
    pub stride: usize,
    pub bpp: usize,
}

impl Framebuffer {
    pub fn FillBlit(&mut self, x: usize, y: usize, w: usize, h: usize, color: u32) {
        for i in y..y+h {
            if i >= self.height {
                break;
            }
            for j in x..x+w {
                if j >= self.width {
                    break;
                }
                unsafe { self.ptr.offset((j + i * (self.stride / size_of::<usize>())) as isize).write_volatile(color); }
            }
        }
    }
    pub fn Clear(&mut self, color: u32) {
        self.FillBlit(0,0,self.width,self.height,color);
    }
    pub fn DrawImage(&self, img: *mut c_void, x: usize, y: usize) {

    }
}