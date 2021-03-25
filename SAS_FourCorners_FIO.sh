#!/bin/bash
#Usage: ./SAS_FourCorners_FIO.sh

#read -p "Which drive should benchmark use? Existing data will be lost! [default 'sdd']: " SASDRIVE
#SASDRIVE=${SASDRIVE:-'sdd'}

SASDRIVE=$1
echo "Benchmark Drive: $SASDRIVE"

testpath=/dev/${SASDRIVE}
echo $testpath

server_model=`sudo dmidecode -t1 | grep 'Product Name:' | xargs | cut -d ':' -f 2 | xargs | tr " " - | xargs`
cpu_model=`sudo cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2 | xargs | tr " " - | tr "@" a | tr "(" - | tr ")" - | xargs`
vendor=`smartctl -i /dev/$SASDRIVE | awk '$1=="Vendor:" {print $2}'`
product=`smartctl -i /dev/$SASDRIVE | awk '$1=="Product:" {print $2}'`
product=`echo ${product/\//-}`
serial=`sudo smartctl -i /dev/$SASDRIVE | awk '$1=="Serial" {print $3}'`
fw_rev=`smartctl -i /dev/$SASDRIVE | awk '$1=="Revision:" {print $2}'`

echo "Server: $server_model"
echo "CPU: $cpu_model"
echo "Vendor: $vendor"
echo "Product: $product"
echo "Serial: $serial"
echo "FW_REV: $fw_rev"

date=$(date '+%Y%m%d')
timestamp=$(date '+%H%M%S')
result_dir=`echo "${product}_${serial}_${fw_rev}_${date}_${timestamp}_${cpu_model}_${server_model}" | xargs`
run_output_dir="Run_Output"

if [ -d ${result_dir} ]
then
    echo "Directory ${result_dir} exists." 
    exit 0
else
    mkdir ${result_dir}
fi

cd ${result_dir}

mkdir ${run_output_dir}
cd ${run_output_dir}

#ioengine
ioeng="libaio"

#iodepths
seq_rd_qd=32
seq_wr_qd=32
rnd_rd_qd=64
rnd_wr_qd=64
mix_rnd_rd_wr_qd=64

#numjobs
threads=(1 8)

run_type="terse"

#percentile_list
perc_list="99:99.9:99.99:99.999:99.9999:100"

echo "Sequential preconditioning for bs=128K started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=write  --bs=128K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3
echo "Sequential preconditioning completed at"
date

for t in "${threads[@]}"; do

echo "Sequential Write bs=128k t${t} qd${seq_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t${t}_qd${seq_wr_qd}_bs128k  --filename=/dev/$SASDRIVE --output=${result_dir}-seqwrite-bs128k-threads${t}-depth${seq_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqwrite_${ioeng}_t${t}_qd${seq_wr_qd}_bs128k --filename=/dev/$SASDRIVE --output=${result_dir}_seqwrite-bs128k-threads${t}-depth${seq_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Sequential Read  bs=128k t${t} qd${seq_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t${t}_qd${seq_rd_qd}_bs128k  --filename=/dev/$SASDRIVE --output=${result_dir}-seqread-bs128k-threads${t}-depth${seq_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqread_${ioeng}_t${t}_qd${seq_rd_qd}_bs128k --filename=/dev/$SASDRIVE --output=${result_dir}_seqread-bs128k-threads${t}-depth${seq_rd_qd}
date

done

echo "Random preconditioning for bs=4K started at"
date
echo "workload:fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=randwrite  --bs=4K --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs4K_qd128_t1 --group_reporting --filename=/dev/$NVMEDRIVE  --output-format=terse --loops=3
echo "Random preconditioning done at"
date

for t in "${threads[@]}"; do

echo "Random Write bs=4k t${t} qd${rnd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t${t}_qd${rnd_wr_qd}_bs4k  --filename=/dev/$SASDRIVE --output=${result_dir}-randwrite-bs4k-threads${t}-depth${rnd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randwrite_${ioeng}_t${t}_qd${rnd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}_randwrite-bs4k-threads${t}-depth${rnd_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Random Mixed 70% Read 30% Write bs=4k t${t} qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}-randmixedread70write30_-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread70write30_${ioeng}_t${t}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}_randmixedread70write30-bs4k-threads${t}-depth${mix_rnd_rd_wr_qd}
date

done

for t in "${threads[@]}"; do

echo "Random Read bs=4k t${t} qd${rnd_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t${t}_qd${rnd_rd_qd}_bs4k  --filename=/dev/$SASDRIVE --output=${result_dir}-randread-bs4k-threads${t}-depth${rnd_rd_qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${t} --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randread_${ioeng}_t${t}_qd${rnd_rd_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}_randread-bs4k-threads${t}-depth${rnd_rd_qd}
date

done

cd ..

for file in ${run_output_dir}/*
do
  cat "$file" >> output.csv
done 

mv output.csv ${run_output_dir}/output.csv


echo "Results are in $result_dir"

#sudo python3 database_insert.py fio $result_dir
#sudo python3 excel_creator.py $result_dir

exit
