my_clz:
    my_clz_prologue:
        li t0, 0  # t0 = count = 0
        li t1, 31 # t1 = i = 31
    my_clz_loop:
        blt t1, x0, my_clz_epilogue # exit loop if i < 0
        li t2, 1                    # t2 = 1
        sll t2, t2, t1              # t2 = 1 << i
        and t2, t2, a0              # t2 = x & (1 << i)
        bne t2, x0, my_clz_epilogue # exit loop if t2 is true
        addi t0, t0, 1              # t0 = t0 + 1 = count + 1
        addi, t1, t1, -1            # t1 = t1 - 1 = i - 1
        j my_clz_loop
    my_clz_epilogue:
        mv a0, t0 # a0 = count
        jr ra     # return control
end:
    li, t0, 1