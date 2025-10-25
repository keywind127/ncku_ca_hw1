
# Assignment1: RISC-V Assembly and Instruction Pipeline
contributed by < [keywind127](https://github.com/keywind127/) >

###### tags: `RISC-V` `computer architecture 2024`
---
## 1. Problem Statement
In this assignment, we are tasked with translating one of the C programs from [Quiz 1](https://hackmd.io/@sysprog/arch2024-quiz1-sol) (either A, B, or C) into [RISC-V](https://en.wikipedia.org/wiki/RISC-V) assembly language. I have chosen to work on ==Problem C==, as it offers a broad range of potential applications, particularly in the area of bitwise operations such as ["counting leading zeros" (CLZ)](https://en.wikipedia.org/wiki/Leading_zero). This function may prove useful for addressing similar problems in future bit-level programming tasks.

### 1.1 `fabsf()` - Absolute Function for Floating Numbers

Problem C requires the implementation of three C programs, starting with the ==absolute value function for floating-point numbers==, `fabsf()`. According to [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) standards, the bit structure of floating-point numbers is organized in a specific format, as illustrated below (**image source**: [GeeksForGeeks](https://www.geeksforgeeks.org/ieee-standard-754-floating-point-numbers/)).
![Screenshot 2024-10-12 142335](https://hackmd.io/_uploads/S1dZL9vyyg.png)

The key distinction between positive and negative numbers lies in the [Most Significant Bit (MSB)](https://en.wikipedia.org/wiki/Bit_numbering), which represents the sign: a 0 for positive and a 1 for negative. The simplest way to convert any number to its positive counterpart is to set the [MSB](https://en.wikipedia.org/wiki/Bit_numbering) to 0, regardless of the values of the other bits. This concept aligns with the C code provided below. The details of implementing this logic in [RISC-V](https://en.wikipedia.org/wiki/RISC-V)  assembly will be examined later in the report.

```c=
static inline float fabsf(float x) {
    uint32_t i = *(uint32_t *)&x; 
    i &= 0x7FFFFFFF;
    x = *(float *)&i;             
    return x;
}
```

### 1.2 `my_clz()` - Counting the Number of Leading Zeros

The `my_clz()` function is designed specifically to ==count the number of leading zeros== in a given number. This functionality is so frequently utilized that it is included as a built-in function in both [GCC](https://en.wikipedia.org/wiki/GNU_Compiler_Collection) and [G++](https://en.wikipedia.org/wiki/GNU_Compiler_Collection).

The following C program provides a straightforward (*but naive*) implementation of [clz](https://en.wikipedia.org/wiki/Leading_zero). It iterates from the [Most Significant Bit (MSB)](https://en.wikipedia.org/wiki/Bit_numbering) to the [Least Significant Bit (LSB)](https://en.wikipedia.org/wiki/Bit_numbering), incrementing the count and halting as soon as a 1 bit is encountered.

```c=
static inline int my_clz(uint32_t x) {
    int count = 0;
    for (int i = 31; i >= 0; --i) {
        if (x & (1U << i))
            break;
        count++;
    }
    return count;
}
```

### 1.3 `fp16_to_fp32()` - Converting Half to Single-Precision Floating Point Numbers

In many fields, particularly [deep learning](https://en.wikipedia.org/wiki/Deep_learning), where [artificial neural networks](https://en.wikipedia.org/wiki/Neural_network_(machine_learning)) are employed, model size often becomes a [bottleneck](https://en.wikipedia.org/wiki/Bottleneck_(software)), leading to slower [training and inference](https://blogs.nvidia.com/blog/difference-deep-learning-training-inference-ai/) due to limited [V-RAM](https://en.wikipedia.org/wiki/Video_random-access_memory). One way to alleviate this issue is by using [half-precision floating-point numbers (fp16)](https://en.wikipedia.org/wiki/Half-precision_floating-point_format) instead of [single-precision (fp32)](https://en.wikipedia.org/wiki/Single-precision_floating-point_format). Although half-precision sacrifices some accuracy, the potential speedup may justify the tradeoff.

The purpose of this function is to convert a floating-point number from [half-precision (fp16)](https://en.wikipedia.org/wiki/Half-precision_floating-point_format) back to [single-precision (fp32)](https://en.wikipedia.org/wiki/Single-precision_floating-point_format). According to the [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) standard (**image source**: [MindSpore](https://www.mindspore.cn/tutorials/zh-CN/br_base/beginner/mixed_precision.html)), [fp16](https://en.wikipedia.org/wiki/Half-precision_floating-point_format) uses 5 exponent bits, compared to the 8 bits used in [fp32](https://en.wikipedia.org/wiki/Single-precision_floating-point_format), and has only 10 [mantissa bits](https://www.geeksforgeeks.org/introduction-of-floating-point-representation/), whereas [fp32](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) uses 23 bits.
![Screenshot 2024-10-12 151413](https://hackmd.io/_uploads/H1S9OsDyye.png)


The following C program implements the `fp16_to_fp32()` function. We will later discuss its translation into [RISC-V asembly](https://en.wikipedia.org/wiki/RISC-V) and examine potential [optimizations](https://en.wikipedia.org/wiki/Program_optimization) that can be leveraged.

```c=
static inline uint32_t fp16_to_fp32(uint16_t h) {
    const uint32_t w = (uint32_t) h << 16;
    const uint32_t sign = w & UINT32_C(0x80000000);
    const uint32_t nonsign = w & UINT32_C(0x7FFFFFFF);
    uint32_t renorm_shift = my_clz(nonsign);
    renorm_shift = renorm_shift > 5 ? renorm_shift - 5 : 0;
    const int32_t inf_nan_mask = ((int32_t)(nonsign + 0x04000000) >> 8) & INT32_C(0x7F800000);
    const int32_t zero_mask = (int32_t)(nonsign - 1) >> 31;
    return sign | ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask);
}
```
---
## 2. RISC-V Implementations and Optimizations
### 2.1 `fabsf()` - Absolute Function for Floating Numbers

According to the [guidelines](https://hackmd.io/@sysprog/2024-arch-homework1) set by the professor, we are prohibited from using [RISC-V instructions with F extensions](https://en.wikipedia.org/wiki/RISC-V). Consequently, the C program must be converted into assembly code under the assumption that we are manipulating the binary data directly.

```c=
static inline uint32_t fabsf(uint32_t x) {          
    return x & 0x7FFFFFFF;
}
```

Assuming that the variable `x` is stored in register `a0`, we apply a 32-bit [mask](https://en.wikipedia.org/wiki/Mask_(computing)) to clear the [sign bit](https://en.wikipedia.org/wiki/Sign_bit) by forcing it to zero. The following [RISC-V](https://en.wikipedia.org/wiki/RISC-V) assembly code represents a direct translation of the C program into assembly.

```asm=
fabsf:
    andi a0, a0, 0x7FFFFFFF # error
    jr ra
```

However, this program cannot be assembled as-is because the `andi` instruction follows the [I-format](https://itnext.io/risc-v-instruction-set-cheatsheet-70961b4bbe8), and the constant `0x7FFFFFFF` is a 32-bit value that exceeds the 12-bit immediate field allowed in the I-format (as shown in the diagram below, **source**: [StackOverflow](https://stackoverflow.com/questions/39427092/risc-v-immediate-encoding-variants)).
![Screenshot 2024-10-12 160914](https://hackmd.io/_uploads/rkp3y3v11l.png)

Fortunately, [RISC-V](https://en.wikipedia.org/wiki/RISC-V) provides the `li` [pseudo-instruction](https://homepage.divms.uiowa.edu/~ghosh/2-2-10.pdf), which can handle 32-bit constants by partitioning them into two parts: a 20-bit upper portion and a 12-bit lower portion. Behind the scenes, it uses the `lui` instruction to load the upper 20 bits and `addi` to incorporate the lower 12 bits into the result.

```asm=
fabsf:
    li t0, 0x7FFFFFFF # 0b0111_1111_1111_1111_1111_1111_1111_1111
    and a0, a0, t0    #                           ^
    jr ra
```

Which is equivalent to:
```asm=
fabsf:
    lui t0, 0x7FFFF     # 0b0111_1111_1111_1111_1111
    addi t0, t0, 0xFFF  # 0b1111_1111_1111
    and a0, a0, t0      
    jr ra
```
To test this function, we implement a simple `main` function, as shown below.
```asm=
main:
    li a0, 0xFFFFFFFF
    jal ra, fabsf
    li a7, 10 
    ecall
fabsf:
    li t0, 0x7FFFFFFF
    and a0, a0, t0
    jr ra
```

The table below provides a [performance benchmark](https://en.wikipedia.org/wiki/Benchmark_(computing)) for this function. For each 32-bit [floating-point number](https://en.wikipedia.org/wiki/Floating-point_arithmetic), represented in [hexadecimal literal](https://en.wikipedia.org/wiki/Hexadecimal) format, the program executes 8 instructions, requiring 18 [clock cycles](https://en.wikipedia.org/wiki/Clock_rate) to complete.

<center>
    
|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|
|18|8|2.25|0.444|3|
    
</center>center>

![2024-10-12 23-31-07](https://hackmd.io/_uploads/SJcwUGdy1x.gif)

### 2.2 `my_clz()` - Counting the Number of Leading Zeros
In this section, we will examine the implementation and optimization of the `my_clz` function, which stands for "[count leading zeros]((https://en.wikipedia.org/wiki/Leading_zero))." To illustrate the optimization process, we will begin with a direct translation of the C code into [RISC-V](https://en.wikipedia.org/wiki/RISC-V) assembly, as shown below.
```asm=
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
```

We will also include a simple `main` function to benchmark the performance of this direct translation approach.

```asm=
main:
    li a0, 0x0
    jal ra, my_clz
    li a7, 10
    ecall
```

Since this algorithm uses [loops](https://skaminsky115.github.io/teaching/cs61c/resources/fa18/Disc04_notes.pdf) that terminate based on the input data, we selected three test values: `0x0`, `0xFFFF`, and `0xFFFFFFFF`. The results are presented in the table below.

<center>
    
|Test Data|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|:-:|
|0x0|==341==|265|1.29|0.777|5|
|0xFFFF|186|142|1.31|0.763|5|
|0xFFFFFFFF|25|13|1.92|0.52|5|
    
</center>

Upon reviewing the assembly code above, we notice ==redundant computations== when checking if a bit is 0 or 1. Specifically, as we iterate from the 31st bit to the 0th bit, the [bitwise shifts](https://en.wikipedia.org/wiki/Bitwise_operation) are recalculated repeatedly, leading to multiple unnecessary `li` instructions. To optimize this, we can ==utilize a single mask==, `0x80000000`, and shift it logically to the right within the loop. The optimized code is shown below.

```asm=
main:
    li a0, 0x0
    jal ra, my_clz
    li a7, 10
    ecall
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
```

The table below shows the [benchmarking](https://en.wikipedia.org/wiki/Benchmark_(computing)) results of the optimized code. Notably, for the [worst-case](https://en.wikipedia.org/wiki/Worst-case_complexity) scenario, the number of [clock cycles](https://en.wikipedia.org/wiki/Clock_rate) decreased from 341 to 277, resulting in a ==19% speedup==. However, the number of [general-purpose registers (GPR)](https://www.geeksforgeeks.org/general-purpose-registers/) used remain the same.

<center>

|Test Data|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|:-:|
|0x0|==277==|201|1.38|0.726|5|
|0xFFFF|152|108|1.41|0.711|5|
|0xFFFFFFFF|23|11|2.09|0.478|5|

</center>
    
Given that `clz` is a widely-used function, it is beneficial to explore further [optimizations](https://en.wikipedia.org/wiki/Program_optimization) through available online resources. I encountered a loopless and [branchless](https://en.algorithmica.org/hpc/pipelining/branchless/) approach that employs two [efficient algorithms](https://en.wikipedia.org/wiki/Algorithmic_efficiency) to enhance the performance of `clz`.

The first algorithm pads all bits to the right of the first non-zero [MSB](https://en.wikipedia.org/wiki/Bit_numbering) by repeatedly mirroring the bits from left to right and applying [bitwise OR operations](https://en.wikipedia.org/wiki/Bitwise_operation). The second algorithm is the well-known `pop_count` ([hamming weight](https://en.wikipedia.org/wiki/Hamming_weight)), which encodes 16 pairs of adjacent bits into their corresponding [binary representation](https://en.wikipedia.org/wiki/Binary_number) of the number of 1 bits. These counts are then accumulated to determine the total number of 1 bits in the 32-bit [word](https://en.wikipedia.org/wiki/Word_(computer_architecture)).

<center>
    
|Bit-1-Before|Bit-0-Before|Bit-1-After|Bit-0-After|
|:-:|:-:|:-:|:-:|
|0|0|0|0|
|0|1|0|1|
|1|0|0|1|
|1|1|1|0|
    
</center>

According to the [truth table](https://en.wikipedia.org/wiki/Truth_table) above, the encoding process involves subtracting the [Most Significant Bit (MSB)](https://en.wikipedia.org/wiki/Bit_numbering) of each pair of bits from the pair itself.

Since this method ensures that there are no zeros beyond the [leading zeros](https://en.wikipedia.org/wiki/Leading_zero), the final result for the number of [leading zeros](https://en.wikipedia.org/wiki/Leading_zero) is calculated as 32 minus the [population count](https://en.wikipedia.org/wiki/Hamming_weight).
    
```asm=
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
```

The table below presents the [performance benchmarks](https://en.wikipedia.org/wiki/Benchmark_(computing)) for the [optimized](https://en.wikipedia.org/wiki/Program_optimization) `clz` algorithm. While the [best-case](https://www.geeksforgeeks.org/worst-average-and-best-case-analysis-of-algorithms/) (`0xFFFFFFFF`) performance slightly declined, most other cases, including `0x0` and `0xFFFF`, showed significant improvement. Notably, the original [worst-case](https://www.geeksforgeeks.org/worst-average-and-best-case-analysis-of-algorithms/) scenario improved from 277 [clock cycles](https://en.wikipedia.org/wiki/Clock_rate) to just 50, representing an ==82% speedup== compared to the previous version and an ==85% speedup== compared to the naive, direct translation.

<center>

|Test Data|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|:-:|
|0x0|==50==|40|1.25|1.25|5|
|0xFFFF|51|41|1.24|0.804|5|
|0xFFFFFFFF|50|40|1.25|0.8|5|

</center>
    
![My Video2](https://hackmd.io/_uploads/rJO8-kYk1x.gif)

### 2.3 `fp16_to_fp32()` - Converting Half to Single-Precision Floating Point Numbers

The function `fp16_to_fp32` converts a 16-bit [half-precision floating-point number (fp16)](https://en.wikipedia.org/wiki/Half-precision_floating-point_format) to a 32-bit [single-precision floating-point number (fp32)](https://en.wikipedia.org/wiki/Single-precision_floating-point_format). It first extends the 16-bit number to 32 bits, separating the [sign, exponent, and mantissa](https://en.wikipedia.org/wiki/IEEE_754). 

The [sign](https://en.wikipedia.org/wiki/Sign_bit) is isolated and placed in the [most significant bit](https://en.wikipedia.org/wiki/Bit_numbering), while the [mantissa and exponent](https://en.wikipedia.org/wiki/IEEE_754) are normalized based on their values. Special cases such as [NaN](https://en.wikipedia.org/wiki/NaN), infinity, and zero are handled using specific [masks](https://en.wikipedia.org/wiki/Mask_(computing)), ensuring proper conversion by adjusting the [exponent bias](https://en.wikipedia.org/wiki/IEEE_754) and handling denormalized numbers through [bit shifting](https://www.interviewcake.com/concept/java/bit-shift). Finally, the components are combined to form the [fp32](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) result.

```asm=
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
        li s2, 0x7FFFFFFF # s2 = non_sign mask = 0x7FFFFFFF
        and s2, s2, s0    # s2 = no_sign = w & non_sign_mask(0x7FFFFFFF)
        mv a0, s2         # a0 = s2 = no_sign
        jal ra, my_clz    # a0 = renorm_shift = number of leading zeros
        li s3, 0          # s3 = renorm_shift = 0
        li t0, 5          # t0 = 5
        slt t0, t0, a0    # t0 = 5 < renorm_shift
        beq t0, x0, fp16_to_fp32_post_overflow_check # branch if 5 < renorm_shift
        addi s3, a0, -5                              # s3 = renorm_shift = renorm_shift - 5
    fp16_to_fp32_post_overflow_check:
        li s4, 0x04000000 # s4 = 0x04000000
        add s4, s2, s4    # s4 = no_sign + 0x04000000
        srli s4, s4, 8    # s4 = (no_sign + 0x04000000) >> 8 # buggy!!!
        li t0, 0x7F800000 # t0 = 0x7F800000
        and s4, s4, t0    # s4 = inf_nan_mask = ((no_sign + 0x04000000) >> 8) & 0x7F800000
        addi s5, s2, -1 # s5 = no_sign - 1
        srli s5, s5, 31 # s5 = zero_mask = (no_sign - 1) >> 31
        sll t0, s2, s3  # t0 = no_sign << renorm_shift
        srli t0, t0, 3  # t0 = (no_sign << renorm_shift) >> 3
        li t1, 0x70     # t1 = 0x70
        sub t1, t1, s3  # t1 = 0x70 - renorm_shift
        slli t1, t1, 23 # t1 = (0x70 - renorm_shift) << 23
        add t0, t0, t1  # t0 = (no_sign << renorm_shift) >> 3 + (0x70 - renorm_shift) << 23
        or t0, t0, s4   # t0 = t0 | inf_nan_mask
        not t1, s5      # t1 = ~zero_mask
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
```

The program above is a direct translation of the C code into [RISC-V assembly](https://en.wikipedia.org/wiki/RISC-V). Although it appears correct at first glance, there is a significant [bug](https://en.wikipedia.org/wiki/Software_bug) in the code. In the original C code, the expression `(int32_t)(nonsign + 0x04000000) >> 8` casts an [unsigned number](https://en.wikipedia.org/wiki/Signed_number_representations) to a [signed integer](https://en.wikipedia.org/wiki/Signed_number_representations) before performing a [right shift](https://en.wikipedia.org/wiki/Bitwise_operation). Since the result could be negative, [sign extension](https://en.wikipedia.org/wiki/Sign_extension) is mistakenly omitted in the assembly translation.

<center>
    
|Instruction|Output Hexadecimal Literal|
|:-:|:-:|
|**srli**|0x00830100|
|**srai**|0xFF830100|

</center>

This issue can be easily resolved by replacing the `srli` instruction with `srai`, which stands for =="shift right **arithmetic** immediate"== and ensures proper [sign extension](https://en.wikipedia.org/wiki/Sign_extension). The corrected code is shown below.

```asm=
main:
    li a0, 0xFFFFFFFF
    jal ra, fp16_to_fp32
    li a7, 10 
    ecall
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
        li s2, 0x7FFFFFFF # s2 = non_sign mask = 0x7FFFFFFF
        and s2, s2, s0    # s2 = no_sign = w & non_sign_mask(0x7FFFFFFF)
        mv a0, s2         # a0 = s2 = no_sign
        jal ra, my_clz    # a0 = renorm_shift = number of leading zeros
        li s3, 0          # s3 = renorm_shift = 0
        li t0, 5          # t0 = 5
        slt t0, t0, a0    # t0 = 5 < renorm_shift
        beq t0, x0, fp16_to_fp32_post_overflow_check # branch if 5 < renorm_shift
        addi s3, a0, -5                              # s3 = renorm_shift = renorm_shift - 5
    fp16_to_fp32_post_overflow_check:
        li s4, 0x04000000 # s4 = 0x04000000
        add s4, s2, s4    # s4 = no_sign + 0x04000000
        srai s4, s4, 8    # s4 = (no_sign + 0x04000000) >> 8
        li t0, 0x7F800000 # t0 = 0x7F800000
        and s4, s4, t0    # s4 = inf_nan_mask = ((no_sign + 0x04000000) >> 8) & 0x7F800000
        addi s5, s2, -1 # s5 = no_sign - 1
        srli s5, s5, 31 # s5 = zero_mask = (no_sign - 1) >> 31
        sll t0, s2, s3  # t0 = no_sign << renorm_shift
        srli t0, t0, 3  # t0 = (no_sign << renorm_shift) >> 3
        li t1, 0x70     # t1 = 0x70
        sub t1, t1, s3  # t1 = 0x70 - renorm_shift
        slli t1, t1, 23 # t1 = (0x70 - renorm_shift) << 23
        add t0, t0, t1  # t0 = (no_sign << renorm_shift) >> 3 + (0x70 - renorm_shift) << 23
        or t0, t0, s4   # t0 = t0 | inf_nan_mask
        not t1, s5      # t1 = ~zero_mask
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
```

The subsequent table depicts the performance of this algorithm based on various metrics.

<center>
    
|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|
|104|87|1.2|0.837|10|
    
</center>

From the code above, we can see that the `s0` register is only used in the first few [instructions](https://en.wikipedia.org/wiki/Assembly_language), suggesting that it can be reused later. Additionally, we can utilize a [temporary register](https://en.wikipedia.org/wiki/Processor_register) `t0` to store the [hexadecimal literal](https://en.wikipedia.org/wiki/Hexadecimal) `0x7FFFFFFF`, which can be discarded afterward. Since `s2` is no longer needed, we can rename registers: `s3` to `s2`, `s4` to `s3`, and `s5` to `s4`. Consequently, we can eliminate the need to push and pop the `s5` register to and from the [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)). The [optimized code](https://en.wikipedia.org/wiki/Program_optimization) is shown below.

```asm=
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
```

The [optimized code](https://en.wikipedia.org/wiki/Program_optimization) takes 102 [clock cycles](https://en.wikipedia.org/wiki/Clock_rate) to finish, which is 2 [clock cycles](https://en.wikipedia.org/wiki/Clock_rate) faster than the original code.

<center>

|Clock Cycles #|Instructions #|CPI|IPC|Used GPR #|
|:-:|:-:|:-:|:-:|:-:|
|==102==|==85==|1.2|0.833|9|
    
</center>

![My Video3](https://hackmd.io/_uploads/BJlXcWFk1x.gif)

--- 

## 3. LeetCode 977 - Squares of A Sorted Array

### 3.1 Problem Description
Given an integer array nums sorted in non-decreasing order, return an array of the squares of each number sorted in non-decreasing order.

### 3.2 C Program Implementation

The most straightforward solution to this problem is to iterate through the array, square each number, and then apply a [sorting algorithm](https://en.wikipedia.org/wiki/Sorting_algorithm) to obtain the result in non-decreasing order. However, this approach is suboptimal because it involves sorting the array, which, when using [merge sort](https://en.wikipedia.org/wiki/Merge_sort), results in a [time complexity](https://en.wikipedia.org/wiki/Time_complexity) of $O(nlogn)$.

A more efficient approach is to locate the separation point between negative and non-negative numbers and use three index counters: one to move left and two to move right. We then compare the squared values and store the larger one in the result array. The following is the C implementation.

```c=
int min(int a, int b) {
    return a < b ? a : b;
}
int* sortedSquares(int* nums, int numsSize, int* returnSize) {
    int* result = (int*) malloc(sizeof(int) * numsSize);
    int splitPoint = numsSize;
    for (int i = 0; i < numsSize; ++i) {
        if (nums[i] >= 0) {
            splitPoint = i;
            break;
        }
    }
    int res = 0, left = splitPoint - 1, right = splitPoint;
    while (left >= 0 && right < numsSize) {
        if (-nums[left] < nums[right]) 
            result[res++] = nums[left] * nums[left--];
        else 
            result[res++] = nums[right] * nums[right++];
    }
    while (left >= 0) 
        result[res++] = nums[left] * nums[left--];
    while (right < numsSize) 
        result[res++] = nums[right] * nums[right++];
    *returnSize = numsSize;
    return result;
}
```

### 3.3 RISC-V Implementation

In the C program, memory was allocated on the [heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) using `malloc`, with the assumption that the caller would remember to free the [allocated memory](https://en.wikipedia.org/wiki/Memory_management). However, in the [RISC-V program](https://en.wikipedia.org/wiki/RISC-V), [allocating memory](https://en.wikipedia.org/wiki/Memory_management) on the [heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) is more complex because it requires making [OS calls](https://en.wikipedia.org/wiki/System_call), which are not supported in Ripes. As a result, I opted to store the result in memory allocated in the data section, which resides on the [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)). The following is the [RISC-V](https://en.wikipedia.org/wiki/RISC-V) code implementation with automated error checking.

```asm=
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
```

### 3.4 RISC-V Implementation with CLZ Optimization

In the above code, since we are storing the squared values in an independent array, it is advantageous to dynamically determine the number of [bytes](https://en.wikipedia.org/wiki/Byte) needed for storage. This can be achieved by calculating the smallest [CLZ (Count Leading Zeros)](https://en.wikipedia.org/wiki/Leading_zero) values within the array. Since the squared numbers are always positive, we can [optimize](https://en.wikipedia.org/wiki/Program_optimization) storage by using a [byte](https://en.wikipedia.org/wiki/Byte) if the number is greater than 24 bits (ensuring the [MSB](https://en.wikipedia.org/wiki/Bit_numbering) remains 0 for positive values), a [half-word](https://en.wikipedia.org/wiki/Word_(computer_architecture)) if it exceeds 16 bits, and a [full word](https://en.wikipedia.org/wiki/Word_(computer_architecture)) if it is less than or equal to 16 bits.

```asm=
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
```

For the test data `[-4, -1, 0, 3, 10]`, the output becomes `[0, 1, 9, 16, 100]`. The table below shows the number of [bytes](https://en.wikipedia.org/wiki/Byte) required to store the resulting array. As indicated, the minimum [CLZ](https://en.wikipedia.org/wiki/Leading_zero) score is 25, which exceeds 24, meaning a single [byte](https://en.wikipedia.org/wiki/Byte) per number suffices.

<center>

|Decimal|Hexadecimal|CLZ|Unit Needed|Data in Memory|
|:-:|:-:|:-:|:-:|:-:|
|0|0x0|32|Byte|0x00|
|1|0x1|31|Byte|0x01|
|9|0x9|28|Byte|0x09|
|16|0x10|27|Byte|0x10|
|100|0x64|25|Byte|0x64|
    
</center>

We can now examine the memory to confirm that the data is stored as [bytes](https://en.wikipedia.org/wiki/Byte). The screenshot below verifies that the array has been compressed using smaller units without any loss of information.

![Screenshot 2024-10-14 133159](https://hackmd.io/_uploads/Sy4zT7qJJx.png)

For the test data `[-1, 3, 8, 10, 22]`, the output becomes `[1, 9, 64, 100, 484]`. The table demonstrates that the minimum [CLZ](https://en.wikipedia.org/wiki/Leading_zero) is 23, which is less than 24, requiring a [half-word](https://en.wikipedia.org/wiki/Word_(computer_architecture)) unit to store each element of the array.

<center>

|Decimal|Hexadecimal|CLZ|Unit Needed|Data in Memory|
|:-:|:-:|:-:|:-:|:-:|
|1|0x1|31|Byte|0x0001|
|9|0x9|28|Byte|0x0009|
|64|0x40|28|Byte|0x0040|
|100|0x64|25|Byte|0x0064|
|==484==|==0x1E4==|==23==|==Half Word==|==0x01E4==|
    
</center>

The screenshot below confirms that the data is indeed stored as [half-words](https://en.wikipedia.org/wiki/Word_(computer_architecture)) in memory.

![Screenshot 2024-10-14 132436](https://hackmd.io/_uploads/ry2cnXcyyx.png)
