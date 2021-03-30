#!/bin/bash
#Usage: ./Expanded_SAS_FIO.sh

#read -p "Which drive should benchmark use? Existing data will be lost! [default 'sde']: " SASDRIVE
#SASDRIVE=${SASDRIVE:-'sde'}

SASDRIVE=$1
echo "Benchmark Drive: $SASDRIVE"

testpath=/dev/$SASDRIVE
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
rand_output_dir="Random"
seq_output_dir="Sequential"

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

mkdir ${rand_output_dir}
mkdir ${seq_output_dir}

#ioengine
ioeng="libaio"

#run type
run_type="terse"

#bs
rnd_block_size=(4k 8k 16k 32k 64k 128k 512k 1024k)
seq_block_size=(128k 512k 1024k)

#numjobs
rnd_qd=(1 8 16 32 64 128 256)
seq_qd=(1)

#percentile_list
perc_list="99:99.9:99.99:99.999:99.9999:100"

#read write percentages
rd_wr_perc=(0 30 50 70 100)

cd ${rand_output_dir}

# RANDOM BS WORKLOAD ONLY
for bs in "${rnd_block_size[@]}"; do

mkdir ${bs}
cd ${bs}

echo "Random preconditioning for bs=${bs} started at"
date
echo "workload:fio --direct=1 --rw=randwrite  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=randwrite  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Ran_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3
echo "workload independent preconditioning done at"
date

for perc in "${rd_wr_perc[@]}"; do 

rd_perc=${perc}
wr_perc="$((100-${rd_perc}))"

for qd in "${rnd_qd[@]}"; do

if [ ${qd} -eq 1 ]
then
    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t1 qd${qd}"
    date
    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads1-depth${qd}"
    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}_randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads1-depth${qd}
    date
else
    echo "Random Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t8 qd${qd}"
    date
    echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t8_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}-randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads8-depth${qd}"
    fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=randrw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=8 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=randmixedread${rd_perc}write${wr_perc}_${ioeng}_t8_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}_randmixedread${rd_perc}write${wr_perc}-bs${bs}-threads8-depth${qd}
    date

fi

done 

done

cd ..

done

cd .. 

cd ${seq_output_dir}

# SEQUENTIAL BS WORKLOAD ONLY
for bs in "${seq_block_size[@]}"; do

mkdir ${bs}
cd ${bs}

echo "Sequential preconditioning for bs=${bs} started at"
date
echo "workload:fio --direct=1 --rw=write  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3"
fio --direct=1 --rw=write  --bs=${bs} --iodepth=256 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs${bs}_qd256_t1 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=3
echo "workload independent preconditioning done at"
date

for perc in "${rd_wr_perc[@]}"; do 

rd_perc=${perc}
wr_perc="$((100-${rd_perc}))"

for qd in "${seq_qd[@]}"; do

echo "Sequential Mixed ${rd_perc}% Read ${wr_perc}% Write bs=${bs} t1 qd${qd}"
date
echo "fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}-seqmixedread${rd_perc}write${wr_perc}_-bs${bs}-threads1-depth${qd}"
fio --time_based --runtime=300 --output-format=${run_type} --direct=1 --buffered=0 --rw=rw --rwmixread=${rd_perc} --rwmixwrite=${wr_perc} --bs=${bs} --iodepth=${qd} --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --group_reporting --percentile_list=${perc_list} --name=seqmixedread${rd_perc}write${wr_perc}_${ioeng}_t1_qd${qd}_bs${bs} --filename=/dev/$SASDRIVE --output=${result_dir}_seqmixedread${rd_perc}write${wr_perc}-bs${bs}-threads1-depth${qd}
date

done

done

cd ..

done

#for file in ${run_output_dir}/*
#do
#  cat "$file" >> output.csv
#done 
#mv output.csv ${run_output_dir}/output.csv


cd ..
cd ..

echo "Results are in $result_dir"

#sudo python3 database_insert.py fio $result_dir

exit
