
C:\Users\papgu\Desktop\JAI\biriscv-new\riscv-app-gen\dot_product\dotproduct.elf:     formato de ficheiro elf32-littleriscv


Desmontagem da sec??o .text:

80000000 <_start>:
80000000:	80020137          	lui	sp,0x80020
80000004:	00000413          	li	s0,0
80000008:	054000ef          	jal	8000005c <main>

8000000c <_hang>:
8000000c:	10500073          	wfi
80000010:	ffdff06f          	j	8000000c <_hang>

80000014 <produto_escalar>:
80000014:	800102b7          	lui	t0,0x80010
80000018:	26028293          	addi	t0,t0,608 # 80010260 <_end+0xf260>
8000001c:	0002a023          	sw	zero,0(t0)
80000020:	00000693          	li	a3,0
80000024:	00700313          	li	t1,7
80000028:	00052383          	lw	t2,0(a0)
8000002c:	0005ae03          	lw	t3,0(a1)
80000030:	03c38eb3          	mul	t4,t2,t3
80000034:	01d62023          	sw	t4,0(a2)
80000038:	01d686b3          	add	a3,a3,t4
8000003c:	00d2a023          	sw	a3,0(t0)
80000040:	00450513          	addi	a0,a0,4
80000044:	00458593          	addi	a1,a1,4
80000048:	00460613          	addi	a2,a2,4
8000004c:	fff30313          	addi	t1,t1,-1
80000050:	fc031ce3          	bnez	t1,80000028 <produto_escalar+0x14>
80000054:	00068513          	mv	a0,a3
80000058:	00008067          	ret

8000005c <main>:
8000005c:	ff010113          	addi	sp,sp,-16 # 8001fff0 <_end+0x1eff0>
80000060:	00112623          	sw	ra,12(sp)
80000064:	800102b7          	lui	t0,0x80010
80000068:	00300313          	li	t1,3
8000006c:	0062a023          	sw	t1,0(t0) # 80010000 <_end+0xf000>
80000070:	0002a223          	sw	zero,4(t0)
80000074:	20028513          	addi	a0,t0,512
80000078:	22028593          	addi	a1,t0,544
8000007c:	24028613          	addi	a2,t0,576
80000080:	00000397          	auipc	t2,0x0
80000084:	06438393          	addi	t2,t2,100 # 800000e4 <dp_init_v1>
80000088:	00000e17          	auipc	t3,0x0
8000008c:	078e0e13          	addi	t3,t3,120 # 80000100 <dp_init_v2>
80000090:	00050e93          	mv	t4,a0
80000094:	00058f13          	mv	t5,a1
80000098:	00700f93          	li	t6,7
8000009c:	0003a703          	lw	a4,0(t2)
800000a0:	000e2783          	lw	a5,0(t3)
800000a4:	00eea023          	sw	a4,0(t4)
800000a8:	00ff2023          	sw	a5,0(t5)
800000ac:	00438393          	addi	t2,t2,4
800000b0:	004e0e13          	addi	t3,t3,4
800000b4:	004e8e93          	addi	t4,t4,4
800000b8:	004f0f13          	addi	t5,t5,4
800000bc:	ffff8f93          	addi	t6,t6,-1
800000c0:	fc0f9ee3          	bnez	t6,8000009c <main+0x40>
800000c4:	f51ff0ef          	jal	80000014 <produto_escalar>
800000c8:	800102b7          	lui	t0,0x80010
800000cc:	00100313          	li	t1,1
800000d0:	0062a223          	sw	t1,4(t0) # 80010004 <_end+0xf004>
800000d4:	00c12083          	lw	ra,12(sp)
800000d8:	00000513          	li	a0,0
800000dc:	01010113          	addi	sp,sp,16
800000e0:	00008067          	ret
