#!/bin/bash
#Usage: ./NVMe_FourCorners_FIO.sh

#read -p "Which drive should benchmark use? Existing data will be lost! [default 'nvme0n1']: " NVMEDRIVE
#NVMEDRIVE=${NVMEDRIVE:-'nvme0n1'}

NVMEDRIVE=$1
echo "Benchmark Drive: $NVMEDRIVE"

testpath=/dev/$NVMEDRIVE
echo $testpath

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


cap_TB=$(($cap_Bytes / $TB_multiplier))
cap_TB=$((cap_TB+1))

num_loops=2
iosize=$(($cap_TB * $num_loops * 1000))

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

echo "Getting telemetry log prior to running workload started at"
date
nvme telemetry-log /dev/$NVMEDRIVE --output-file=${model_num}_telemetry_${date}_before_workload

echo "Getting telemetry log prior to running workload completed at"
date

echo "Formatting drive started at"
date
nvme format /dev/$NVMEDRIVE --ses=1 --force
echo "Formatting completed at"
date

#ioengine
ioeng="libaio"

cd ..

mkdir ${run_output_dir}
cd ${run_output_dir}

#iodepths
seq_rd_qd=32
seq_wr_qd=32
rnd_rd_qd=64
rnd_wr_qd=64
mix_rnd_rd_wr_qd=64

run_type="terse"

echo "Sequential preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3
echo "Sequential preconditioning completed at"
date

#numjobs
threads=(1 8)

#percentile_list
perc_list="99:99.9:99.99:99.999:99.9999:100"

for t in "${threads[@]}"; do

echo "Sequential Write bs=128k t${t} qd${seq_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t${t}_qd${seq_wr_qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqwrite-bs128k-threads${t}-depth${seq_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t${t}_qd${seq_wr_qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqwrite-bs128k-threads${t}-depth${seq_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Sequential Read  bs=128k t${t} qd${seq_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t${t}_qd${seq_rd_qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqread-bs128k-threads${t}-depth${seq_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t${t}_qd${seq_rd_qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqread-bs128k-threads${t}-depth${seq_rd_qd}
date

done

echo "Sequential preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3
echo "Sequential preconditioning completed at"
date

echo "Random preconditioning for bs=4K started at"
date
echo "workload:fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=0 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=0 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3
echo "Random preconditioning done at"
date

for t in "${threads[@]}"; do

echo "Random Write bs=4k t${t} qd${rnd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t${t}_qd${rnd_wr_qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randwrite-bs4k-threads${t}-depth${rnd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t${t}_qd${rnd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randwrite-bs4k-threads${t}-depth${rnd_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Random Mixed 30% Read 70% Write bs=4k t${t} qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=30 --rwmixwrite=70 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread30write70_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread30write70_-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=30 --rwmixwrite=70 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread30write70_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread30write70-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}
date

done


for t in "${threads[@]}"; do

echo "Random Mixed 50% Read 50% Write bs=4k t${t} qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=50 --rwmixwrite=50 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread50write50_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread50write50_-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=50 --rwmixwrite=50 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread50write50_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread50write50-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Random Mixed 70% Read 30% Write bs=4k t${t} qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread70write30_-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread70write30-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Random Read bs=4k t${t} qd${rnd_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t${t}_qd${rnd_rd_qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randread-bs4k-threads${t}-depth${rnd_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t${t}_qd${rnd_rd_qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randread-bs4k-threads${t}-depth${rnd_rd_qd}
date

done

cd ..

for file in ${run_output_dir}/*
do
  cat "$file" >> output.csv
done 


mv output.csv ${result_dir}/output.csv

cd /home/labuser/${result_dir}/${run_output_dir}

for f in *; do mv "$f" "$f.txt"; done

cd ..

cd ${telemetry_dir}

echo "Getting telemetry log after running workload started at"
date
nvme telemetry-log /dev/$NVMEDRIVE --output-file=${model_num}_telemetry_${date}_after_workload

echo "Getting telemetry log after running workload completed at"
date

cd ..
cd ..

echo "Results are in $result_dir"

#sudo python3 database_insert.py fio $result_dir
#sudo python3 excel_creator.py $result_dir

exit
