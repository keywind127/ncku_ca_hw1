.data
    #array: .word -4, -1, 0, 3, 10
    #array: .word -7, -3, 2, 3, 11
    array: .word -1, 3, 8, 10, 22
    array_size: .word 5
    output_array: .word 0, 0, 0, 0, 0
    #output_answer: .word 0, 1, 9, 16, 100
    #output_answer: .word 4, 9, 9, 49, 121
    output_answer: .word 1, 9, 64, 100, 484
    string_match_message: .asciz "The answer is correct."
    string_mismatch_message: .asciz "The answer is incorrect."
    output_array_final: .word 0, 0, 0, 0, 0
.text
    main:
        la a0, array
        la a1, array_size
        lw a1, 0(a1)
        la a2, output_array
        jal ra, sorted_squares
        la a0, output_array
        la a1, output_answer
        lw a2, array_size
        jal ra, check_result
        bne a0, x0, answer_match
    answer_mismatch:
        la a0, string_mismatch_message
        li a7, 4 
        ecall
        j answer_check_end
    answer_match:
        la a0, string_match_message
        li a7, 4
        ecall
    answer_check_end:
        la a0, output_array
        lw a1, array_size
        jal compute_bytes_needed
        mv a3, a0
        la a0, output_array
        lw a1, array_size
        la a2, output_array_final
        jal move_data
        li a7, 10 
        ecall
    check_result:
        mv t0, x0                                 # t0 = i = 0 
        check_result_loop:
            slt t1, t0, a2                        # t1 = i < n
            beq t1, x0, check_result_loop_end     # terminate loop if i >= n
            slli t1, t0, 2                        # t1 = i << 2
            add t2, a0, t1                        # t2 = &nums + (i << 2)
            add t3, a1, t1                        # t3 = &result + (i << 2)
            lw t2, 0(t2)                          # t2 = nums[i]
            lw t3, 0(t3)                          # t3 = result[i]
            beq t2, t3, continue_loop
            mv a0, x0
            jr ra
        continue_loop:
            addi t0, t0, 1                        # t0 = t0 + 1; i = i + 1
            j check_result_loop
        check_result_loop_end:
            addi a0, x0, 1
            jr ra
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
    sorted_squares:
        mv t0, x0                                 # t0 = 4i = 0
        mv s0, a1                                 # s0 = splitPoint = numsSize
        slli t2, a1, 2                            # t2 = 4n = 4 * numsSize
        loop_for_split_point:
            bge t0, t2, loop_for_split_point_end  # terminate loop if 4i >= 4n
            add t1, a0, t0                        # t2 = &nums + 4i
            lw t1, 0(t1)                          # t2 = nums[i]
            bge t1, x0, after_split_point         # terminate loop if nums[0] >= 0
            addi t0, t0, 4                        # t0 = 4i + 4
            j loop_for_split_point                # repeat loop
            after_split_point:          
                srli s0, t0, 2                    # s0 = 4i / 4 = i 
        loop_for_split_point_end:                 # s0 = right
            addi s1, s0, -1                       # s1 = left = splitPoint - 1   
            mv s2, x0                             # s2 = resIdx = 0
        bidirectional_loop:
            blt s1, x0, bidirectional_loop_end    # terminate loop if left < 0
            slt t1, s0, a1                        # t1 = right < numsSize
            beq t1, x0, bidirectional_loop_end    # terminate loop if right >= numsSize
            slli t0, s1, 2                        # t0 = left << 2
            add t0, a0, t0                        # t0 = &nums + (left << 2)
            lw t0, 0(t0)                          # t0 = nums[left]
            sub t0, x0, t0                        # t0 = -nums[left]
            slli t1, s0, 2                        # t1 = right << 2
            add t1, a0, t1                        # t1 = &nums + (right << 2)
            lw t1, 0(t1)                          # t1 = nums[right] 
            blt t0, t1, select_right               
            mul t2, t1, t1                        # t2 = nums[right] * nums[right]
            addi s0, s0, 1                        # s0 = s0 + 1; right = right + 1
            j after_select
            select_right:
                mul t2, t0, t0                    # t2 = -nums[left] * -nums[left]
                addi s1, s1, -1                   # s1 = s1 - 1; left = left - 1
            after_select:
                slli t0, s2, 2                    # t0 = resIdx << 2
                add t0, a2, t0                    # t0 = &result + (resIdx << 2)
                sw t2, 0(t0)                      # store t2 to result[resIdx]
                addi s2, s2, 1                    # s2 = s2 + 1; resIdx = resIdx + 1
                j bidirectional_loop
        bidirectional_loop_end:
            blt s1, x0, left_directional_end
            slli t0, s1, 2                        # t0 = left << 2
            add t0, a0, t0                        # t0 = &nums + (left << 2)
            lw t0, 0(t0)                          # t0 = nums[left]
            mul t0, t0, t0                        # t0 = nums[left] * nums[left]
            slli t1, s2, 2                        # t1 = resIdx << 2
            add t1, a2, t1                        # t1 = &result + (resIdx << 2)
            sw t0, 0(t1)                          # store t0 to result[resIdx]
            addi s1, s1, -1                       # s1 = s1 - 1; left = left - 1
            addi s2, s2, 1                        # s2 = s2 + 1; resIdx = resIdx + 1
            j bidirectional_loop_end
        left_directional_end:
            slt t0, s0, a1                        # t0 = right < numsSize
            beq t0, x0, right_directional_end     # terminate loop if right >= numsSize
            slli t0, s0, 2                        # t0 = right << 2
            add t0, a0, t0                        # t0 = &nums + (right << 2)
            lw t0, 0(t0)                          # t0 = nums[right]
            slli t1, s2, 2                        # t1 = resIdx << 2
            add t1, a2, t1                        # t1 = &result + (resIdx << 2)
            mul t0, t0, t0                        # t0 = t0 * t0 = nums[right] * nums[right]
            sw t0, 0(t1)                          # store t0 to result[resIdx]
            addi s0, s0, 1                        # s0 = s0 + 1; right = right + 1
            addi s2, s2, 1                        # s2 = s2 + 1; resIdx = resIdx + 1
            j left_directional_end
        right_directional_end:
            jr ra
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
     move_data:
         # a0: num[]
         # a1: num_size
         # a2: res[]
         # a3: num_bits
         li t0, 0                                 # t0 = idx = 0
         move_data_loop:
             slt t1, t0, a1                       # t1 = idx < n 
             beq t1, x0, loop_end                 # terminate loop if (idx >= n)
             slli t1, t0, 2                       # t1 = idx << 2 
             add t1, a0, t1                       # t1 = &nums + (idx << 2)
             lw t1, 0(t1)                         # t1 = nums[idx]
             slti t2, a3, 8                       # t2 = num_bits < 8
             bne t2, x0, store_byte               # store byte if (num_bits < 8)
             slti t2, a3, 16                      # t2 = num_bits < 16
             bne t2, x0, store_half               # store half if (num_bits < 16)
             addi t2, t0, 2                       # t2 = idx << 2
             add t2, a2, t2                       # t2 = res + idx << 2
             sw t1, 0(t2)                         # store nums[idx] to res[idx]
             j end_store
         store_half:
             slli t2, t0, 1                       # t2 = idx << 1
             add t2, a2, t2                       # t2 = res + (idx << 1)
             sh t1, 0(t2)                         # store nums[idx] to res[idx]
             j end_store
         store_byte:
             add t2, a2, t0                       # t2 = res + idx
             sb t1, 0(t2)                         # store nums[idx] to res[idx]
         end_store:
             addi t0, t0, 1                       # t0 = t0 + 1; idx = idx + 1
             j move_data_loop
         loop_end:
             jr ra
