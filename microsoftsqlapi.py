import pyodbc


class SQLServerAPI:
    def __init__(self, driver, server_ip, database_name, username, password):
        self.DRIVER = driver
        self.SERVER = server_ip
        self.DATABASE = database_name
        self.USERNAME = username
        self.PASSWORD = password

        print("Testing Connection to SQL Server ...")
        self.connect()
        print("Connection was successful ...")

    def connect(self):
        cnxn = pyodbc.connect(
            'DRIVER=' + self.DRIVER +
            ';SERVER=' + self.SERVER +
            ';DATABASE=' + self.DATABASE +
            ';UID=' + self.USERNAME +
            ';PWD=' + self.PASSWORD)
        cursor = cnxn.cursor()

    def insert_hammerdb(self, key_dict):
        cnxn = pyodbc.connect(
            'DRIVER=' + self.DRIVER +
            ';SERVER=' + self.SERVER +
            ';DATABASE=' + self.DATABASE +
            ';UID=' + self.USERNAME +
            ';PWD=' + self.PASSWORD)
        cursor = cnxn.cursor()
        cursor.execute('''
                       INSERT INTO APL_Performance.dbo.hammerdb_tpcc VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
                       ''',
                       (key_dict["date"],
                        key_dict["timestamp"],
                        key_dict["ram"],
                        key_dict["model"],
                        key_dict["serial"],
                        key_dict["fw_rev"],
                        key_dict["capacity"],
                        key_dict["database"],
                        key_dict["benchmark"],
                        key_dict["warehouses"],
                        key_dict["mysql_test_type"],
                        key_dict["mysql_test_time"],
                        key_dict["use_all_ware"],
                        key_dict["num_virt_usr_run"],
                        key_dict["delay_time"],
                        key_dict["repeat_time"],
                        key_dict["iter"],
                        key_dict["tpm"],
                        key_dict["nopm"]))
        cursor.commit()
        cnxn.close()
        return "Insertion of HammerDB Data Successful"

    def insert_fio_expanded(self, key_dict):
        cnxn = pyodbc.connect(
            'DRIVER=' + self.DRIVER +
            ';SERVER=' + self.SERVER +
            ';DATABASE=' + self.DATABASE +
            ';UID=' + self.USERNAME +
            ';PWD=' + self.PASSWORD, timeout=300)
        cursor = cnxn.cursor()
        cursor.execute('''
                          INSERT INTO APL_Performance.dbo.fio_expanded VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?, ?, ?, ?) 
                       ''',
                       (key_dict["friendly_name"],
                        key_dict["server_model"],
                        key_dict["cpu_model"],
                        key_dict["model"],
                        key_dict["serial"],
                        key_dict["fw_rev"],
                        key_dict["timestamp"],
                        key_dict["terse_version_3"],
                        key_dict["fio_version"],
                        key_dict["jobname"],
                        key_dict["test_type"],
                        key_dict["threads"],
                        key_dict["bs"],
                        key_dict["io_engine"],
                        key_dict["iodepth"],
                        key_dict["groupid"],
                        key_dict["error"],
                        key_dict["read_kb"],
                        key_dict["read_bandwidth"],
                        key_dict["read_iops"],
                        key_dict["read_runtime_ms"],
                        key_dict["read_slat_min"],
                        key_dict["read_slat_max"],
                        key_dict["read_slat_mean"],
                        key_dict["read_slat_dev"],
                        key_dict["read_clat_min"],
                        key_dict["read_clat_max"],
                        key_dict["read_clat_mean"],
                        key_dict["read_clat_dev"],
                        key_dict["read_clat_pct01"],
                        key_dict["read_clat_pct01_val"],
                        key_dict["read_clat_pct02"],
                        key_dict["read_clat_pct02_val"],
                        key_dict["read_clat_pct03"],
                        key_dict["read_clat_pct03_val"],
                        key_dict["read_clat_pct04"],
                        key_dict["read_clat_pct04_val"],
                        key_dict["read_clat_pct05"],
                        key_dict["read_clat_pct05_val"],
                        key_dict["read_clat_pct06"],
                        key_dict["read_clat_pct06_val"],
                        key_dict["read_clat_pct07"],
                        key_dict["read_clat_pct07_val"],
                        key_dict["read_clat_pct08"],
                        key_dict["read_clat_pct08_val"],
                        key_dict["read_clat_pct09"],
                        key_dict["read_clat_pct09_val"],
                        key_dict["read_clat_pct10"],
                        key_dict["read_clat_pct10_val"],
                        key_dict["read_clat_pct11"],
                        key_dict["read_clat_pct11_val"],
                        key_dict["read_clat_pct12"],
                        key_dict["read_clat_pct12_val"],
                        key_dict["read_clat_pct13"],
                        key_dict["read_clat_pct13_val"],
                        key_dict["read_clat_pct14"],
                        key_dict["read_clat_pct14_val"],
                        key_dict["read_clat_pct15"],
                        key_dict["read_clat_pct15_val"],
                        key_dict["read_clat_pct16"],
                        key_dict["read_clat_pct16_val"],
                        key_dict["read_clat_pct17"],
                        key_dict["read_clat_pct17_val"],
                        key_dict["read_clat_pct18"],
                        key_dict["read_clat_pct18_val"],
                        key_dict["read_clat_pct19"],
                        key_dict["read_clat_pct19_val"],
                        key_dict["read_clat_pct20"],
                        key_dict["read_clat_pct20_val"],
                        key_dict["read_tlat_min"],
                        key_dict["read_lat_max"],
                        key_dict["read_lat_mean"],
                        key_dict["read_lat_dev"],
                        key_dict["read_bw_min"],
                        key_dict["read_bw_max"],
                        key_dict["read_bw_agg_pct"],
                        key_dict["read_bw_mean"],
                        key_dict["read_bw_dev"],
                        key_dict["write_kb"],
                        key_dict["write_bandwidth"],
                        key_dict["write_iops"],
                        key_dict["write_runtime_ms"],
                        key_dict["write_slat_min"],
                        key_dict["write_slat_max"],
                        key_dict["write_slat_mean"], 
                        key_dict["write_slat_dev"], 
                        key_dict["write_clat_min"],
                        key_dict["write_clat_max"], 
                        key_dict["write_clat_mean"], 
                        key_dict["write_clat_dev"], 
                        key_dict["write_clat_pct01"],
                        key_dict["write_clat_pct01_val"],
                        key_dict["write_clat_pct02"],
                        key_dict["write_clat_pct02_val"],
                        key_dict["write_clat_pct03"],
                        key_dict["write_clat_pct03_val"],
                        key_dict["write_clat_pct04"],
                        key_dict["write_clat_pct04_val"],
                        key_dict["write_clat_pct05"],
                        key_dict["write_clat_pct05_val"],
                        key_dict["write_clat_pct06"],
                        key_dict["write_clat_pct06_val"],
                        key_dict["write_clat_pct07"],
                        key_dict["write_clat_pct07_val"],
                        key_dict["write_clat_pct08"],
                        key_dict["write_clat_pct08_val"],
                        key_dict["write_clat_pct09"],
                        key_dict["write_clat_pct09_val"],
                        key_dict["write_clat_pct10"],
                        key_dict["write_clat_pct10_val"],
                        key_dict["write_clat_pct11"],
                        key_dict["write_clat_pct11_val"],
                        key_dict["write_clat_pct12"],
                        key_dict["write_clat_pct12_val"],
                        key_dict["write_clat_pct13"],
                        key_dict["write_clat_pct13_val"],
                        key_dict["write_clat_pct14"],
                        key_dict["write_clat_pct14_val"],
                        key_dict["write_clat_pct15"],
                        key_dict["write_clat_pct15_val"],
                        key_dict["write_clat_pct16"],
                        key_dict["write_clat_pct16_val"],
                        key_dict["write_clat_pct17"],
                        key_dict["write_clat_pct17_val"],
                        key_dict["write_clat_pct18"],
                        key_dict["write_clat_pct18_val"],
                        key_dict["write_clat_pct19"],
                        key_dict["write_clat_pct19_val"],
                        key_dict["write_clat_pct20"],
                        key_dict["write_clat_pct20_val"],
                        key_dict["write_tlat_min"],
                        key_dict["write_lat_max"],
                        key_dict["write_lat_mean"],
                        key_dict["write_lat_dev"], 
                        key_dict["write_bw_min"],
                        key_dict["write_bw_max"],
                        key_dict["write_bw_agg_pct"],
                        key_dict["write_bw_mean"],
                        key_dict["write_bw_dev"],
                        key_dict["cpu_user"],
                        key_dict["cpu_sys"],
                        key_dict["cpu_csw"],
                        key_dict["cpu_mjf"], 
                        key_dict["cpu_minf"],
                        key_dict["iodepth_1"],
                        key_dict["iodepth_2"],
                        key_dict["iodepth_4"],
                        key_dict["iodepth_8"],
                        key_dict["iodepth_16"],
                        key_dict["iodepth_32"],
                        key_dict["iodepth_64"],
                        key_dict["lat_2us"],
                        key_dict["lat_4us"],
                        key_dict["lat_10us"],
                        key_dict["lat_20us"],
                        key_dict["lat_50us"],
                        key_dict["lat_100us"],
                        key_dict["lat_250us"],
                        key_dict["lat_500us"],
                        key_dict["lat_750us"],
                        key_dict["lat_1000us"],
                        key_dict["lat_2ms"],
                        key_dict["lat_4ms"],
                        key_dict["lat_10ms"],
                        key_dict["lat_20ms"],
                        key_dict["lat_50ms"],
                        key_dict["lat_100ms"],
                        key_dict["lat_250ms"],
                        key_dict["lat_500ms"],
                        key_dict["lat_750ms"],
                        key_dict["lat_1000ms"],
                        key_dict["lat_2000ms"],
                        key_dict["lat_over_2000ms"],
                        key_dict["disk_name"],
                        key_dict["disk_read_iops"],
                        key_dict["disk_write_iops"],
                        key_dict["disk_read_merges"],
                        key_dict["disk_write_merges"],
                        key_dict["disk_read_ticks"],
                        key_dict["write_ticks"],
                        key_dict["disk_queue_time"],
                        key_dict["disk_util"]))
        cursor.commit()
        cnxn.close()
        print("Insertion of FIO Data Successful")
