my_clz:
    my_clz_prologue:
        li t0, 0          # t0 = count = 0
        li t1, 0x80000000 # t1 = mask = 0b1000_0000_0000_0000_0000_0000_0000_0000
    my_clz_loop:
        beq t1, x0, my_clz_epilogue
        and t2, t1, a0
        bne t2, x0, my_clz_epilogue
        addi t0, t0, 1
        srli t1, t1, 1
        j my_clz_loop
    my_clz_epilogue:
        mv a0, t0 # a0 = count
        jr ra     # return control
