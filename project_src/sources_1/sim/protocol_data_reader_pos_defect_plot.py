# !/usr/bin/python3


import os
import struct
import numpy as np
import matplotlib.pyplot as plt
import functools
import re

# drawts = 20000000
# x = np.arange(0, drawts, 1)
# yx_encoder = []
# yw_encoder = []

def one_64bit_bin_ana(proto_bin_data):
    # global yx_encoder
    # global yw_encoder
    sigv = proto_bin_data & 0x1ffff

    if sigv & 0x010000 != 0:
        sigv = sigv & 0x0FFFF
        sigv = sigv - 65536

    reserve = (proto_bin_data & (0x1 << 17)) >> 17
    x_enco = (proto_bin_data & (0x3ffff << 18)) >> 18
    w_enco = (proto_bin_data & (0x3ffff << 36)) >> 36
    gain = (proto_bin_data & (0x0f << 54)) >> 54
    afsv = (proto_bin_data & (0x0f << 58)) >> 58
    type_sig = 0
    acc = (proto_bin_data & (0x1 << 62)) >> 62
    trigger_bit = (proto_bin_data & (0x1 << 63)) >> 63
    
    # if len(yx_encoder) < drawts:
    #     yx_encoder.append(x_enco)
    #     yw_encoder.append(w_enco)

    # return (x_enco, w_enco)
    return (sigv, x_enco, w_enco, gain, afsv, reserve, type_sig, acc, trigger_bit)


def parse_zps_file(file_name, outdir):
    i = str.rfind(file_name, '\\')
    wfile_name = os.path.join(outdir, file_name[i+1 :] + r'.a.csv')

    if not os.path.exists(outdir):
        os.mkdir(outdir)

    wst = 0
    track_num = 1
    with open(file_name, 'rb') as fr, open(wfile_name, 'w') as fw:
        fw.write('Signal, X-Encoder, W-Encoder, Gain, AFS, Reserve, Type, Acc, Trigger-Bit\n')
        bdata = fr.read()
        fr.seek(0, os.SEEK_END)
        sz = fr.tell() // 8
        sdata = struct.unpack('<%uq' % sz, bdata)
        print(track_num)
        # for v in sdata:
        #     parsed_v = one_64bit_bin_ana(v)
        #     if parsed_v[1] < wst:
        #         track_num+=1
        #         print(track_num)
        #     wst = parsed_v[1]
        #     fw.write('%u, %u\n' % parsed_v)
        for v in sdata:
            parsed_v = one_64bit_bin_ana(v)
            if parsed_v[2] < wst:
                track_num+=1
                print(track_num)
            wst = parsed_v[2]
            fw.write('%u, %u, %u, %u, %u, %u, %u, %u, %u\n' % parsed_v)

def sort_str_custom(a, b):
    a_i = int(re.findall('\d+', a)[0])
    b_i = int(re.findall('\d+', b)[0])

    if (a_i < b_i): return -1
    elif(a_i > b_i): return 1
    else: return 0


def main(args):
    if len(args) > 2:
       for root, dirs, files in os.walk(args[1]):
           allfiles = files
           allfiles.sort(key=functools.cmp_to_key(sort_str_custom))
           for file in files:
                fn = os.path.join(root, file)
                print(r'Start to parse pt file: %s' % fn)
                parse_zps_file(fn, args[2])
                # if len(yx_encoder) == drawts:
                #     break
    else:
        print(r'No pt file given.')


if __name__ == '__main__':
    main((1, r'D:/private_gitlab_prj/zas_prj_real_acc/pmt_ch1_prj_v2/project_1.srcs/sources_1/sim/src_data', 'D:/private_gitlab_prj/zas_prj_real_acc/pmt_ch1_prj_v2/project_1.srcs/sources_1/sim/src_data_csv'))
    # plt.plot(x, yx_encoder, c='red', linestyle='-', linewidth=1, label='x-encoder')
    # plt.plot(x, yw_encoder, c='blue', linestyle='-', linewidth=1, label='w-encoder')
    # plt.show()
