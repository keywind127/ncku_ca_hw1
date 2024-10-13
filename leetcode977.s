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
