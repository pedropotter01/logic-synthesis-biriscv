
C:\Users\papgu\Desktop\JAI\biriscv-new\riscv-app-gen\array_sum_mul\arraysum_mul.elf:     formato de ficheiro elf32-littleriscv


Desmontagem da sec??o .text:

80000000 <_start>:
80000000:	80020137          	lui	sp,0x80020
80000004:	00000413          	li	s0,0
80000008:	00c000ef          	jal	80000014 <main>

8000000c <_hang>:
8000000c:	10500073          	wfi
80000010:	ffdff06f          	j	8000000c <_hang>

80000014 <main>:
80000014:	800102b7          	lui	t0,0x80010
80000018:	00400313          	li	t1,4
8000001c:	0062a023          	sw	t1,0(t0) # 80010000 <_end+0xf000>
80000020:	0002a223          	sw	zero,4(t0)
80000024:	30028513          	addi	a0,t0,768
80000028:	32828593          	addi	a1,t0,808
8000002c:	35028613          	addi	a2,t0,848
80000030:	37828693          	addi	a3,t0,888
80000034:	00000397          	auipc	t2,0x0
80000038:	0bc38393          	addi	t2,t2,188 # 800000f0 <asm_init_v1>
8000003c:	00000e17          	auipc	t3,0x0
80000040:	0dce0e13          	addi	t3,t3,220 # 80000118 <asm_init_v2>
80000044:	00050e93          	mv	t4,a0
80000048:	00058f13          	mv	t5,a1
8000004c:	00a00f93          	li	t6,10
80000050:	0003a703          	lw	a4,0(t2)
80000054:	000e2783          	lw	a5,0(t3)
80000058:	00eea023          	sw	a4,0(t4)
8000005c:	00ff2023          	sw	a5,0(t5)
80000060:	00438393          	addi	t2,t2,4
80000064:	004e0e13          	addi	t3,t3,4
80000068:	004e8e93          	addi	t4,t4,4
8000006c:	004f0f13          	addi	t5,t5,4
80000070:	ffff8f93          	addi	t6,t6,-1
80000074:	fc0f9ee3          	bnez	t6,80000050 <main+0x3c>
80000078:	00050393          	mv	t2,a0
8000007c:	00058e13          	mv	t3,a1
80000080:	00060e93          	mv	t4,a2
80000084:	00a00f93          	li	t6,10
80000088:	0003a703          	lw	a4,0(t2)
8000008c:	000e2783          	lw	a5,0(t3)
80000090:	02f70833          	mul	a6,a4,a5
80000094:	010ea023          	sw	a6,0(t4)
80000098:	00438393          	addi	t2,t2,4
8000009c:	004e0e13          	addi	t3,t3,4
800000a0:	004e8e93          	addi	t4,t4,4
800000a4:	ffff8f93          	addi	t6,t6,-1
800000a8:	fe0f90e3          	bnez	t6,80000088 <main+0x74>
800000ac:	00050393          	mv	t2,a0
800000b0:	00058e13          	mv	t3,a1
800000b4:	00068f13          	mv	t5,a3
800000b8:	00a00f93          	li	t6,10
800000bc:	0003a703          	lw	a4,0(t2)
800000c0:	000e2783          	lw	a5,0(t3)
800000c4:	00f70833          	add	a6,a4,a5
800000c8:	010f2023          	sw	a6,0(t5)
800000cc:	00438393          	addi	t2,t2,4
800000d0:	004e0e13          	addi	t3,t3,4
800000d4:	004f0f13          	addi	t5,t5,4
800000d8:	ffff8f93          	addi	t6,t6,-1
800000dc:	fe0f90e3          	bnez	t6,800000bc <main+0xa8>
800000e0:	00100313          	li	t1,1
800000e4:	0062a223          	sw	t1,4(t0)
800000e8:	00000513          	li	a0,0
800000ec:	00008067          	ret
