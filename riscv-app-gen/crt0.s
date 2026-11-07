/* Bare-metal CRT0 startup for biRISC-V */
.section .init, "ax"
.global _start
_start:
    # 1. Initialize Stack Pointer at top of TCM RAM (128 KB at 0x80000000 -> 0x80020000)
    lui  sp, 0x80020

    # 2. Clear frame pointer
    mv   s0, zero

    # 3. Call application entry point main()
    jal  ra, main

_hang:
    # 4. Safely park processor on exit
    wfi
    j    _hang

