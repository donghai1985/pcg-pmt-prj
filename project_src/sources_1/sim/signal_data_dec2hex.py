

import csv
import math
import time

def get_fir_parameter(csv_file_path):

    # 用于存储CSV数据的列表
    data = []

    # 打开CSV文件进行读取
    with open(csv_file_path, mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        
        # 遍历CSV文件中的每一行
        for row in reader:
            # 将当前行添加到数据列表中
            a = [int(item) for item in row]
            data.append(a)

    # 打印导入的数据
    # print('data:',type(data))
    # print('row:',type(row))
    return data

def clean_hex_str(hex_string):
    if hex_string.startswith('0x'):
        clean_string = hex_string[2:]
    else:
        clean_string = hex_string

    if len(clean_string) < 4 :
        for i in range(4-len(clean_string)):
            clean_string = '0' + clean_string
    
    return clean_string

if __name__ == '__main__':

    file_path =  r'D:/private_gitlab_prj/zas_prj_real_acc/pmt_ch1_prj_v2/project_1.srcs/sources_1/sim/src_data_csv/20240531172025_sim_signal_data - 副本dec.csv'
    src_data = get_fir_parameter(file_path)

    for index in range(len(src_data)):
        src_data[index][0] = clean_hex_str(hex(src_data[index][0]))

    
    currentTime = time.localtime()
    parameter_file_name = time.strftime("%Y%m%d%H%M%S", currentTime)+'_'+'sim_signal_data_hex'+'.csv'
    print(parameter_file_name)
    with open(parameter_file_name, 'w',newline='') as file:
        write = csv.writer(file)
        
        csv_data = []
        for index in src_data:
            csv_data = index
            write.writerow(csv_data)