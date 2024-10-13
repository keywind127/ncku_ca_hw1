fp16_to_fp32:
    fp16_to_fp32_prologue:
        addi sp, sp, -28
        sw ra, 0(sp)
        sw s0, 4(sp)
        sw s1, 8(sp)
        sw s2, 12(sp)
        sw s3, 16(sp)
        sw s4, 20(sp)
        sw s5, 24(sp)
    fp16_to_fp32_prologue_after:
        slli s0, a0, 16   # s0 = w
        li s1, 0x80000000 # s1 = sign mask = 0x80000000
        and s1, s1, s0    # s1 = sign = w & sign_mask(0x80000000)
        li t0, 0x7FFFFFFF # t0 = non_sign mask = 0x7FFFFFFF
        and s0, t0, s0    # s0 = no_sign = w & non_sign_mask(0x7FFFFFFF)
        mv a0, s0         # a0 = s0 = no_sign
        jal ra, my_clz    # a0 = renorm_shift = number of leading zeros
        li s2, 0          # s2 = renorm_shift = 0
        li t0, 5          # t0 = 5
        slt t0, t0, a0    # t0 = 5 < renorm_shift
        beq t0, x0, fp16_to_fp32_post_overflow_check # branch if 5 < renorm_shift
        addi s2, a0, -5                              # s3 = renorm_shift = renorm_shift - 5
    fp16_to_fp32_post_overflow_check:
        li s3, 0x04000000 # s3 = 0x04000000
        add s3, s0, s3    # s3 = no_sign + 0x04000000
        srai s3, s3, 8    # s3 = (no_sign + 0x04000000) >> 8
        li t0, 0x7F800000 # t0 = 0x7F800000
        and s3, s3, t0    # s3 = inf_nan_mask = ((no_sign + 0x04000000) >> 8) & 0x7F800000
        addi s4, s0, -1 # s4 = no_sign - 1
        srli s4, s4, 31 # s4 = zero_mask = (no_sign - 1) >> 31
        sll t0, s0, s2  # t0 = no_sign << renorm_shift
        srli t0, t0, 3  # t0 = (no_sign << renorm_shift) >> 3
        li t1, 0x70     # t1 = 0x70
        sub t1, t1, s2  # t1 = 0x70 - renorm_shift
        slli t1, t1, 23 # t1 = (0x70 - renorm_shift) << 23
        add t0, t0, t1  # t0 = (no_sign << renorm_shift) >> 3 + (0x70 - renorm_shift) << 23
        or t0, t0, s3   # t0 = t0 | inf_nan_mask
        not t1, s4      # t1 = ~zero_mask
        and t0, t0, t1  # t0 = t0 & ~zero_mask
        or a0, s1, t0   # a0 = sign | t0
    fp16_to_fp32_epilogue:
        lw ra, 0(sp)
        lw s0, 4(sp)
        lw s1, 8(sp)
        lw s2, 12(sp)
        lw s3, 16(sp)
        lw s4, 20(sp)
        lw s5, 24(sp)
        addi sp, sp, 28
        jr ra
