import xml.etree.ElementTree as ET
import matplotlib.pyplot as plt
import sample_parser as spl

print "Starting XML Parsing...."

regs = spl.CpuRegs()
p = spl.SampleParser()

# with open("mm_samplesG.txt") as xml_file:
#     goldenParse = ET.parse(xml_file)

# golden_samples = goldenParse.getroot()

with open("samples.txt") as xml_file:
    injectParse = ET.parse(xml_file)

samples = injectParse.getroot()

num_samples = len(samples) - 1
num_global_var = len(samples[0][3])
reg_err = []
heap_err = []
stack_err = []
errCnt = 0
heapCnt = []



try:
    val_listA = samples[0][3][0].text.split(' ')
    addrErrs = [0] * len(val_listA)
    for idx in range(1, num_samples):
        
        errCnt = p.diff_regs(samples[0], samples[idx])
        reg_err.append(errCnt)

        heapCnt = p.diff_heap(samples[0], samples[idx], num_global_var)
        heap_err.append(heapCnt)

        addrErrs = p.addr_errs(samples[0], samples[idx], addrErrs)

    print("Register Errors")
    print(reg_err)

    print("Heap Errors")
    print(heap_err)

    addrs = []
    errs = []
    for val in heap_err:
        errs.append(val[0][0])
        addrs.append(val[1])

    plt.plot(addrErrs, 'r.')
    # plt.plot(addrs, errs, 'r.')
    plt.show()


except IndexError:
    print("IndexError. End.")

# data_root = data_tree.getroot()
#
# stack_size = p.get_reg_list(data_root[0])
#
# print(stack_size)
#
# print("length: ", len(data_root))
#
# print("heap: ", data_root[0][1][0].text)
#
# for sample in data_root:
#     try:
#         # registers = sample[0].text.split('\n')[regs.sp() + 1]
#         # sp = int(registers.split(' ')[2], 16)
#         # size = 0x20030000 - sp
#         # # print(registers)
#         # # print(sp)
#         size = p.get_stack_size(sample)
#         print(size)
#     except IndexError:
#         print("IndexError for ", sample.text)

# print("root name: ", data_root.tag)
# print("\troot attributes: ", data_root.attrib)
#
# print("sample tag: ", data_root[2].tag)
# print("\tsample attr: ", data_root[2].attrib)
# print("\tsample subchild: ", data_root[2][1].text)
#
# print("sample tag: ", data_root[0][1].tag)
# print("\tsample attr: ", data_root[0][1][0].attrib)
#
# print("regs: ", data_root[0][0].text)
#
# reg_list = data_root[0][0].text.split()
# print("reg test: ", reg_list[2])
#
# glb_list = data_root[2][1].text.split()
# dict_a = data_root[1].attrib
#
# num = int(data_root[0][1][0].attrib['addr'], 16)
# print(glb_list)
# print(num)
# print("length: ", len(data_root))




