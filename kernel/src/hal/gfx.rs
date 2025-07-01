type FillFn = fn(&mut Framebuffer, usize, usize, usize, usize, u32);

pub struct Framebuffer {
    pub pointer: *mut u32,
    pub width: usize,
    pub height: usize,
    pub stride: usize,
    pub bpp: usize,

    fillfn: FillFn,
}

fn fill15(this: &mut Framebuffer, x: usize, y: usize, w: usize, h: usize, color: u32) {
    let red: u32 = (color & 0xf80000u32) >> 9;
    let green: u32 = (color & 0xf800u32) >> 6;
    let blue: u32 = (color & 0xf8u32) >> 3;
    let cvt_color: u16 = (red | green | blue) as u16;
    for i in x..x+w {
        if i >= this.width {
            break;
        }
        for j in y..y+h {
            if j >= this.height {
                break;
            }
            unsafe { (this.pointer as *mut u16).offset((i + j * (this.stride/(this.bpp/8))) as isize).write_volatile(cvt_color); }
        }
    }
}
fn fill32(this: &mut Framebuffer, x: usize, y: usize, w: usize, h: usize, color: u32) {
    for i in x..x+w {
        if i >= this.width {
            break;
        }
        for j in y..y+h {
            if j >= this.height {
                break;
            }
            unsafe { this.pointer.offset((i + j * (this.stride/(this.bpp/8))) as isize).write_volatile(color); }
        }
    }
}

impl Framebuffer {
    pub fn new(pointer: *mut u32, width: usize, height: usize, stride: usize, bpp: usize) -> Self {
        Self {
            pointer: pointer,
            width,
            height,
            stride,
            bpp,

            fillfn: if bpp == 15 { fill15 as FillFn } else { fill32 as FillFn }
        }
    }
}