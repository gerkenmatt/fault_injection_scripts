import xml.etree.ElementTree as ET
from enum import Enum
import re

MAX_STACK_ADDR = 0x20030000

# within a sample
REG_SUBIDX = 2
HEAP_SUBIDX = 3
STACK_SUBIDX = 4

NUM_REGS = 17

class CpuRegs:

    def r0(self):
        return 0

    def r1(self):
        return 1

    def r2(self):
        return 2

    def r3(self):
        return 3

    def r4(self):
        return 4

    def r5(self):
        return 5

    def r6(self):
        return 6

    def r7(self):
        return 7

    def r8(self):
        return 8

    def r9(self):
        return 9

    def r10(self):
        return 10

    def r11(self):
        return 11

    def r12(self):
        return 12

    def sp(self):
        return 13

    def lr(self):
        return 14

    def pc(self):
        return 15

    def xPSR(self):
        return 16

    # r0 = 0
    # r1 = 1
    # r2 = 2
    # r3 = 3
    # r4 = 4
    # r5 = 5
    # r6 = 6
    # r7 = 7
    # r8 = 8
    # r9 = 9
    # r10 = 10
    # r11 = 11
    # r12 = 12
    # sp = 13
    # lr = 14
    # pc = 15
    # xPSR = 16

class SampleParser:

    def get_reg_list(self, sample):
        # note that first element of newline_split is ""
        newline_split = sample[REG_SUBIDX].text.split('\n')
        print(newline_split)
        reg_val = []

        for idx in range(1, NUM_REGS + 1):
            val = int(newline_split[idx].split(' ')[2], 16)
            reg_val.append(val)

        return reg_val

    def get_stack_size(self, sample):
        regs = CpuRegs()
        registers = sample[REG_SUBIDX].text.split('\n')[regs.sp() + 1]
        print(registers)
        sp = int(registers.split(' ')[2], 16)
        size = MAX_STACK_ADDR - sp

        return size

    def diff_regs(self, sampleA, sampleB):
        regs = CpuRegs()
        regA = sampleA[REG_SUBIDX].text.split('\n')
        regB = sampleB[REG_SUBIDX].text.split('\n')
        errCount = 0

        for idx in range(1, NUM_REGS + 1):
            if regA[idx] != regB[idx]:
                errCount += 1

        return errCount

    def diff_string_list(self, val_listA, val_listB):
        errCount = 0

        for idx in range(0, len(val_listA)): # assuming lists are of same length
            if val_listA[idx] != val_listB[idx]:
                errCount += 1

        return errCount

    def diff_heap(self, sampleA, sampleB, numHeap):
        errCount = []
        for idx in range(0, numHeap):
            val_listA = sampleA[HEAP_SUBIDX][idx].text.split(' ')
            val_listB = sampleB[HEAP_SUBIDX][idx].text.split(' ')
            errCount.append(self.diff_string_list(val_listA, val_listB))

        return errCount, int(re.search(r'\d+', sampleB[0].text).group()), int(re.search(r'\d+', sampleB[1].text).group()) # a list of error counts for each global var in the heap

    def addr_errs(self, sampleA, sampleB,  addrCount):
        val_listA = sampleA[HEAP_SUBIDX][0].text.split(' ')
        val_listB = sampleB[HEAP_SUBIDX][0].text.split(' ')
        for idx in range(0, len(val_listA)): # assuming lists are of same length
            if val_listA[idx] != val_listB[idx]:
                addrCount[idx] = addrCount[idx] + 1
            
        return addrCount

