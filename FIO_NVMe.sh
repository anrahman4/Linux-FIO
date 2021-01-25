#!/bin/bash
#Usage: ./FIO_NVME.sh

read -p "Which drive should benchmark use? Existing data will be lost! [default 'nvme0n1']: " NVMEDRIVE
NVMEDRIVE=${NVMEDRIVE:-'nvme0n1'}
echo "Benchmark Drive: $NVMEDRIVE"

testpath=/dev/$NVMEDRIVE
echo $testpath
controller=${testpath::-3}
echo $controller

server_model=`sudo dmidecode -t1 | grep 'Product Name:' | xargs | cut -d ':' -f 2 | xargs | tr " " - | xargs`
cpu_model=`sudo cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2 | xargs | tr " " - | tr "@" a | tr "(" - | tr ")" - | xargs`
serial_num=`nvme id-ctrl $testpath | awk '$1=="sn" {print $3}'`
model_num=`nvme id-ctrl $testpath | awk '$1=="mn" {print $3}'`
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

echo "Getting telemetry log prior to running workload"
nvme telemetry-log /dev/$NVMEDRIVE --output-file=CD6_telemetry_${date}_before_workload

echo "formatting drive started at"
date
nvme format /dev/$NVMEDRIVE --ses=1
echo "formatting completed at"
date

#ioengine
ioeng="libaio"

cd ..

mkdir ${run_output_dir}
cd ${run_output_dir}

echo "workload independent preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd256 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2"
fio --direct=1 --rw=write  --bs=128K --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd256 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=2

echo "workload:fio --direct=1 --rw=write  --bs=4K --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs4K_qd128 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=1"
fio --direct=1 --rw=write  --bs=4K --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=1


echo "workload independent preconditioning done at"
date

#block_size=(512b 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m)
block_size=(4k 128k)

#iodepths
queue_depths=(1 2 4 8 16 32 64 128 256)
seq_rd_qd=32
seq_wr_qd=32
rnd_rd_qd=256
rnd_wr_qd=256
mix_rnd_rd_wr_qd=256

#numjobs
threads=(1 2 4 8 16 32 64 128 256)

for qd in "${queue_depths[@]}"; do

for t in "${threads[@]}"; do

echo "Sequential Read  bs=128k t${t} qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=seqread_${ioeng}_t${t}_qd${qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqread-bs128k-threads${t}-depth${qd}"
fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=seqread_${ioeng}_t${t}_qd${qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqread-bs128k-threads${t}-depth${qd}
date

echo "Sequential Write bs=128k t${t} qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=seqwrite_${ioeng}_t${t}_qd${qd}_bs128k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-seqwrite-bs128k-threads${t}-depth${qd}"
fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=seqwrite_${ioeng}_t${t}_qd${qd}_bs128k --filename=/dev/$NVMEDRIVE --output=${result_dir}_seqwrite-bs128k-threads${t}-depth${qd}
date

echo "Random Read bs=4k t${t} qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randread_${ioeng}_t${t}_qd${qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randread-bs4k-threads${t}-depth${qd}"
fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randread_${ioeng}_t${t}_qd${qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randread-bs4k-threads${t}-depth${qd}
date

echo "Random Write bs=4k t${t} qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randwrite_${ioeng}_t${t}_qd${qd}_bs4k  --filename=/dev/$NVMEDRIVE --output=${result_dir}-randwrite-bs4k-threads${t}-depth${qd}"
fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randwrite_${ioeng}_t${t}_qd${qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randwrite-bs4k-threads${t}-depth${qd}
date

echo "Random Mixed 70% Read 30% Write bs=4k t${t} qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randmixedread70write30_${ioeng}_t${t}_qd${qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}-randmixedread70write30_-bs4k-threads${t}-depth${qd}"
fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --name=randmixedread70write30_${ioeng}_t${t}_qd${qd}_bs4k --filename=/dev/$NVMEDRIVE --output=${result_dir}_randmixedread70write30-bs4k-threads${t}-depth${qd}
date

done

done

cd ..

for file in ${run_output_dir}/*
do
  cat "$file" >> output.csv
done 


mv output.csv ${run_output_dir}/output.csv


cd ${telemetry_dir}

echo "Getting telemetry log after running workload"
nvme telemetry-log /dev/$NVMEDRIVE --output-file=CD6_telemetry_${date}_after_workload

cd ..
cd ..

echo "Results are in $result_dir"

sudo python3 database_insert.py fio $result_dir
