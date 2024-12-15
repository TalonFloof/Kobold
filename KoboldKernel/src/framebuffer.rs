use core::ffi::c_void;

pub struct Framebuffer {
    pub ptr: *mut u32,
    pub width: usize,
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
                unsafe { self.ptr.offset((j + i * (self.stride / size_of::<u32>())) as isize).write_volatile(color); }
            }
        }
    }
    pub fn Clear(&mut self, color: u32) {
        self.FillBlit(0,0,self.width,self.height,color);
    }
    pub fn GetImageSize(img: *const c_void) -> (usize, usize) {
        let width = unsafe {*(img as *mut u32)};
        let height = unsafe {*(img as *mut u32).offset(1)};
        return (width as usize, height as usize);
    }
    pub fn DrawImage(&mut self, img: *const c_void, x: usize, y: usize, color: u32) {
        let (width, height) = Framebuffer::GetImageSize(img);
        let adjwidth = width.div_ceil(32) * 32;
        let data = unsafe {(img as *mut u8).byte_offset(8)};
        for i in 0..height {
            for j in 0..adjwidth {
                let offset = i * adjwidth + j;
                let dat = unsafe {*data.byte_offset((offset / 8) as isize)};
                if (dat >> (7 - (offset % 8))) & 1 != 0 {
                    self.FillBlit(j+x,i+y,1,1,color);
                }
            }
        }
    }
    pub fn DrawScaledImage(&mut self, img: *const c_void, x: usize, y: usize, w: usize, h: usize, color: u32) {
        let (width, height) = Framebuffer::GetImageSize(img);
        let adjwidth = width.div_ceil(32) * 32;
        let data = unsafe {(img as *mut u8).byte_offset(8)};
        let x_ratio: usize = ((width << 16) / w) + 1;
        let y_ratio: usize = ((height << 16) / h) + 1;
        for i in 0..h {
            for j in 0..w {
                let final_x: usize = (j * x_ratio) >> 16;
                let final_y: usize = (i * y_ratio) >> 16;
                let offset = final_y * adjwidth + final_x;
                let dat = unsafe {*data.byte_offset((offset / 8) as isize)};
                if (dat >> (7 - (offset % 8))) & 1 != 0 {
                    self.FillBlit(j+x,i+y,1,1,color);
                }
            }
        }
    }
}

pub static mut MAIN_FRAMEBUFFER: Framebuffer = Framebuffer {
    ptr: 0 as *mut u32,
    width: 0,
    height: 0,
    stride: 0,
    bpp: 0,
};

pub fn GetFramebuffer() -> &'static mut Framebuffer {
    return unsafe {(&raw mut MAIN_FRAMEBUFFER).as_mut().unwrap()};
}