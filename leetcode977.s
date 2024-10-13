.data
    array: .word -4, -1, 0, 3, 10
    array_size: .word 5
    output_array: .word 0, 0, 0, 0, 0
.text
    main:
        la a0, array
        la a1, array_size
        lw a1, 0(a1)
        la a2, output_array
        jal ra, sorted_squares
        li a7, 10 
        ecall
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
        loop_for_split_point_end:
            # s0 = right
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
            beq t0, x0, abc                       # terminate loop if right >= numsSize
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
        abc:
            mv a0, a0 
            jr ra
