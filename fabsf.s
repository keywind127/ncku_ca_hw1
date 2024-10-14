.data 
    #input_word: .word 0xFFFFFFFF
    #input_word: .word 0xc1411eb8
    input_word: .word 0x40490e56
    #output_word: .word 0x7FFFFFFF
    #output_word: .word 0x41411eb8
    output_word: .word 0x40490e56
    string_match_message: .asciz "The answer is correct."
    string_mismatch_message: .asciz "The answer is incorrect."
.text
    main:
        la a0, input_word
        lw a0, 0(a0)
        jal ra, fabsf
        la a1, output_word
        lw a1, 0(a1)
        beq a0, a1, answer_match
        answer_mismatch:
            la a0, string_mismatch_message
            li a7, 4
            ecall
            j answer_match_end
        answer_match:
            la a0, string_match_message
            li a7, 4
            ecall
        answer_match_end:
            li a7, 10 
            ecall
    fabsf:
        li t0, 0x7FFFFFFF
        and a0, a0, t0
        jr ra
