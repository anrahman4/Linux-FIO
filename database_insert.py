from pathlib import Path
import sys
import microsoftsqlapi
import constants
import json


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
           ";read_clat_dev;" \
           "read_clat_pct01;read_clat_pct01_val;" \
           "read_clat_pct02;read_clat_pct02_val;" \
           "read_clat_pct03;read_clat_pct03_val;" \
           "read_clat_pct04;read_clat_pct04_val;" \
           "read_clat_pct05;read_clat_pct05_val;" \
           "read_clat_pct06;read_clat_pct06_val;" \
           "read_clat_pct07;read_clat_pct07_val;" \
           "read_clat_pct08;read_clat_pct08_val;" \
           "read_clat_pct09;read_clat_pct09_val;" \
           "read_clat_pct10;read_clat_pct10_val;" \
           "read_clat_pct11;read_clat_pct11_val;" \
           "read_clat_pct12;read_clat_pct12_val;" \
           "read_clat_pct13;read_clat_pct13_val;" \
           "read_clat_pct14;read_clat_pct14_val;" \
           "read_clat_pct15;read_clat_pct15_val;" \
           "read_clat_pct16;read_clat_pct16_val;" \
           "read_clat_pct17;read_clat_pct17_val;" \
           "read_clat_pct18;read_clat_pct18_val;" \
           "read_clat_pct19;read_clat_pct19_val;" \
           "read_clat_pct20;read_clat_pct20_val;" \
           "read_lat_min;read_lat_max;read_lat_mean;read_lat_dev" \
           ";read_bw_min;read_bw_max;read_bw_agg_pct;read_bw_mean;read_bw_dev;write_kb;write_bandwidth;write_iops" \
           ";write_runtime_ms;write_slat_min;write_slat_max;write_slat_mean;write_slat_dev;write_clat_min" \
           ";write_clat_max;write_clat_mean;write_clat_dev;" \
           "write_clat_pct01;write_clat_pct01_val;" \
           "write_clat_pct02;write_clat_pct02_val;" \
           "write_clat_pct03;write_clat_pct03_val;" \
           "write_clat_pct04;write_clat_pct04_val;" \
           "write_clat_pct05;write_clat_pct05_val;" \
           "write_clat_pct06;write_clat_pct06_val;" \
           "write_clat_pct07;write_clat_pct07_val;" \
           "write_clat_pct08;write_clat_pct08_val;" \
           "write_clat_pct09;write_clat_pct09_val;" \
           "write_clat_pct10;write_clat_pct10_val;" \
           "write_clat_pct11;write_clat_pct11_val;" \
           "write_clat_pct12;write_clat_pct12_val;" \
           "write_clat_pct13;write_clat_pct13_val;" \
           "write_clat_pct14;write_clat_pct14_val;" \
           "write_clat_pct15;write_clat_pct15_val;" \
           "write_clat_pct16;write_clat_pct16_val;" \
           "write_clat_pct17;write_clat_pct17_val;" \
           "write_clat_pct18;write_clat_pct18_val;" \
           "write_clat_pct19;write_clat_pct19_val;" \
           "write_clat_pct20;write_clat_pct20_val;" \
           "write_lat_min" \
           ";write_lat_max;write_lat_mean;write_lat_dev;write_bw_min;write_bw_max;write_bw_agg_pct;write_bw_mean" \
           ";write_bw_dev;cpu_user;cpu_sys;cpu_csw;cpu_mjf;cpu_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8" \
           ";iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us" \
           ";lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms" \
           ";lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops" \
           ";disk_read_merges;disk_write_merges;disk_read_ticks;disk_write_ticks;disk_queue_time;disk_util".split(";")

# Instantiate SQL Server API to insert data to database
sql_server = microsoftsqlapi.SQLServerAPI(driver, server, database_name, username, password)


def execute(benchmark, fio_file_type, data_folder_name):
    if benchmark == "fio_expanded" and fio_file_type == "terse":
        insert_data_fio_expanded_terse(data_folder_name)
    elif benchmark == "fio_expanded" and fio_file_type == "json+":
        insert_data_fio_expanded_jsonplus(data_folder_name)
    elif benchmark == "fio_lat" and fio_file_type == "json+":
        insert_data_fio_lat_jsonplus(data_folder_name)
    elif benchmark == "fio_lat" and fio_file_type == "terse":
        insert_data_fio_lat_terse(data_folder_name)
    elif benchmark == "hammerdb":
        insert_data_hammerdb(data_folder_name)


def insert_data_fio_lat_terse(data_folder_name):
    # Obtain the path to the data, and then create a list of just files, not directories.
    # Assumes data is in the home directory
    data_folder_path = Path(r"/home/" + username + "/" + data_folder_name).glob('**/*')
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        fio_dict = create_fiodict_lat_terse(file)
        if fio_dict:
            print(str(file))
            sql_server.insert_fio_lat(fio_dict)


def create_fiodict_lat_terse(file):
    fio_dict = {}

    # Only open relevant FIO files, which will have the bs string in the file name
    # Create dictionary of FIO vars and values
    str_file = str(file)
    if "bs" in str_file:
        with open(file, 'r') as reader:
            drive_data = str_file.split("_")
            drive_name = drive_data[0].split("/")[-1]
            drive_name = drive_name.split("-")
            friendly_name = ""
            for i in range(len(drive_name)):
                if i == 0:
                    friendly_name = friendly_name + drive_name[i]
                else:
                    friendly_name = friendly_name + " " + drive_name[i]
            model = drive_data[1]
            serial = drive_data[2]
            fw_rev = drive_data[3]
            timestamp = (drive_data[4] + " " + drive_data[5]).split("/")[0]
            cpu_model = drive_data[6]
            server_model = drive_data[7].split("/")[0]

            fio_data = reader.readline().split(";")
            fio_data[-1] = fio_data[-1].rstrip("\n")
            job_info = fio_data[2].split("_")
            test_type = job_info[0]
            ioengine = job_info[1]
            threads = job_info[2][1:]
            iodepth = job_info[3][2:]
            bs = job_info[4][2:]
            bs = bs.replace("k", "")

            fio_dict["friendly_name"] = friendly_name
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

            i = 0
            j = 0

            while i < len(fio_vars):
                if "=" in fio_data[j]:
                    percentile_data = fio_data[j].split("=")
                    percentile = percentile_data[0]
                    percentile_val = percentile_data[1]
                    fio_dict[fio_vars[i]] = percentile[:-1]
                    fio_dict[fio_vars[i + 1]] = percentile_val
                    i += 2
                else:
                    fio_dict[fio_vars[i]] = fio_data[j]
                    i += 1
                j += 1
    # for k, v in fio_dict.items():
    #    print(k, v)
    return fio_dict


def insert_data_fio_lat_jsonplus(data_folder_name):
    # Obtain the path to the data, and then create a list of just files, not directories.
    # Assumes data is in the home directory
    data_folder_path = Path(r"/home/" + username + "/" + data_folder_name).glob('**/*')
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        fio_dict = create_fiodict_lat_jsonplus(file)
        if fio_dict:
            print(str(file))
            sql_server.insert_fio_lat(fio_dict)

def create_fiodict_lat_jsonplus(file):
    fio_dict = {}

    str_file = str(file)
    if ".json" in str_file:
        drive_data = str_file.split("_")
        drive_name = drive_data[0].split("/")[-1]
        drive_name = drive_name.split("-")
        friendly_name = ""
        for i in range(len(drive_name)):
            if i == 0:
                friendly_name = friendly_name + drive_name[i]
            else:
                friendly_name = friendly_name + " " + drive_name[i]
        model = drive_data[1]
        serial = drive_data[2]
        fw_rev = drive_data[3]
        timestamp = (drive_data[4] + " " + drive_data[5]).split("/")[0]
        cpu_model = drive_data[6]
        server_model = drive_data[7].split("/")[0]

        with open(file) as user_file:
            json_dict = json.load(user_file)

        test_type = json_dict["jobs"][0]["jobname"].split("_")[0]
        ioengine = json_dict["global options"]["ioengine"]
        threads = json_dict["global options"]["numjobs"]
        iodepth = json_dict["global options"]["iodepth"]
        bs = json_dict["global options"]["bs"].replace("k", "")

        fio_dict["friendly_name"] = friendly_name
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

        fio_dict["terse_version_3"] = 0
        fio_dict["fio_version"] = json_dict["fio version"]
        fio_dict["jobname"] = json_dict["jobs"][0]["jobname"]
        fio_dict["groupid"] = json_dict["jobs"][0]["groupid"]
        fio_dict["error"] = json_dict["jobs"][0]["error"]
        fio_dict["read_kb"] = json_dict["jobs"][0]["read"]["io_kbytes"]
        fio_dict["read_bandwidth"] = json_dict["jobs"][0]["read"]["bw"]
        fio_dict["read_iops"] = json_dict["jobs"][0]["read"]["iops"]
        fio_dict["read_runtime_ms"] = json_dict["jobs"][0]["read"]["runtime"]
        fio_dict["read_slat_min"] = json_dict["jobs"][0]["read"]["slat_ns"]["min"]
        fio_dict["read_slat_max"] = json_dict["jobs"][0]["read"]["slat_ns"]["max"]
        fio_dict["read_slat_mean"] = json_dict["jobs"][0]["read"]["slat_ns"]["mean"]
        fio_dict["read_slat_dev"] = json_dict["jobs"][0]["read"]["slat_ns"]["stddev"]
        fio_dict["read_clat_min"] = json_dict["jobs"][0]["read"]["clat_ns"]["min"]
        fio_dict["read_clat_max"] = json_dict["jobs"][0]["read"]["clat_ns"]["max"]
        fio_dict["read_clat_mean"] = json_dict["jobs"][0]["read"]["clat_ns"]["mean"]
        fio_dict["read_clat_dev"] = json_dict["jobs"][0]["read"]["clat_ns"]["stddev"]

        if "read0" in test_type:
            fio_dict["read_clat_pct01"] = 50
            fio_dict["read_clat_pct02"] = 99
            fio_dict["read_clat_pct03"] = 99.9
            fio_dict["read_clat_pct04"] = 99.99
            fio_dict["read_clat_pct05"] = 99.999
            fio_dict["read_clat_pct06"] = 99.9999
            fio_dict["read_clat_pct07"] = 99.99999
            fio_dict["read_clat_pct08"] = 99.999999
            fio_dict["read_clat_pct09"] = 100
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = 0
            fio_dict["read_clat_pct02_val"] = 0
            fio_dict["read_clat_pct03_val"] = 0
            fio_dict["read_clat_pct04_val"] = 0
            fio_dict["read_clat_pct05_val"] = 0
            fio_dict["read_clat_pct06_val"] = 0
            fio_dict["read_clat_pct07_val"] = 0
            fio_dict["read_clat_pct08_val"] = 0
            fio_dict["read_clat_pct09_val"] = 0
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 50
            fio_dict["write_clat_pct02"] = 99
            fio_dict["write_clat_pct03"] = 99.9
            fio_dict["write_clat_pct04"] = 99.99
            fio_dict["write_clat_pct05"] = 99.999
            fio_dict["write_clat_pct06"] = 99.9999
            fio_dict["write_clat_pct07"] = 99.99999
            fio_dict["write_clat_pct08"] = 99.999999
            fio_dict["write_clat_pct09"] = 100
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["50.000000"]
            fio_dict["write_clat_pct02_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.000000"]
            fio_dict["write_clat_pct03_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.900000"]
            fio_dict["write_clat_pct04_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.990000"]
            fio_dict["write_clat_pct05_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999000"]
            fio_dict["write_clat_pct06_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999900"]
            fio_dict["write_clat_pct07_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999990"]
            fio_dict["write_clat_pct08_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999999"]
            fio_dict["write_clat_pct09_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["100.000000"]
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        elif "write0" in  test_type:
            fio_dict["read_clat_pct01"] = 50
            fio_dict["read_clat_pct02"] = 99
            fio_dict["read_clat_pct03"] = 99.9
            fio_dict["read_clat_pct04"] = 99.99
            fio_dict["read_clat_pct05"] = 99.999
            fio_dict["read_clat_pct06"] = 99.9999
            fio_dict["read_clat_pct07"] = 99.99999
            fio_dict["read_clat_pct08"] = 99.999999
            fio_dict["read_clat_pct09"] = 100
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["50.000000"]
            fio_dict["read_clat_pct02_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.000000"]
            fio_dict["read_clat_pct03_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.900000"]
            fio_dict["read_clat_pct04_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.990000"]
            fio_dict["read_clat_pct05_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999000"]
            fio_dict["read_clat_pct06_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999900"]
            fio_dict["read_clat_pct07_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999990"]
            fio_dict["read_clat_pct08_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999999"]
            fio_dict["read_clat_pct09_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["100.000000"]
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 50
            fio_dict["write_clat_pct02"] = 99
            fio_dict["write_clat_pct03"] = 99.9
            fio_dict["write_clat_pct04"] = 99.99
            fio_dict["write_clat_pct05"] = 99.999
            fio_dict["write_clat_pct06"] = 99.9999
            fio_dict["write_clat_pct07"] = 99.99999
            fio_dict["write_clat_pct08"] = 99.999999
            fio_dict["write_clat_pct09"] = 100
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = 0
            fio_dict["write_clat_pct02_val"] = 0
            fio_dict["write_clat_pct03_val"] = 0
            fio_dict["write_clat_pct04_val"] = 0
            fio_dict["write_clat_pct05_val"] = 0
            fio_dict["write_clat_pct06_val"] = 0
            fio_dict["write_clat_pct07_val"] = 0
            fio_dict["write_clat_pct08_val"] = 0
            fio_dict["write_clat_pct09_val"] = 0
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        else:
            fio_dict["read_clat_pct01"] = 50
            fio_dict["read_clat_pct02"] = 99
            fio_dict["read_clat_pct03"] = 99.9
            fio_dict["read_clat_pct04"] = 99.99
            fio_dict["read_clat_pct05"] = 99.999
            fio_dict["read_clat_pct06"] = 99.9999
            fio_dict["read_clat_pct07"] = 99.99999
            fio_dict["read_clat_pct08"] = 99.999999
            fio_dict["read_clat_pct09"] = 100
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["50.000000"]
            fio_dict["read_clat_pct02_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.000000"]
            fio_dict["read_clat_pct03_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.900000"]
            fio_dict["read_clat_pct04_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.990000"]
            fio_dict["read_clat_pct05_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999000"]
            fio_dict["read_clat_pct06_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999900"]
            fio_dict["read_clat_pct07_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999990"]
            fio_dict["read_clat_pct08_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999999"]
            fio_dict["read_clat_pct09_val"] = json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["100.000000"]
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 50
            fio_dict["write_clat_pct02"] = 99
            fio_dict["write_clat_pct03"] = 99.9
            fio_dict["write_clat_pct04"] = 99.99
            fio_dict["write_clat_pct05"] = 99.999
            fio_dict["write_clat_pct06"] = 99.9999
            fio_dict["write_clat_pct07"] = 99.99999
            fio_dict["write_clat_pct08"] = 99.999999
            fio_dict["write_clat_pct09"] = 100
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["50.000000"]
            fio_dict["write_clat_pct02_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.000000"]
            fio_dict["write_clat_pct03_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.900000"]
            fio_dict["write_clat_pct04_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.990000"]
            fio_dict["write_clat_pct05_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999000"]
            fio_dict["write_clat_pct06_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999900"]
            fio_dict["write_clat_pct07_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999990"]
            fio_dict["write_clat_pct08_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999999"]
            fio_dict["write_clat_pct09_val"] = json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["100.000000"]
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        fio_dict["read_lat_min"] = json_dict["jobs"][0]["read"]["lat_ns"]["min"]
        fio_dict["read_lat_max"] = json_dict["jobs"][0]["read"]["lat_ns"]["max"]
        fio_dict["read_lat_mean"] = json_dict["jobs"][0]["read"]["lat_ns"]["mean"]
        fio_dict["read_lat_dev"] = json_dict["jobs"][0]["read"]["lat_ns"]["stddev"]
        fio_dict["read_bw_min"] = json_dict["jobs"][0]["read"]["bw_min"]
        fio_dict["read_bw_max"] = json_dict["jobs"][0]["read"]["bw_max"]
        fio_dict["read_bw_agg_pct"] = json_dict["jobs"][0]["read"]["bw_agg"]
        fio_dict["read_bw_mean"] = json_dict["jobs"][0]["read"]["bw_mean"]
        fio_dict["read_bw_dev"] = json_dict["jobs"][0]["read"]["bw_dev"]

        fio_dict["write_kb"] = json_dict["jobs"][0]["write"]["io_kbytes"]
        fio_dict["write_bandwidth"] = json_dict["jobs"][0]["write"]["bw"]
        fio_dict["write_iops"] = json_dict["jobs"][0]["write"]["iops"]
        fio_dict["write_runtime_ms"] = json_dict["jobs"][0]["write"]["runtime"]
        fio_dict["write_slat_min"] = json_dict["jobs"][0]["write"]["slat_ns"]["min"]
        fio_dict["write_slat_max"] = json_dict["jobs"][0]["write"]["slat_ns"]["max"]
        fio_dict["write_slat_mean"] = json_dict["jobs"][0]["write"]["slat_ns"]["mean"]
        fio_dict["write_slat_dev"] = json_dict["jobs"][0]["write"]["slat_ns"]["stddev"]
        fio_dict["write_clat_min"] = json_dict["jobs"][0]["write"]["clat_ns"]["min"]
        fio_dict["write_clat_max"] = json_dict["jobs"][0]["write"]["clat_ns"]["max"]
        fio_dict["write_clat_mean"] = json_dict["jobs"][0]["write"]["clat_ns"]["mean"]
        fio_dict["write_clat_dev"] = json_dict["jobs"][0]["write"]["clat_ns"]["stddev"]
        fio_dict["write_lat_min"] = json_dict["jobs"][0]["write"]["lat_ns"]["min"]
        fio_dict["write_lat_max"] = json_dict["jobs"][0]["write"]["lat_ns"]["max"]
        fio_dict["write_lat_mean"] = json_dict["jobs"][0]["write"]["lat_ns"]["mean"]
        fio_dict["write_lat_dev"] = json_dict["jobs"][0]["write"]["lat_ns"]["stddev"]
        fio_dict["write_bw_min"] = json_dict["jobs"][0]["write"]["bw_min"]
        fio_dict["write_bw_max"] = json_dict["jobs"][0]["write"]["bw_max"]
        fio_dict["write_bw_agg_pct"] = json_dict["jobs"][0]["write"]["bw_agg"]
        fio_dict["write_bw_mean"] = json_dict["jobs"][0]["write"]["bw_mean"]
        fio_dict["write_bw_dev"] = json_dict["jobs"][0]["write"]["bw_dev"]

        fio_dict["cpu_user"] = json_dict["jobs"][0]["usr_cpu"]
        fio_dict["cpu_sys"] = json_dict["jobs"][0]["sys_cpu"]
        fio_dict["cpu_csw"] = json_dict["jobs"][0]["ctx"]
        fio_dict["cpu_mjf"] = json_dict["jobs"][0]["majf"]
        fio_dict["cpu_minf"] = json_dict["jobs"][0]["minf"]
        fio_dict["iodepth_1"] = json_dict["jobs"][0]["iodepth_level"]["1"]
        fio_dict["iodepth_2"] = json_dict["jobs"][0]["iodepth_level"]["2"]
        fio_dict["iodepth_4"] = json_dict["jobs"][0]["iodepth_level"]["4"]
        fio_dict["iodepth_8"] = json_dict["jobs"][0]["iodepth_level"]["8"]
        fio_dict["iodepth_16"] = json_dict["jobs"][0]["iodepth_level"]["16"]
        fio_dict["iodepth_32"] = json_dict["jobs"][0]["iodepth_level"]["32"]
        fio_dict["iodepth_64"] = json_dict["jobs"][0]["iodepth_level"][">=64"]

        fio_dict["lat_2us"] = json_dict["jobs"][0]["latency_us"]["2"]
        fio_dict["lat_4us"] = json_dict["jobs"][0]["latency_us"]["4"]
        fio_dict["lat_10us"] = json_dict["jobs"][0]["latency_us"]["10"]
        fio_dict["lat_20us"] = json_dict["jobs"][0]["latency_us"]["20"]
        fio_dict["lat_50us"] = json_dict["jobs"][0]["latency_us"]["50"]
        fio_dict["lat_100us"] = json_dict["jobs"][0]["latency_us"]["100"]
        fio_dict["lat_250us"] = json_dict["jobs"][0]["latency_us"]["250"]
        fio_dict["lat_500us"] = json_dict["jobs"][0]["latency_us"]["500"]
        fio_dict["lat_750us"] = json_dict["jobs"][0]["latency_us"]["750"]
        fio_dict["lat_1000us"] = json_dict["jobs"][0]["latency_us"]["1000"]

        fio_dict["lat_2ms"] = json_dict["jobs"][0]["latency_ms"]["2"]
        fio_dict["lat_4ms"] = json_dict["jobs"][0]["latency_ms"]["4"]
        fio_dict["lat_10ms"] = json_dict["jobs"][0]["latency_ms"]["10"]
        fio_dict["lat_20ms"] = json_dict["jobs"][0]["latency_ms"]["20"]
        fio_dict["lat_50ms"] = json_dict["jobs"][0]["latency_ms"]["50"]
        fio_dict["lat_100ms"] = json_dict["jobs"][0]["latency_ms"]["100"]
        fio_dict["lat_250ms"] = json_dict["jobs"][0]["latency_ms"]["250"]
        fio_dict["lat_500ms"] = json_dict["jobs"][0]["latency_ms"]["500"]
        fio_dict["lat_750ms"] = json_dict["jobs"][0]["latency_ms"]["750"]
        fio_dict["lat_1000ms"] = json_dict["jobs"][0]["latency_ms"]["1000"]
        fio_dict["lat_2000ms"] = json_dict["jobs"][0]["latency_ms"]["2000"]
        fio_dict["lat_over_2000ms"] = json_dict["jobs"][0]["latency_ms"][">=2000"]

        fio_dict["disk_name"] = json_dict["disk_util"][0]["name"]
        fio_dict["disk_read_iops"] = json_dict["disk_util"][0]["read_ios"]
        fio_dict["disk_write_iops"] = json_dict["disk_util"][0]["write_ios"]
        fio_dict["disk_read_merges"] = json_dict["disk_util"][0]["read_merges"]
        fio_dict["disk_write_merges"] = json_dict["disk_util"][0]["write_merges"]
        fio_dict["disk_read_ticks"] = json_dict["disk_util"][0]["read_ticks"]
        fio_dict["disk_write_ticks"] = json_dict["disk_util"][0]["write_ticks"]
        fio_dict["disk_queue_time"] = json_dict["disk_util"][0]["in_queue"]
        fio_dict["disk_util"] = json_dict["disk_util"][0]["util"]

    # for k, v in fio_dict.items():
    #     print(k, v)
    return fio_dict

def insert_data_fio_expanded_terse(data_folder_name):
    # Obtain the path to the data, and then create a list of just files, not directories.
    # Assumes data is in the home directory
    data_folder_path = Path(r"/home/" + username + "/" + data_folder_name).glob('**/*')
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        fio_dict = create_fiodict_expanded_terse(file)
        if fio_dict:
            print(str(file))
            sql_server.insert_fio_expanded(fio_dict)


def insert_data_fio_expanded_jsonplus(data_folder_name):
    data_folder_path = Path(r"" + data_folder_name).glob('**/*')
    data_files = [file for file in data_folder_path if file.is_file()]
    for file in data_files:
        fio_dict = create_fiodict_expanded_jsonplus(file)
        if fio_dict:
            print(str(file))
            sql_server.insert_fio_expanded(fio_dict)


def create_fiodict_expanded_jsonplus(file):
    fio_dict = {}

    str_file = str(file)
    if ".json" in str_file:
        drive_data = str_file.split("_")
        drive_name = drive_data[0].split("/")[-1]
        drive_name = drive_name.split("-")
        friendly_name = ""
        for i in range(len(drive_name)):
            if i == 0:
                friendly_name = friendly_name + drive_name[i]
            else:
                friendly_name = friendly_name + " " + drive_name[i]
        model = drive_data[1]
        serial = drive_data[2]
        fw_rev = drive_data[3]
        timestamp = (drive_data[4] + " " + drive_data[5]).split("/")[0]
        cpu_model = drive_data[6]
        server_model = drive_data[7].split("/")[0]

        with open(file) as user_file:
            json_dict = json.load(user_file)

        test_type = json_dict["jobs"][0]["jobname"].split("_")[0]
        ioengine = json_dict["global options"]["ioengine"]
        threads = json_dict["global options"]["numjobs"]
        iodepth = json_dict["global options"]["iodepth"]
        bs = json_dict["global options"]["bs"].replace("k", "")

        fio_dict["friendly_name"] = friendly_name
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

        fio_dict["terse_version_3"] = 0
        fio_dict["fio_version"] = json_dict["fio version"]
        fio_dict["jobname"] = json_dict["jobs"][0]["jobname"]
        fio_dict["groupid"] = json_dict["jobs"][0]["groupid"]
        fio_dict["error"] = json_dict["jobs"][0]["error"]
        fio_dict["read_kb"] = json_dict["jobs"][0]["read"]["io_kbytes"]
        fio_dict["read_bandwidth"] = json_dict["jobs"][0]["read"]["bw"]
        fio_dict["read_iops"] = json_dict["jobs"][0]["read"]["iops"]
        fio_dict["read_runtime_ms"] = json_dict["jobs"][0]["read"]["runtime"]
        fio_dict["read_slat_min"] = json_dict["jobs"][0]["read"]["slat_ns"]["min"]
        fio_dict["read_slat_max"] = json_dict["jobs"][0]["read"]["slat_ns"]["max"]
        fio_dict["read_slat_mean"] = json_dict["jobs"][0]["read"]["slat_ns"]["mean"]
        fio_dict["read_slat_dev"] = json_dict["jobs"][0]["read"]["slat_ns"]["stddev"]
        fio_dict["read_clat_min"] = json_dict["jobs"][0]["read"]["clat_ns"]["min"]
        fio_dict["read_clat_max"] = json_dict["jobs"][0]["read"]["clat_ns"]["max"]
        fio_dict["read_clat_mean"] = json_dict["jobs"][0]["read"]["clat_ns"]["mean"]
        fio_dict["read_clat_dev"] = json_dict["jobs"][0]["read"]["clat_ns"]["stddev"]

        if "read0" in test_type:
            fio_dict["read_clat_pct01"] = 99
            fio_dict["read_clat_pct02"] = 99.9
            fio_dict["read_clat_pct03"] = 99.99
            fio_dict["read_clat_pct04"] = 99.999
            fio_dict["read_clat_pct05"] = 99.9999
            fio_dict["read_clat_pct06"] = 100
            fio_dict["read_clat_pct07"] = 0
            fio_dict["read_clat_pct08"] = 0
            fio_dict["read_clat_pct09"] = 0
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = 0
            fio_dict["read_clat_pct02_val"] = 0
            fio_dict["read_clat_pct03_val"] = 0
            fio_dict["read_clat_pct04_val"] = 0
            fio_dict["read_clat_pct05_val"] = 0
            fio_dict["read_clat_pct06_val"] = 0
            fio_dict["read_clat_pct07_val"] = 0
            fio_dict["read_clat_pct08_val"] = 0
            fio_dict["read_clat_pct09_val"] = 0
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 99
            fio_dict["write_clat_pct02"] = 99.9
            fio_dict["write_clat_pct03"] = 99.99
            fio_dict["write_clat_pct04"] = 99.999
            fio_dict["write_clat_pct05"] = 99.9999
            fio_dict["write_clat_pct06"] = 100
            fio_dict["write_clat_pct07"] = 0
            fio_dict["write_clat_pct08"] = 0
            fio_dict["write_clat_pct09"] = 0
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.000000"]) // 1000
            fio_dict["write_clat_pct02_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.900000"]) // 1000
            fio_dict["write_clat_pct03_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.990000"]) // 1000
            fio_dict["write_clat_pct04_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999000"]) // 1000
            fio_dict["write_clat_pct05_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999900"]) // 1000
            fio_dict["write_clat_pct06_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["100.000000"]) // 1000
            fio_dict["write_clat_pct07_val"] = 0
            fio_dict["write_clat_pct08_val"] = 0
            fio_dict["write_clat_pct09_val"] = 0
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        elif "write0" in  test_type:
            fio_dict["read_clat_pct01"] = 99
            fio_dict["read_clat_pct02"] = 99.9
            fio_dict["read_clat_pct03"] = 99.99
            fio_dict["read_clat_pct04"] = 99.999
            fio_dict["read_clat_pct05"] = 99.9999
            fio_dict["read_clat_pct06"] = 100
            fio_dict["read_clat_pct07"] = 0
            fio_dict["read_clat_pct08"] = 0
            fio_dict["read_clat_pct09"] = 0
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.000000"]) // 1000
            fio_dict["read_clat_pct02_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.900000"]) // 1000
            fio_dict["read_clat_pct03_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.990000"]) // 1000
            fio_dict["read_clat_pct04_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999000"]) // 1000
            fio_dict["read_clat_pct05_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999900"]) // 1000
            fio_dict["read_clat_pct06_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["100.000000"]) // 1000
            fio_dict["read_clat_pct07_val"] = 0
            fio_dict["read_clat_pct08_val"] = 0
            fio_dict["read_clat_pct09_val"] = 0
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 99
            fio_dict["write_clat_pct02"] = 99.9
            fio_dict["write_clat_pct03"] = 99.99
            fio_dict["write_clat_pct04"] = 99.999
            fio_dict["write_clat_pct05"] = 99.9999
            fio_dict["write_clat_pct06"] = 100
            fio_dict["write_clat_pct07"] = 0
            fio_dict["write_clat_pct08"] = 0
            fio_dict["write_clat_pct09"] = 0
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = 0
            fio_dict["write_clat_pct02_val"] = 0
            fio_dict["write_clat_pct03_val"] = 0
            fio_dict["write_clat_pct04_val"] = 0
            fio_dict["write_clat_pct05_val"] = 0
            fio_dict["write_clat_pct06_val"] = 0
            fio_dict["write_clat_pct07_val"] = 0
            fio_dict["write_clat_pct08_val"] = 0
            fio_dict["write_clat_pct09_val"] = 0
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        else:
            fio_dict["read_clat_pct01"] = 99
            fio_dict["read_clat_pct02"] = 99.9
            fio_dict["read_clat_pct03"] = 99.99
            fio_dict["read_clat_pct04"] = 99.999
            fio_dict["read_clat_pct05"] = 99.9999
            fio_dict["read_clat_pct06"] = 100
            fio_dict["read_clat_pct07"] = 0
            fio_dict["read_clat_pct08"] = 0
            fio_dict["read_clat_pct09"] = 0
            fio_dict["read_clat_pct10"] = 0
            fio_dict["read_clat_pct11"] = 0
            fio_dict["read_clat_pct12"] = 0
            fio_dict["read_clat_pct13"] = 0
            fio_dict["read_clat_pct14"] = 0
            fio_dict["read_clat_pct15"] = 0
            fio_dict["read_clat_pct16"] = 0
            fio_dict["read_clat_pct17"] = 0
            fio_dict["read_clat_pct18"] = 0
            fio_dict["read_clat_pct19"] = 0
            fio_dict["read_clat_pct20"] = 0
            fio_dict["read_clat_pct01_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.000000"]) // 1000
            fio_dict["read_clat_pct02_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.900000"]) // 1000
            fio_dict["read_clat_pct03_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.990000"]) // 1000
            fio_dict["read_clat_pct04_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999000"]) // 1000
            fio_dict["read_clat_pct05_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["99.999900"]) // 1000
            fio_dict["read_clat_pct06_val"] = int(json_dict["jobs"][0]["read"]["clat_ns"]["percentile"]["100.000000"]) // 1000
            fio_dict["read_clat_pct07_val"] = 0
            fio_dict["read_clat_pct08_val"] = 0
            fio_dict["read_clat_pct09_val"] = 0
            fio_dict["read_clat_pct10_val"] = 0
            fio_dict["read_clat_pct11_val"] = 0
            fio_dict["read_clat_pct12_val"] = 0
            fio_dict["read_clat_pct13_val"] = 0
            fio_dict["read_clat_pct14_val"] = 0
            fio_dict["read_clat_pct15_val"] = 0
            fio_dict["read_clat_pct16_val"] = 0
            fio_dict["read_clat_pct17_val"] = 0
            fio_dict["read_clat_pct18_val"] = 0
            fio_dict["read_clat_pct19_val"] = 0
            fio_dict["read_clat_pct20_val"] = 0

            fio_dict["write_clat_pct01"] = 99
            fio_dict["write_clat_pct02"] = 99.9
            fio_dict["write_clat_pct03"] = 99.99
            fio_dict["write_clat_pct04"] = 99.999
            fio_dict["write_clat_pct05"] = 99.9999
            fio_dict["write_clat_pct06"] = 100
            fio_dict["write_clat_pct07"] = 0
            fio_dict["write_clat_pct08"] = 0
            fio_dict["write_clat_pct09"] = 0
            fio_dict["write_clat_pct10"] = 0
            fio_dict["write_clat_pct11"] = 0
            fio_dict["write_clat_pct12"] = 0
            fio_dict["write_clat_pct13"] = 0
            fio_dict["write_clat_pct14"] = 0
            fio_dict["write_clat_pct15"] = 0
            fio_dict["write_clat_pct16"] = 0
            fio_dict["write_clat_pct17"] = 0
            fio_dict["write_clat_pct18"] = 0
            fio_dict["write_clat_pct19"] = 0
            fio_dict["write_clat_pct20"] = 0
            fio_dict["write_clat_pct01_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.000000"]) // 1000
            fio_dict["write_clat_pct02_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.900000"]) // 1000
            fio_dict["write_clat_pct03_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.990000"]) // 1000
            fio_dict["write_clat_pct04_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999000"]) // 1000
            fio_dict["write_clat_pct05_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["99.999900"]) // 1000
            fio_dict["write_clat_pct06_val"] = int(json_dict["jobs"][0]["write"]["clat_ns"]["percentile"]["100.000000"]) // 1000
            fio_dict["write_clat_pct07_val"] = 0
            fio_dict["write_clat_pct08_val"] = 0
            fio_dict["write_clat_pct09_val"] = 0
            fio_dict["write_clat_pct10_val"] = 0
            fio_dict["write_clat_pct11_val"] = 0
            fio_dict["write_clat_pct12_val"] = 0
            fio_dict["write_clat_pct13_val"] = 0
            fio_dict["write_clat_pct14_val"] = 0
            fio_dict["write_clat_pct15_val"] = 0
            fio_dict["write_clat_pct16_val"] = 0
            fio_dict["write_clat_pct17_val"] = 0
            fio_dict["write_clat_pct18_val"] = 0
            fio_dict["write_clat_pct19_val"] = 0
            fio_dict["write_clat_pct20_val"] = 0

        fio_dict["read_tlat_min"] = json_dict["jobs"][0]["read"]["lat_ns"]["min"]
        fio_dict["read_lat_max"] = json_dict["jobs"][0]["read"]["lat_ns"]["max"]
        fio_dict["read_lat_mean"] = json_dict["jobs"][0]["read"]["lat_ns"]["mean"]
        fio_dict["read_lat_dev"] = json_dict["jobs"][0]["read"]["lat_ns"]["stddev"]
        fio_dict["read_bw_min"] = json_dict["jobs"][0]["read"]["bw_min"]
        fio_dict["read_bw_max"] = json_dict["jobs"][0]["read"]["bw_max"]
        fio_dict["read_bw_agg_pct"] = json_dict["jobs"][0]["read"]["bw_agg"]
        fio_dict["read_bw_mean"] = json_dict["jobs"][0]["read"]["bw_mean"]
        fio_dict["read_bw_dev"] = json_dict["jobs"][0]["read"]["bw_dev"]

        fio_dict["write_kb"] = json_dict["jobs"][0]["write"]["io_kbytes"]
        fio_dict["write_bandwidth"] = json_dict["jobs"][0]["write"]["bw"]
        fio_dict["write_iops"] = json_dict["jobs"][0]["write"]["iops"]
        fio_dict["write_runtime_ms"] = json_dict["jobs"][0]["write"]["runtime"]
        fio_dict["write_slat_min"] = json_dict["jobs"][0]["write"]["slat_ns"]["min"]
        fio_dict["write_slat_max"] = json_dict["jobs"][0]["write"]["slat_ns"]["max"]
        fio_dict["write_slat_mean"] = json_dict["jobs"][0]["write"]["slat_ns"]["mean"]
        fio_dict["write_slat_dev"] = json_dict["jobs"][0]["write"]["slat_ns"]["stddev"]
        fio_dict["write_clat_min"] = json_dict["jobs"][0]["write"]["clat_ns"]["min"]
        fio_dict["write_clat_max"] = json_dict["jobs"][0]["write"]["clat_ns"]["max"]
        fio_dict["write_clat_mean"] = json_dict["jobs"][0]["write"]["clat_ns"]["mean"]
        fio_dict["write_clat_dev"] = json_dict["jobs"][0]["write"]["clat_ns"]["stddev"]
        fio_dict["write_tlat_min"] = json_dict["jobs"][0]["write"]["lat_ns"]["min"]
        fio_dict["write_lat_max"] = json_dict["jobs"][0]["write"]["lat_ns"]["max"]
        fio_dict["write_lat_mean"] = json_dict["jobs"][0]["write"]["lat_ns"]["mean"]
        fio_dict["write_lat_dev"] = json_dict["jobs"][0]["write"]["lat_ns"]["stddev"]
        fio_dict["write_bw_min"] = json_dict["jobs"][0]["write"]["bw_min"]
        fio_dict["write_bw_max"] = json_dict["jobs"][0]["write"]["bw_max"]
        fio_dict["write_bw_agg_pct"] = json_dict["jobs"][0]["write"]["bw_agg"]
        fio_dict["write_bw_mean"] = json_dict["jobs"][0]["write"]["bw_mean"]
        fio_dict["write_bw_dev"] = json_dict["jobs"][0]["write"]["bw_dev"]

        fio_dict["cpu_user"] = json_dict["jobs"][0]["usr_cpu"]
        fio_dict["cpu_sys"] = json_dict["jobs"][0]["sys_cpu"]
        fio_dict["cpu_csw"] = json_dict["jobs"][0]["ctx"]
        fio_dict["cpu_mjf"] = json_dict["jobs"][0]["majf"]
        fio_dict["cpu_minf"] = json_dict["jobs"][0]["minf"]
        fio_dict["iodepth_1"] = json_dict["jobs"][0]["iodepth_level"]["1"]
        fio_dict["iodepth_2"] = json_dict["jobs"][0]["iodepth_level"]["2"]
        fio_dict["iodepth_4"] = json_dict["jobs"][0]["iodepth_level"]["4"]
        fio_dict["iodepth_8"] = json_dict["jobs"][0]["iodepth_level"]["8"]
        fio_dict["iodepth_16"] = json_dict["jobs"][0]["iodepth_level"]["16"]
        fio_dict["iodepth_32"] = json_dict["jobs"][0]["iodepth_level"]["32"]
        fio_dict["iodepth_64"] = json_dict["jobs"][0]["iodepth_level"][">=64"]

        fio_dict["lat_2us"] = json_dict["jobs"][0]["latency_us"]["2"]
        fio_dict["lat_4us"] = json_dict["jobs"][0]["latency_us"]["4"]
        fio_dict["lat_10us"] = json_dict["jobs"][0]["latency_us"]["10"]
        fio_dict["lat_20us"] = json_dict["jobs"][0]["latency_us"]["20"]
        fio_dict["lat_50us"] = json_dict["jobs"][0]["latency_us"]["50"]
        fio_dict["lat_100us"] = json_dict["jobs"][0]["latency_us"]["100"]
        fio_dict["lat_250us"] = json_dict["jobs"][0]["latency_us"]["250"]
        fio_dict["lat_500us"] = json_dict["jobs"][0]["latency_us"]["500"]
        fio_dict["lat_750us"] = json_dict["jobs"][0]["latency_us"]["750"]
        fio_dict["lat_1000us"] = json_dict["jobs"][0]["latency_us"]["1000"]

        fio_dict["lat_2ms"] = json_dict["jobs"][0]["latency_ms"]["2"]
        fio_dict["lat_4ms"] = json_dict["jobs"][0]["latency_ms"]["4"]
        fio_dict["lat_10ms"] = json_dict["jobs"][0]["latency_ms"]["10"]
        fio_dict["lat_20ms"] = json_dict["jobs"][0]["latency_ms"]["20"]
        fio_dict["lat_50ms"] = json_dict["jobs"][0]["latency_ms"]["50"]
        fio_dict["lat_100ms"] = json_dict["jobs"][0]["latency_ms"]["100"]
        fio_dict["lat_250ms"] = json_dict["jobs"][0]["latency_ms"]["250"]
        fio_dict["lat_500ms"] = json_dict["jobs"][0]["latency_ms"]["500"]
        fio_dict["lat_750ms"] = json_dict["jobs"][0]["latency_ms"]["750"]
        fio_dict["lat_1000ms"] = json_dict["jobs"][0]["latency_ms"]["1000"]
        fio_dict["lat_2000ms"] = json_dict["jobs"][0]["latency_ms"]["2000"]
        fio_dict["lat_over_2000ms"] = json_dict["jobs"][0]["latency_ms"][">=2000"]

        fio_dict["disk_name"] = json_dict["disk_util"][0]["name"]
        fio_dict["disk_read_iops"] = json_dict["disk_util"][0]["read_ios"]
        fio_dict["disk_write_iops"] = json_dict["disk_util"][0]["write_ios"]
        fio_dict["disk_read_merges"] = json_dict["disk_util"][0]["read_merges"]
        fio_dict["disk_write_merges"] = json_dict["disk_util"][0]["write_merges"]
        fio_dict["disk_read_ticks"] = json_dict["disk_util"][0]["read_ticks"]
        fio_dict["write_ticks"] = json_dict["disk_util"][0]["write_ticks"]
        fio_dict["disk_queue_time"] = json_dict["disk_util"][0]["in_queue"]
        fio_dict["disk_util"] = json_dict["disk_util"][0]["util"]

    # for k, v in fio_dict.items():
    #     print(k, v)
    return fio_dict


def create_fiodict_expanded_terse(file):
    fio_dict = {}

    # Only open relevant FIO files, which will have the bs string in the file name
    # Create dictionary of FIO vars and values
    str_file = str(file)
    if "bs" in str_file:
        with open(file, 'r') as reader:
            drive_data = str_file.split("_")
            drive_name = drive_data[0].split("/")[-1]
            drive_name = drive_name.split("-")
            friendly_name = ""
            for i in range(len(drive_name)):
                if i == 0:
                    friendly_name = friendly_name + drive_name[i]
                else:
                    friendly_name = friendly_name + " " + drive_name[i]
            model = drive_data[1]
            serial = drive_data[2]
            fw_rev = drive_data[3]
            timestamp = (drive_data[4] + " " + drive_data[5]).split("/")[0]
            cpu_model = drive_data[6]
            server_model = drive_data[7].split("/")[0]

            fio_data = reader.readline().split(";")
            fio_data[-1] = fio_data[-1].rstrip("\n")
            job_info = fio_data[2].split("_")
            test_type = job_info[0]
            ioengine = job_info[1]
            threads = job_info[2][1:]
            iodepth = job_info[3][2:]
            bs = job_info[4][2:]
            bs = bs.replace("k", "")

            fio_dict["friendly_name"] = friendly_name
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

            i = 0
            j = 0

            while i < len(fio_vars):
                if "=" in fio_data[j]:
                    percentile_data = fio_data[j].split("=")
                    percentile = percentile_data[0]
                    percentile_val = percentile_data[1]
                    fio_dict[fio_vars[i]] = percentile[:-1]
                    fio_dict[fio_vars[i + 1]] = percentile_val
                    i += 2
                else:
                    fio_dict[fio_vars[i]] = fio_data[j]
                    i += 1
                j += 1
    # for k, v in fio_dict.items():
    #    print(k, v)
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

    # for k, v in hammerdb_dict.items():
    #    print(k, v)

    return hammerdb_dict


if __name__ == '__main__':
    benchmark = str(sys.argv[1])
    fio_file_type = str(sys.argv[2])
    data_folder_name = str(sys.argv[3])
    execute(benchmark, fio_file_type, data_folder_name)
