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
