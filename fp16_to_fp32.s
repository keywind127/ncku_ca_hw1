.data
    #input_data: .word 0xFFFF
    #input_data: .word 0xF0FF
    input_data: .word 0x744F
    #output_data: .word 0xFFFFE000
    #output_data: .word 0xC61FE000
    output_data: .word 0x4689E000
    mismatch_message: .asciz "The answer is incorrect.\n"
    match_message: .asciz "The answer is correct.\n"
.text
    main:
        la a0, input_data 
        lw a0, 0(a0)
        jal fp16_to_fp32
        la a1, output_data
        lw a1, 0(a1)
        check_answer:
            beq a0, a1, answer_match
            la a0, mismatch_message
            li a7, 4
            ecall
            j answer_match_end
        answer_match:
            la a0, match_message
            li a7, 4
            ecall
        answer_match_end:
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
    fp16_to_fp32:
        fp16_to_fp32_prologue:
            addi sp, sp, -24
            sw ra, 0(sp)
            sw s0, 4(sp)
            sw s1, 8(sp)
            sw s2, 12(sp)
            sw s3, 16(sp)
            sw s4, 20(sp)
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
            addi sp, sp, 24
            jr ra
