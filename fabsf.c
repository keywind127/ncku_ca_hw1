static inline float fabsf(float x) {
    uint32_t i = *(uint32_t *)&x;  // Read the bits of the float into an integer
    i &= 0x7FFFFFFF;               // Clear the sign bit to get the absolute value
    x = *(float *)&i;              // Write the modified bits back into the float
    return x;
}