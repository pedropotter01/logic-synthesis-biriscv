// C Program to swap bits in a given number
// Fonte: https://www.geeksforgeeks.org/swap-bits-in-a-given-number/?ref=shm

#include <stdint.h>

#define BENCH_ID_ADDR   (*(volatile uint32_t *)0x80010000u)
#define BENCH_DONE_ADDR (*(volatile uint32_t *)0x80010004u)
#define BENCH_SWAPBITS  5u

#define SB_X_ADDR       (*(volatile uint32_t *)0x80010400u)
#define SB_P1_ADDR      (*(volatile uint32_t *)0x80010404u)
#define SB_P2_ADDR      (*(volatile uint32_t *)0x80010408u)
#define SB_N_ADDR       (*(volatile uint32_t *)0x8001040Cu)
#define SB_SET1_ADDR    (*(volatile uint32_t *)0x80010410u)
#define SB_SET2_ADDR    (*(volatile uint32_t *)0x80010414u)
#define SB_XOR_ADDR     (*(volatile uint32_t *)0x80010418u)
#define SB_RESULT_ADDR  (*(volatile uint32_t *)0x8001041Cu)

unsigned int swapBits(unsigned int x, unsigned int p1, unsigned int p2, unsigned int n) {
    unsigned int mask = (1U << n) - 1U;

    /* Move all bits of first set to rightmost side */
    unsigned int set1 = (x >> p1) & mask;
    SB_SET1_ADDR = set1;

    /* Move all bits of second set to rightmost side */
    unsigned int set2 = (x >> p2) & mask;
    SB_SET2_ADDR = set2;

    /* XOR the two sets */
    unsigned int xor_val = (set1 ^ set2);

    /* Put the xor bits back to their original positions */
    xor_val = (xor_val << p1) | (xor_val << p2);
    SB_XOR_ADDR = xor_val;

    /* XOR with original number so that the two sets are swapped */
    unsigned int result = x ^ xor_val;
    SB_RESULT_ADDR = result;

    return result;
}

int main(void) {
    BENCH_ID_ADDR   = BENCH_SWAPBITS;
    BENCH_DONE_ADDR = 0u;

    unsigned int x  = 28u;
    unsigned int p1 = 0u;
    unsigned int p2 = 3u;
    unsigned int n  = 2u;

    SB_X_ADDR  = x;
    SB_P1_ADDR = p1;
    SB_P2_ADDR = p2;
    SB_N_ADDR  = n;

    (void)swapBits(x, p1, p2, n);

    BENCH_DONE_ADDR = 1u;
    return 0;
}
