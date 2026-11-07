
C:\Users\papgu\Desktop\JAI\biriscv-new\riscv-app-gen\bubblesort\bubblesort.elf:     formato de ficheiro elf32-littleriscv


Desmontagem da sec??o .text:

80000000 <_start>:
80000000:	80020137          	lui	sp,0x80020
80000004:	00000413          	li	s0,0
80000008:	054000ef          	jal	8000005c <main>

8000000c <_hang>:
8000000c:	10500073          	wfi
80000010:	ffdff06f          	j	8000000c <_hang>

80000014 <bubbleSort>:
80000014:	00100813          	li	a6,1
80000018:	04b85063          	bge	a6,a1,80000058 <bubbleSort+0x44>
8000001c:	00259613          	slli	a2,a1,0x2
80000020:	00c50633          	add	a2,a0,a2
80000024:	00450513          	addi	a0,a0,4
80000028:	00050793          	mv	a5,a0
8000002c:	02b85063          	bge	a6,a1,8000004c <bubbleSort+0x38>
80000030:	ffc7a703          	lw	a4,-4(a5)
80000034:	0007a683          	lw	a3,0(a5)
80000038:	00e6d663          	bge	a3,a4,80000044 <bubbleSort+0x30>
8000003c:	fed7ae23          	sw	a3,-4(a5)
80000040:	00e7a023          	sw	a4,0(a5)
80000044:	00478793          	addi	a5,a5,4
80000048:	fec794e3          	bne	a5,a2,80000030 <bubbleSort+0x1c>
8000004c:	fff58593          	addi	a1,a1,-1
80000050:	ffc60613          	addi	a2,a2,-4
80000054:	fd059ae3          	bne	a1,a6,80000028 <bubbleSort+0x14>
80000058:	00008067          	ret

8000005c <main>:
8000005c:	fd010113          	addi	sp,sp,-48 # 8001ffd0 <_end+0x1efd0>
80000060:	02112623          	sw	ra,44(sp)
80000064:	800102b7          	lui	t0,0x80010
80000068:	00100393          	li	t2,1
8000006c:	0072a023          	sw	t2,0(t0) # 80010000 <_end+0xf000>
80000070:	0002a223          	sw	zero,4(t0)
80000074:	00000797          	auipc	a5,0x0
80000078:	06878793          	addi	a5,a5,104 # 800000dc <test_array>
8000007c:	0007a303          	lw	t1,0(a5)
80000080:	0047a883          	lw	a7,4(a5)
80000084:	0087a803          	lw	a6,8(a5)
80000088:	00c7a603          	lw	a2,12(a5)
8000008c:	0107a683          	lw	a3,16(a5)
80000090:	0147a703          	lw	a4,20(a5)
80000094:	0187a783          	lw	a5,24(a5)
80000098:	00612223          	sw	t1,4(sp)
8000009c:	01112423          	sw	a7,8(sp)
800000a0:	01012623          	sw	a6,12(sp)
800000a4:	00c12823          	sw	a2,16(sp)
800000a8:	00d12a23          	sw	a3,20(sp)
800000ac:	00e12c23          	sw	a4,24(sp)
800000b0:	00f12e23          	sw	a5,28(sp)
800000b4:	00410513          	addi	a0,sp,4
800000b8:	00700593          	li	a1,7
800000bc:	f59ff0ef          	jal	80000014 <bubbleSort>
800000c0:	800102b7          	lui	t0,0x80010
800000c4:	00100393          	li	t2,1
800000c8:	0072a223          	sw	t2,4(t0) # 80010004 <_end+0xf004>
800000cc:	02c12083          	lw	ra,44(sp)
800000d0:	00000513          	li	a0,0
800000d4:	03010113          	addi	sp,sp,48
800000d8:	00008067          	ret
