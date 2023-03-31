#!/bin/bash
# Usage: ./Expanded_NVMe_Performance_FIO.sh <dev_device> <drive_alias> > output.txt 2>&1 &

NVMEDRIVE=$1
echo "Benchmark Drive: ${NVMEDRIVE}"
drive_name=$2

if [[ ${drive_name} =~ "_" ]]; then
   echo "The chosen drive alias: ${drive_name} contains underscores. Please remove any underscores '_' from your drive_alias name"
   exit
fi

testpath="/dev/${NVMEDRIVE}"

server_model=`sudo dmidecode -t1 | grep 'Product Name:' | xargs | cut -d ':' -f 2 | xargs | tr " " - | xargs`
cpu_model=`sudo cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2 | xargs | tr " " - | tr "@" a | tr "(" - | tr ")" - | xargs`
serial_num=`nvme id-ctrl ${testpath} | awk '$1=="sn" {print $3}'`
model_num=`nvme id-ctrl ${testpath} | awk '$1=="mn" {print $3, $4, $5, $6, $7, $8}' | xargs | tr " " - | tr "_" - | xargs`
fw_rev=`nvme id-ctrl ${testpath} | awk '$1=="fr" {print $3}'`
cap_Bytes=`nvme id-ctrl ${testpath} | awk '$1=="tnvmcap" {print $3}'`

echo "Drive Name: ${drive_name}"
echo "Server: ${server_model}"
echo "CPU: ${cpu_model}"
echo "Serial Num: ${serial_num}"
echo "Model Num: ${model_num}"
echo "FW_REV: ${fw_rev}"
echo "Cap Bytes: ${cap_Bytes}"

date=$(date '+%m-%d-%Y')
timestamp=$(date +'%T')
timestamp=`echo $timestamp | tr : -`
result_dir=`echo "${drive_name}_${model_num}_${serial_num}_${fw_rev}_${date}_${timestamp}_${cpu_model}_${server_model}" | xargs`
telemetry_dir="telemetry_logs"
run_output_dir="run_output"
rand_output_dir="random"
seq_output_dir="sequential"
outputcsv_dir="output_csv"

mkdir ${result_dir}
cd ${result_dir}

mkdir ${telemetry_dir}
cd ${telemetry_dir}

echo "Getting telemetry log prior to running workload started at"
date
nvme telemetry-log /dev/${NVMEDRIVE} --output-file=${model_num}_telemetry_${date}_before_workload
echo "Getting telemetry log prior to running workload completed at"
date

echo "Formatting drive started at"
date
nvme format /dev/${NVMEDRIVE} --ses=1 --force
echo "Formatting completed at"
date

cd ..

mkdir ${run_output_dir}
cd ${run_output_dir}
mkdir ${outputcsv_dir}
mkdir ${rand_output_dir}
mkdir ${seq_output_dir}

#ioengine
ioeng="libaio"

#run type
run_type="json+"

#bs
rnd_block_size=(4k 8k 16k 32k 64k 128k 512k 1024k)
seq_block_size=(128k 512k 1024k)

#queue depth
rnd_qd=(1 2 4 8 16 32 64)
seq_qd=(1 2 4 8 16 32 64)

#percentile_list
perc_list="99:99.9:99.99:99.999:99.9999:100"

#read write percentages
rd_wr_perc=(0 30 50 70 100)

cd ${rand_output_dir}

#####################################
###    RANDOM BS WORKLOAD ONLY    ###
#####################################
for bs in "${rnd_block_size[@]}"; do
    mkdir ${bs}
    cd ${bs}

    echo "Workload Independent Preconditioning with bs=128k started at"
    date
    echo "workload:fio --direct=1 --rw=write  --bs=128k --iodepth=32 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128k_qd32_t1 --group_reporting --filename=/dev/${NVMEDRIVE} --output-format=json+ --loops=2"
    fio --direct=1 --rw=write  --bs=128k --iodepth=32 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128k_qd32_t1 --group_reporting --filename=/dev/${NVMEDRIVE} --output-format=json+ --loops=2
    echo "Workload Independent Preconditioning completed at"
    date

    echo "Workload Dependent Preconditioning with bs=${bs} started at"
    date
    echo "workload:fio --direct=1 --rw=randwrite  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/${NVMEDRIVE}  --output-format=json+ --loops=3"
    fio --direct=1 --rw=randwrite  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/${NVMEDRIVE}  --output-format=json+ --loops=3
    echo "Workload Dependent Preconditioning completed at"
    date

    for perc in "${rd_wr_perc[@]}"; do

        rd_perc=${perc}
        wr_perc="$((100-${rd_perc}))"

        for qd in "${rnd_qd[@]}"; do

            if [[ "${run_type}" == "json+" ]]; then
                if [ ${qd} -eq 1 ]; then
                    t=1
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date
                elif [ ${qd} -eq 2 ]; then
                    t=1
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date

                    t=2
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date
                elif [ ${qd} -eq 4 ]; then
                    t=2
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date

                    t=4
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date

                    t=8
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date
                else
                    t=8
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.json
                    date
                fi

            else
                if [ ${qd} -eq 1 ]; then
                    t=1
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date
                elif [ ${qd} -eq 2 ]; then
                    t=1
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date

                    t=2
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date
                elif [ ${qd} -eq 4 ]; then
                    t=2
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date

                    t=4
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date

                    t=8
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date
                else
                    t=8
                    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t${t} qd${qd}"
                    date
                    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv"
                    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t${t}_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads${t}-depth${qd}.csv
                    date
                fi
            fi
        done
    done

    cd ..

    if [[ "${run_type}" == "terse" ]]; then
        for file in ${bs}/*
        do
            cat "$file" >> ${bs}random_output.csv
        done
        mv ${bs}random_output.csv /home/labuser/${result_dir}/${run_output_dir}/${outputcsv_dir}/
    fi
    sudo python3 /home/labuser/database_insert.py fio_expanded ${result_dir}/${run_output_dir}/${rand_output_dir}/${bs}/
done



cd ..

cd ${seq_output_dir}

#########################################
###    SEQUENTIAL BS WORKLOAD ONLY    ###
#########################################
for bs in "${seq_block_size[@]}"; do
    mkdir ${bs}
    cd ${bs}

    echo "Workload Independent Preconditioning with bs=128k started at"
    date
    echo "workload:fio --direct=1 --rw=write  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/${NVMEDRIVE}  --output-format=json+ --loops=3"
    fio --direct=1 --rw=write  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/${NVMEDRIVE}  --output-format=json+ --loops=3
    echo "Workload Independent Preconditioning done at"
    date

    for perc in "${rd_wr_perc[@]}"; do
        rd_perc=${perc}
        wr_perc="$((100-${rd_perc}))"

        for qd in "${seq_qd[@]}"; do
            if [[ "${run_type}" == "json+" ]]; then
                echo "Sequential Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t1 qd${qd}"
                date
                echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-seqmixedread${rd_perc}write${wr_perc}_-bs${bs}-threads1-depth${qd}.json"
                fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}_seqmixedread${rd_perc}write${wr_perc}-bs${bs}-threads1-depth${qd}.json
                date
            else
                echo "Sequential Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t1 qd${qd}"
                date
                echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}-seqmixedread${rd_perc}write${wr_perc}_-bs${bs}-threads1-depth${qd}.csv"
                fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/${NVMEDRIVE} --output=${result_dir}_seqmixedread${rd_perc}write${wr_perc}-bs${bs}-threads1-depth${qd}.csv
                date
            fi
        done
    done

    cd ..

    if [ "${run_type}" = "terse" ]; then
        for file in ${bs}/*
        do
            cat "$file" >> ${bs}random_output.csv
        done
        mv ${bs}sequential_output.csv /home/labuser/${result_dir}/${run_output_dir}/${outputcsv_dir}/
    fi


    sudo python3 /home/labuser/database_insert.py fio_expanded ${result_dir}/${run_output_dir}/${seq_output_dir}/${bs}/
done

cd ..
cd ..

cd ${telemetry_dir}
echo "Getting telemetry log after running workload started at"
date
nvme telemetry-log /dev/$NVMEDRIVE --output-file=${model_num}_telemetry_${date}_after_workload
echo "Getting telemetry log after running workload completed at"
date

echo "Results are in $result_dir"

exit
