#include <stdint.h>

// Fonte: https://www.geeksforgeeks.org/quick-sort-algorithm/

#define BENCH_ID_ADDR   (*(volatile uint32_t *)0x80010000u)
#define BENCH_DONE_ADDR (*(volatile uint32_t *)0x80010004u)
#define BENCH_QUICKSORT 2u
#define QS_ARRAY_BASE   ((int *)0x80010100u)

void swap(int *a, int *b) {
    int t = *a;
    *a = *b;
    *b = t;
}

int partition(int arr[], int low, int high) {
    int pivot = arr[high];
    int i = low - 1;

    for (int j = low; j <= high - 1; j++) {
        if (arr[j] < pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }

    swap(&arr[i + 1], &arr[high]);
    return i + 1;
}

void quickSort(int arr[], int low, int high) {
    if (low < high) {
        int pi = partition(arr, low, high);
        quickSort(arr, low, pi - 1);
        quickSort(arr, pi + 1, high);
    }
}

int main(void) {
    BENCH_ID_ADDR   = BENCH_QUICKSORT;
    BENCH_DONE_ADDR = 0u;

    const int init_vals[6] = {10, 7, 8, 9, 1, 5};
    volatile int *v_arr = (volatile int *)QS_ARRAY_BASE;
    for (int k = 0; k < 6; k++) {
        v_arr[k] = init_vals[k];
    }

    quickSort(QS_ARRAY_BASE, 0, 5);

    BENCH_DONE_ADDR = 1u;
    return 0;
}
