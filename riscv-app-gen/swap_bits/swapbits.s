
C:\Users\papgu\Desktop\JAI\biriscv-new\riscv-app-gen\swap_bits\swapbits.elf:     formato de ficheiro elf32-littleriscv


Desmontagem da sec??o .text:

80000000 <_start>:
80000000:	80020137          	lui	sp,0x80020
80000004:	00000413          	li	s0,0
80000008:	058000ef          	jal	80000060 <main>

8000000c <_hang>:
8000000c:	10500073          	wfi
80000010:	ffdff06f          	j	8000000c <_hang>

80000014 <swapBits>:
80000014:	80010fb7          	lui	t6,0x80010
80000018:	400f8f93          	addi	t6,t6,1024 # 80010400 <_end+0xf400>
8000001c:	00100293          	li	t0,1
80000020:	00d292b3          	sll	t0,t0,a3
80000024:	fff28293          	addi	t0,t0,-1
80000028:	00b55333          	srl	t1,a0,a1
8000002c:	00537333          	and	t1,t1,t0
80000030:	006fa823          	sw	t1,16(t6)
80000034:	00c553b3          	srl	t2,a0,a2
80000038:	0053f3b3          	and	t2,t2,t0
8000003c:	007faa23          	sw	t2,20(t6)
80000040:	00734e33          	xor	t3,t1,t2
80000044:	00be1eb3          	sll	t4,t3,a1
80000048:	00ce1f33          	sll	t5,t3,a2
8000004c:	01eeee33          	or	t3,t4,t5
80000050:	01cfac23          	sw	t3,24(t6)
80000054:	01c54533          	xor	a0,a0,t3
80000058:	00afae23          	sw	a0,28(t6)
8000005c:	00008067          	ret

80000060 <main>:
80000060:	ff010113          	addi	sp,sp,-16 # 8001fff0 <_end+0x1eff0>
80000064:	00112623          	sw	ra,12(sp)
80000068:	800102b7          	lui	t0,0x80010
8000006c:	00500313          	li	t1,5
80000070:	0062a023          	sw	t1,0(t0) # 80010000 <_end+0xf000>
80000074:	0002a223          	sw	zero,4(t0)
80000078:	40028393          	addi	t2,t0,1024
8000007c:	01c00513          	li	a0,28
80000080:	00000593          	li	a1,0
80000084:	00300613          	li	a2,3
80000088:	00200693          	li	a3,2
8000008c:	00a3a023          	sw	a0,0(t2)
80000090:	00b3a223          	sw	a1,4(t2)
80000094:	00c3a423          	sw	a2,8(t2)
80000098:	00d3a623          	sw	a3,12(t2)
8000009c:	f79ff0ef          	jal	80000014 <swapBits>
800000a0:	800102b7          	lui	t0,0x80010
800000a4:	00100313          	li	t1,1
800000a8:	0062a223          	sw	t1,4(t0) # 80010004 <_end+0xf004>
800000ac:	00c12083          	lw	ra,12(sp)
800000b0:	00000513          	li	a0,0
800000b4:	01010113          	addi	sp,sp,16
800000b8:	00008067          	ret
