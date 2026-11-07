#include <stdint.h>

#define BENCH_ID_ADDR      (*(volatile uint32_t *)0x80010000u)
#define BENCH_DONE_ADDR    (*(volatile uint32_t *)0x80010004u)
#define BENCH_ARRAYSUM_MUL 4u

#define ASM_VEC1_BASE      ((volatile int *)0x80010300u)
#define ASM_VEC2_BASE      ((volatile int *)0x80010328u)
#define ASM_PROD_BASE      ((volatile int *)0x80010350u)
#define ASM_SUM_BASE       ((volatile int *)0x80010378u)

int main(void) {
    BENCH_ID_ADDR   = BENCH_ARRAYSUM_MUL;
    BENCH_DONE_ADDR = 0u;

    const int init_v1[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 7};
    const int init_v2[10] = {7, 1, 8, 7, 6, 5, 4, 3, 2, 1};

    for (int i = 0; i < 10; i++) {
        ASM_VEC1_BASE[i] = init_v1[i];
        ASM_VEC2_BASE[i] = init_v2[i];
    }

    // Element-wise hardware multiplication (RV32M mul)
    for (int i = 0; i < 10; i++) {
        ASM_PROD_BASE[i] = ASM_VEC1_BASE[i] * ASM_VEC2_BASE[i];
    }

    // Element-wise vector addition
    for (int i = 0; i < 10; i++) {
        ASM_SUM_BASE[i] = ASM_VEC1_BASE[i] + ASM_VEC2_BASE[i];
    }

    BENCH_DONE_ADDR = 1u;
    return 0;
}
