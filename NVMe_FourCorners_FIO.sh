#!/bin/bash
# Usage: sudo ./NVMe_FourCorners_FIO.sh <dev_device>
# Example: sudo ./NVMe_FourCorners_FIO.sh nvme1n1

#read -p "Which drive should benchmark use? Existing data will be lost! [default 'nvme0n1']: " NVMEDRIVE
#NVMEDRIVE=${NVMEDRIVE:-'nvme0n1'}

NVMEDRIVE=$1
echo "Benchmark Drive: $NVMEDRIVE"

testpath=/dev/$NVMEDRIVE
echo $testpath

#ioengine
ioeng="libaio"
#iodepths
seq_rd_qd=32
seq_wr_qd=32
rnd_rd_qd=256
rnd_wr_qd=32
mix_rnd_rd_wr_qd=32
#run type
run_type="normal"
#percentile_list
perc_list="50:99:99.9:99.99:99.999:99.9999:99.99999:99.999999:100"

server_model=`sudo dmidecode -t1 | grep 'Product Name:' | xargs | cut -d ':' -f 2 | xargs | tr " " - | xargs`
cpu_model=`sudo cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2 | xargs | tr " " - | tr "@" a | tr "(" - | tr ")" - | xargs`
serial_num=`nvme id-ctrl $testpath | awk '$1=="sn" {print $3}'`
model_num=`nvme id-ctrl $testpath | awk '$1=="mn" {print $3, $4, $5, $6, $7}' | xargs | tr " " - | xargs`
fw_rev=`nvme id-ctrl $testpath | awk '$1=="fr" {print $3}'`
cap_Bytes=`nvme id-ctrl $testpath | awk '$1=="tnvmcap" {print $3}'`
TB_multiplier=1000000000000
echo "Server: $server_model"
echo "CPU: $cpu_model"
echo "Serial Num: $serial_num"
echo "Model Num: $model_num"
echo "FW_REV: $fw_rev"
echo "Cap Bytes: $cap_Bytes"

date=$(date '+%Y%m%d')
timestamp=$(date '+%H%M%S')
result_dir=`echo "${model_num}_${serial_num}_${fw_rev}_${date}_${timestamp}_${cpu_model}_${server_model}" | xargs`
telemetry_dir="Telemetry_Logs"
run_output_dir="Run_Output"

if [ -d ${result_dir} ]
then
    echo "Directory ${result_dir} exists." 
    exit 0
else
    mkdir ${result_dir}
fi

cd ${result_dir}

mkdir ${telemetry_dir}
cd ${telemetry_dir}

#echo "Getting telemetry log prior to running workload started at"
#date
#nvme telemetry-log /dev/$NVMEDRIVE --output-file=${model_num}_telemetry_${date}_before_workload

#echo "Getting telemetry log prior to running workload completed at"
#date

cd ..

echo "Formatting drive started at"
date
nvme format /dev/$NVMEDRIVE --ses=1 --force
echo "Formatting completed at"
date

mkdir ${run_output_dir}
cd ${run_output_dir}

echo "Sequential preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2"
fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2
echo "Sequential preconditioning completed at"
date

echo "Sequential Write bs=128k t1 qd${seq_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t1_qd${seq_wr_qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqwrite-bs128k-threads1-depth${seq_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t1_qd${seq_wr_qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqwrite-bs128k-threads1-depth${seq_wr_qd}
date

echo "Sequential Read  bs=128k t1 qd${seq_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t1_qd${seq_rd_qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqread-bs128k-threads1-depth${seq_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t1_qd${seq_rd_qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqread-bs128k-threads1-depth${seq_rd_qd}
date

echo "Sequential preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2"
fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2
echo "Sequential preconditioning completed at"
date

echo "Random preconditioning for bs=4K started at"
date
echo "workload:fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3
echo "Random preconditioning done at"
date

echo "Random Write bs=4k t8 qd${rnd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t8_qd${rnd_wr_qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randwrite-bs4k-threads8-depth${rnd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t8_qd${rnd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randwrite-bs4k-threads8-depth${rnd_wr_qd}
date

echo "Random Mixed 30% Read 70% Write bs=4k t8 qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=30 --rwmixwrite=70 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread30write70_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread30write70_-bs4k-threads8-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=30 --rwmixwrite=70 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread30write70_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread30write70-bs4k-threads8-depth${mix_rnd_rd_wr_qd}
date

echo "Random Mixed 50% Read 50% Write bs=4k t8 qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=50 --rwmixwrite=50 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread50write50_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread50write50_-bs4k-threads8-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=50 --rwmixwrite=50 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread50write50_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread50write50-bs4k-threads8-depth${mix_rnd_rd_wr_qd}
date

echo "Random Mixed 70% Read 30% Write bs=4k t8 qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread70write30_-bs4k-threads8-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t8_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread70write30-bs4k-threads8-depth${mix_rnd_rd_wr_qd}
date

echo "Random Read bs=4k t8 qd${rnd_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t8_qd${rnd_rd_qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randread-bs4k-threads8-depth${rnd_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t8_qd${rnd_rd_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randread-bs4k-threads8-depth${rnd_rd_qd}
date

cd ..

#for file in ${run_output_dir}/*
#do
#  cat "$file" >> output.csv
#done 


#mv output.csv ${result_dir}/output.csv

cd /home/labuser/${result_dir}/${run_output_dir}

for f in *; do mv "$f" "$f.txt"; done

cd ..

cd ${telemetry_dir}

#echo "Getting telemetry log after running workload started at"
#date
#nvme telemetry-log /dev/$NVMEDRIVE --output-file=${model_num}_telemetry_${date}_after_workload

#echo "Getting telemetry log after running workload completed at"
#date

echo "Results are in $result_dir"
