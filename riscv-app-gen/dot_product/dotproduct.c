#include <stdint.h>

#define BENCH_ID_ADDR    (*(volatile uint32_t *)0x80010000u)
#define BENCH_DONE_ADDR  (*(volatile uint32_t *)0x80010004u)
#define BENCH_DOTPRODUCT 3u

#define DP_VEC1_BASE     ((volatile int *)0x80010200u)
#define DP_VEC2_BASE     ((volatile int *)0x80010220u)
#define DP_PROD_BASE     ((volatile int *)0x80010240u)
#define DP_RESULT_ADDR   (*(volatile int *)0x80010260u)

int produto_escalar(volatile const int *vetor1, volatile const int *vetor2, volatile int *term_prod) {
    int resultado = 0;
    DP_RESULT_ADDR = 0;
    for (int i = 0; i < 7; i++) {
        int prod = vetor1[i] * vetor2[i];
        term_prod[i] = prod;
        resultado += prod;
        DP_RESULT_ADDR = resultado;
    }
    return resultado;
}

int main(void) {
    BENCH_ID_ADDR   = BENCH_DOTPRODUCT;
    BENCH_DONE_ADDR = 0u;

    const int init_v1[7] = {5, 8, 0, 2, 1, 5, 3};
    const int init_v2[7] = {7, 6, 1, 0, 4, 1, 2};

    for (int i = 0; i < 7; i++) {
        DP_VEC1_BASE[i] = init_v1[i];
        DP_VEC2_BASE[i] = init_v2[i];
    }

    (void)produto_escalar(DP_VEC1_BASE, DP_VEC2_BASE, DP_PROD_BASE);

    BENCH_DONE_ADDR = 1u;
    return 0;
}
