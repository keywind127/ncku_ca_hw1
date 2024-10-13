main:
    li a0, 0x0
    jal ra, my_clz
    li a7, 10 
    ecall
my_clz:
    my_clz_prologue:
        add t0, x0, a0  # t0 = x
    my_clz_padding:
        srli t1, t0, 1  # t1 = x >> 1
        or t0, t0, t1   # t0 = _x = x | (x >> 1)
        srli t1, t0, 2  # t1 = _x >> 2
        or t0, t0, t1   # t0 = __x = _x | (_x >> 2)
        srli t1, t0, 4  # t1 = __x >> 4
        or t0, t0, t1   # t0 = ___x = __x | (__x >> 4)
        srli t1, t0, 8  # t1 = ___x >> 8
        or t0, t0, t1   # t0 = ____x = ___x | (___x >> 8)
        srli t1, t0, 16 # t1 = ____x >> 16
        or t0, t0, t1   # t0 = p = ____x | (____x >> 16)
    my_clz_popcount:
        srli t1, t0, 1    # t1 = p >> 1
        li t2, 0x55555555 # t2 = mask1 = 0b0101_0101_0101_0101_0101_0101_0101_0101
        and t1, t1, t2    # t1 = (p >> 1) & mask1
        sub t0, t0, t1    # t0 = c = p - ((p >> 1) & mask1)
        srli t1, t0, 2    # t1 = c >> 2
        li t2, 0x33333333 # t2 = mask2 = 0b0011_0011_0011_0011_0011_0011_0011_0011
        and t1, t1, t2    # t1 = (c >> 2) & mask2
        and t2, t0, t2    # t2 = c & mask2
        add t0, t1, t2    # t0 = (c >> 2) & mask2 + c & mask2
        srli t1, t0, 4    # t1 = m >> 4
        add t1, t1, t0    # t1 = (m >> 4) + m
        li t2, 0x0F0F0F0F # t2 = mask3 = 0b0000_1111_0000_1111_0000_1111_0000_1111
        and t0, t1, t2    # t0 = e = (((m >> 4) + m) & mask3)
        srli t1, t0, 8    # t1 = e >> 8
        add t0, t0, t1    # t0 = w = e + (e >> 8)
        srli t1, t0, 16   # t1 = w >> 16
        add t0, t0, t1    # t0 = v = w + (w >> 16)
        li t2, 0x3F       # t2 = mask4 = 0b0000_0000_0000_0000_0000_0000_0011_1111
        and t0, t0, t2    # t0 = v & mask4
        li t1, 32         # t1 = 32
        sub a0, t1, t0    # a0 = 32 - (v & mask4)
    my_clz_epilogue:
        jr ra     # return control
