import csv

def clean_hex_str(hex_string):
    if hex_string.startswith('0x'):
        clean_string = hex_string[2:]
    else:
        clean_string = hex_string

    if len(clean_string) < 8 :
        for i in range(8-len(clean_string)):
            clean_string = '0' + clean_string
    
    return clean_string

def transpose_csv(input_file_path, output_file_path):
    """
    读取CSV文件并将其内容转置，然后将转置后的数据写入新的CSV文件。

    参数:
    input_file_path (str): 原始CSV文件的路径。
    output_file_path (str): 转置后CSV文件的保存路径。

    返回:
    无
    """
    # 读取原始CSV文件
    with open(input_file_path, mode='r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        # 读取所有数据行
        data = [row for row in reader]

    # 转置数据
    transposed_data = [list(row) for row in zip(*data)]
    # print(type(transposed_data),transposed_data[0][0])

    # for row in transposed_data:
    #     print(type(row),row)
    #     break
    # 写入转置后的数据到新的CSV文件
    with open(output_file_path, mode='w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        # 写入转置后的数据行
        data_list = []
        print(len(transposed_data[0]))
        for index in range(len(transposed_data[0])):
            for row in transposed_data:
                row_data_str = clean_hex_str(row[index])
                data_list.append(row_data_str)
        
        for item in data_list:
            writer.writerow([item])

if __name__ == '__main__':

    csv_file_path = r'D:/private_gitlab_prj/zas_prj_real_acc/pmt_ch1_prj_v2/project_1.srcs/sources_1/sim/src_data_csv/read_parameter_src.csv'
    transpose_path = r'D:/private_gitlab_prj/zas_prj_real_acc/pmt_ch1_prj_v2/project_1.srcs/sources_1/sim/src_data_csv/sim_parameter_src.csv'
    transpose_csv(csv_file_path,transpose_path)
