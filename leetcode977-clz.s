.data
    int_list: .word 0, 10, 25
    list_size: .word 3
.text
    main:
        la a0, int_list
        lw a1, list_size
        jal ra, compute_bytes_needed
        li a7, 10 
        ecall
    my_clz:
        my_clz_prologue:
            add t0, x0, a0    # t0 = x
        my_clz_padding:
            srli t1, t0, 1    # t1 = x >> 1
            or t0, t0, t1     # t0 = _x = x | (x >> 1)
            srli t1, t0, 2    # t1 = _x >> 2
            or t0, t0, t1     # t0 = __x = _x | (_x >> 2)
            srli t1, t0, 4    # t1 = __x >> 4
            or t0, t0, t1     # t0 = ___x = __x | (__x >> 4)
            srli t1, t0, 8    # t1 = ___x >> 8
            or t0, t0, t1     # t0 = ____x = ___x | (___x >> 8)
            srli t1, t0, 16   # t1 = ____x >> 16
            or t0, t0, t1     # t0 = p = ____x | (____x >> 16)
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
            jr ra             # return control
    compute_bytes_needed:
        compute_bytes_prologue:
            addi sp, sp, -16                      # update stack position to allocate 4 words 
            sw s0, 0(sp)                          # push s0 to stack  
            sw s1, 4(sp)                          # push s1 to stack
            sw s2, 8(sp)                          # push s2 to stack
            sw ra, 12(sp)                         # push ra to stack 
        compute_bytes_prologue_end:
            mv s0, a0                             # s0 = int_list
            addi s1, a1, -1                       # s1 = idx = n - 1
            slli s1, s1, 2                        # s1 = 4 * idx = 4 * (n - 1)
            li s2, 32                             # s2 = min_leading_zeros
        compute_bytes_loop:
            blt s1, x0, compute_bytes_epilogue    # terminate loop if (idx * 4) < 0
            add t0, s0, s1                        # t0 = &int_list + (idx * 4)
            lw a0, 0(t0)                          # a0 = int_list[idx]
            jal my_clz                            # a0 = num_leading_zeros
            blt s2, a0, skip_update               # skip updating s2 if s2 < a0
            mv s2, a0                             # s2 = a0 = smaller min_leading_zeros
        skip_update:
            addi s1, s1, -4                       # s1 = s1 - 4; 4 * idx = 4 * idx - 4
            j compute_bytes_loop                  # continue loop
        compute_bytes_epilogue:
            li t0, 32                             # t0 = 32 (constant) 
            sub a0, t0, s2                        # a0 = number of bits needed = 32 - min_leading_zeros
            lw s0, 0(sp)                          # pop s0 from stack
            lw s1, 4(sp)                          # pop s1 from stack
            lw s2, 8(sp)                          # pop s2 from stack
            lw ra, 12(sp)                         # pop ra from stack
            addi sp, sp, 16                       # update stack position to deallocate 4 words
            jr ra                                 # return to caller
