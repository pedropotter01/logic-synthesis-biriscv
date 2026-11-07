#include <stdint.h>

#define BENCH_ID_ADDR   (*(volatile uint32_t *)0x80010000u)
#define BENCH_DONE_ADDR (*(volatile uint32_t *)0x80010004u)
#define BENCH_BUBBLESORT 1u

void bubbleSort(int arr[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

int main(void) {
    BENCH_ID_ADDR   = BENCH_BUBBLESORT;
    BENCH_DONE_ADDR = 0u;

    int arr[] = {5, 4, 3, 2, 1, 0, 3};

    bubbleSort(arr, 7);

    BENCH_DONE_ADDR = 1u;
    return 0;
}
