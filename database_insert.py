from pathlib import Path
import sys
import microsoftsqlapi
import constants

# Ensure that the correct ODBC Driver is installed on the Linux OS
# Username must match the currently logged in user running benchmarks on Linux OS
driver = constants.DRIVER
server = constants.SERVER
database_name = constants.DATABASE_NAME
username = constants.USERNAME
password = constants.PASSWORD

# Used for keys in fio_dict
fio_vars = "terse_version_3;fio_version;jobname;groupid;error;read_kb;read_bandwidth;read_iops;read_runtime_ms" \
           ";read_slat_min;read_slat_max;read_slat_mean;read_slat_dev;read_clat_min;read_clat_max;read_clat_mean" \
           ";read_clat_dev;read_clat_pct01;read_clat_pct02;read_clat_pct03;read_clat_pct04;read_clat_pct05" \
           ";read_clat_pct06;read_clat_pct07;read_clat_pct08;read_clat_pct09;read_clat_pct10;read_clat_pct11" \
           ";read_clat_pct12;read_clat_pct13;read_clat_pct14;read_clat_pct15;read_clat_pct16;read_clat_pct17" \
           ";read_clat_pct18;read_clat_pct19;read_clat_pct20;read_tlat_min;read_lat_max;read_lat_mean;read_lat_dev" \
           ";read_bw_min;read_bw_max;read_bw_agg_pct;read_bw_mean;read_bw_dev;write_kb;write_bandwidth;write_iops" \
           ";write_runtime_ms;write_slat_min;write_slat_max;write_slat_mean;write_slat_dev;write_clat_min" \
           ";write_clat_max;write_clat_mean;write_clat_dev;write_clat_pct01;write_clat_pct02;write_clat_pct03" \
           ";write_clat_pct04;write_clat_pct05;write_clat_pct06;write_clat_pct07;write_clat_pct08;write_clat_pct09" \
           ";write_clat_pct10;write_clat_pct11;write_clat_pct12;write_clat_pct13;write_clat_pct14;write_clat_pct15" \
           ";write_clat_pct16;write_clat_pct17;write_clat_pct18;write_clat_pct19;write_clat_pct20;write_tlat_min" \
           ";write_lat_max;write_lat_mean;write_lat_dev;write_bw_min;write_bw_max;write_bw_agg_pct;write_bw_mean" \
           ";write_bw_dev;cpu_user;cpu_sys;cpu_csw;cpu_mjf;cpu_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8" \
           ";iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us" \
           ";lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms" \
           ";lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops" \
           ";disk_read_merges;disk_write_merges;disk_read_ticks;write_ticks;disk_queue_time;disk_util".split(";")

# Instantiate SQL Server API to insert data to database
sql_server = microsoftsqlapi.SQLServerAPI(driver, server, database_name, username, password)


def execute(benchmark, data_folder_name):
    if benchmark == "fio":
        insert_data_fio(data_folder_name)
    elif benchmark == "hammerdb":
        insert_data_hammerdb(data_folder_name)


def insert_data_fio(data_folder_name):
    # Obtain the path to the data, and then create a list of just files, not directories.
    # Assumes data is in the home directory
    data_folder_path = Path(r"/home/" + username + "/" + data_folder_name).glob('**/*')    
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        fio_dict = create_fiodict(file)
        if fio_dict:
            print(str(file))
            sql_server.insert_fio(fio_dict)


def create_fiodict(file):
    fio_dict = {}

    # Only open relevant FIO files, which will have the bs string in the file name
    # Create dictionary of FIO vars and values
    str_file = str(file)
    if "bs" in str_file:
        with open(file, 'r') as reader:
            drive_data = str_file.split("_")
            model = drive_data[0].split("/")[-1]
            serial = drive_data[1]
            fw_rev = drive_data[2]
            timestamp = (drive_data[3] + " " + drive_data[4]).split("/")[0]
            fio_data = reader.readline().split(";")
            fio_data[-1] = fio_data[-1].rstrip("\n")
            job_info = fio_data[2].split("_")
            test_type = job_info[0]
            ioengine = job_info[1]
            threads = job_info[2][1:]
            iodepth = job_info[3][2:]
            bs = job_info[4][2:]
            cpu_model = drive_data[5]
            server_model = drive_data[6].split("/")[0]

            fio_dict["model"] = model
            fio_dict["serial"] = serial
            fio_dict["fw_rev"] = fw_rev
            fio_dict["timestamp"] = timestamp
            fio_dict["test_type"] = test_type
            fio_dict["threads"] = threads
            fio_dict["bs"] = bs
            fio_dict["io_engine"] = ioengine
            fio_dict["iodepth"] = iodepth
            fio_dict["cpu_model"] = cpu_model
            fio_dict["server_model"] = server_model
            
            for i in range(len(fio_vars)):
                fio_dict[fio_vars[i]] = fio_data[i]
    #for k, v in fio_dict.items():
        #print(k, v)
    return fio_dict


def insert_data_hammerdb(data_folder_name):
    data_folder_path = Path(r"/home/" + username + "/HammerDB-3.3/runs/" + data_folder_name).glob('**/*')
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        hammerdb_dict = create_hammerdbdict(file)
        if hammerdb_dict:
            print(sql_server.insert_hammerdb(hammerdb_dict))


def create_hammerdbdict(file):
    hammerdb_dict = {}
    str_file = str(file)
    if 'logfile' in str_file:
        with open(file, 'r') as reader:
            data = reader.readline().split(";")
            data2 = reader.readlines()

            date = data[0]
            timestamp = data[1]
            ram = data[2]
            model = data[3]
            serial = data[4]
            fw_rev = data[5]
            capacity = data[6]
            database = data[7]
            benchmark = data[8]
            warehouses = int(data[9])
            mysql_test_type = data[10]
            mysql_test_time = int(data[11])
            use_all_ware = data[12]
            num_virt_usr_run = int(data[13])
            delay_time = int(data[14])
            repeat_time = int(data[15])
            iterations = int(data[16])
            results = data2[-2]
            tpm = results.split(" ")[6]
            nopm = results.split(" ")[10]
            
            hammerdb_dict["date"] = date
            hammerdb_dict["timestamp"] = timestamp
            hammerdb_dict["ram"] = ram
            hammerdb_dict["model"] = model
            hammerdb_dict["serial"] = serial
            hammerdb_dict["fw_rev"] = fw_rev
            hammerdb_dict["capacity"] = capacity
            hammerdb_dict["database"] = database
            hammerdb_dict["benchmark"] = benchmark
            hammerdb_dict["warehouses"] = warehouses
            hammerdb_dict["mysql_test_type"] = mysql_test_type
            hammerdb_dict["mysql_test_time"] = mysql_test_time
            hammerdb_dict["use_all_ware"] = use_all_ware
            hammerdb_dict["num_virt_usr_run"] = num_virt_usr_run
            hammerdb_dict["delay_time"] = delay_time
            hammerdb_dict["repeat_time"] = repeat_time
            hammerdb_dict["iter"] = iterations
            hammerdb_dict["tpm"] = tpm
            hammerdb_dict["nopm"] = nopm

    #for k, v in hammerdb_dict.items():
    #    print(k, v)

    return hammerdb_dict


if __name__ == '__main__':
    benchmark = str(sys.argv[1])
    data_folder_name = str(sys.argv[2])
    execute(benchmark, data_folder_name)
