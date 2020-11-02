#!/bin/bash
#Usage: ./fourcornersFIO-sas_edited.sh

read -p "Which drive should benchmark use? Existing data will be lost! [default 'sdd']: " SASDRIVE
SASDRIVE=${SASDRIVE:-'sdd'}
echo "Benchmark Drive: $SASDRIVE"

testpath=/dev/${SASDRIVE}
echo $testpath

vendor=`smartctl -i /dev/$SASDRIVE | awk '$1=="Vendor:" {print $2}'`
product=`smartctl -i /dev/$SASDRIVE | awk '$1=="Product:" {print $2}'`
product=`echo ${product/\//-}`
fw_rev=`smartctl -i /dev/$SASDRIVE | awk '$1=="Revision:" {print $2}'`

#bs
#block_size=(512b 1k 2k 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m)
block_size=(4k 128k)

#iodepths
seq_rd_qd=16
seq_wr_qd=16
rnd_rd_qd=128
rnd_wr_qd=16
mix_rnd_rd_wr_qd=16

#numjobs
threads=1

#ioengine
ioeng="libaio"

echo "Vendor: ${vendor}"
echo "Product: ${product}"
echo "Firmware Revision: ${fw_rev}"
echo "Block Sizes: ${block_size[*]}"
echo "Sequential Read Queue Depth: ${seq_rd_qd}"
echo "Sequential Write Queue Depth: ${seq_wr_qd}"
echo "Random Read Queue Depth: ${rnd_rd_qd}"
echo "Random Write Queue Depth: ${rnd_wr_qd}"
echo "Mixed Random 70 Read 30 Write Queue Depth: ${mix_rnd_rd_wr_qd}"
echo "Threads: ${threads}"

date=$(date '+%Y%m%d')
timestamp=$(date '+%H%M%S')
result_dir="${vendor}_${product}_${fw_rev}_${date}_${timestamp}"

if [ -d ${result_dir} ]
then
    echo "Directory ${result_dir} exists." 
    exit 0
else
    mkdir ${result_dir}
fi

cd ${result_dir}



echo "workload independent preconditioning started at"
date
echo "workload:fio --direct=1 --rw=write --bs=128k --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128 --group_reporting --filename=/dev/$SASDRIVE --output-format=terse --loops=2"
/usr/local/bin/fio --direct=1 --rw=write --bs=128k --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs128K_qd128 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=2

echo "workload:fio --direct=1 --rw=write --bs=4k --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs4K_qd128 --group_reporting --filename=/dev/$SASDRIVE --output-format=terse --loops=2"
/usr/local/bin/fio --direct=1 --rw=write --bs=4k --iodepth=128 --ioengine=${ioeng} --numjobs=1 --norandommap=1 --randrepeat=0 --name=Seq_precondition_bs4K_qd128 --group_reporting --filename=/dev/$SASDRIVE  --output-format=terse --loops=2

echo "workload independent preconditioning done at"
date




#for i in "${block_size[@]}"; do

echo "Sequential Read  bs=128k t${threads} qd${seq_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=seq_read_${ioeng}_t${threads}_qd${seq_rd_qd}_bs128k  --filename=/dev/$SASDRIVE --output=${result_dir}-seq_read-bs128k-threads${threads}-depth${seq_rd_qd}"
/usr/local/bin/fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=read --bs=128k --iodepth=${seq_rd_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=seq_read_${ioeng}_t${threads}_qd${seq_rd_qd}_bs128k --filename=/dev/$SASDRIVE --output=${result_dir}-seq_read-bs128k-threads${threads}-depth${seq_rd_qd}
date

echo "Sequential Write bs=128k t${threads} qd${seq_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=seq_write_${ioeng}_t${threads}_qd${seq_wr_qd}_bs128k  --filename=/dev/$SASDRIVE --output=${result_dir}-seq_write-bs128k-threads${threads}-depth${seq_wr_qd}"
/usr/local/bin/fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=write --bs=128k --iodepth=${seq_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=seq_write_${ioeng}_t${threads}_qd${seq_wr_qd}_bs$128k --filename=/dev/$SASDRIVE --output=${result_dir}-seq_write-bs128k-threads${threads}-depth${seq_wr_qd}
date

echo "Random Read bs=4k t${threads} qd${rnd_rd_qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_read_${ioeng}_t${threads}_qd${rnd_rd_qd}_bs4k  --filename=/dev/$SASDRIVE --output=${result_dir}-rand_read-bs4k-threads${threads}-depth${rnd_rd_qd}"
/usr/local/bin/fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randread --bs=4k --iodepth=${rnd_rd_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_read_${ioeng}_t${threads}_qd${rnd_rd_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}-rand_read-bs4k-threads${threads}-depth${rnd_rd_qd}
date

echo "Random Write bs=4k t${threads} qd${rnd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_write_${ioeng}_t${threads}_qd${rnd_wr_qd}_bs4k  --filename=/dev/$SASDRIVE --output=${result_dir}-rand_write-bs4k-threads${threads}-depth${rnd_wr_qd}"
/usr/local/bin/fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randwrite --bs=4k --iodepth=${rnd_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_write_${ioeng}_t${threads}_qd${rnd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}-rand_write-bs4k-threads${threads}-depth${rnd_wr_qd}
date

echo "Random Mixed 70% Read 30% Write bs=4k t${threads} qd${mix_rnd_rd_wr_qd}"
date
echo "fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_mixed_read70_write30_${ioeng}_t${threads}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}-rand_mixed_read70_write30_-bs4k-threads${threads}-depth${mix_rnd_rd_wr_qd}"
/usr/local/bin/fio --time_based --runtime=300 --output-format=terse --direct=1 --buffered=0 --rw=randrw --rwmixread=70 --rwmixwrite=30 --bs=4k --iodepth=${mix_rnd_rd_wr_qd} --ioengine=${ioeng} --numjobs=${threads} --norandommap=1 --randrepeat=0 --group_reporting --name=rand_mixed_read70_write30_${ioeng}_t${threads}_qd${mix_rnd_rd_wr_qd}_bs4k --filename=/dev/$SASDRIVE --output=${result_dir}-rand_mixed_read70_write30_-bs4k-threads${threads}-depth${mix_rnd_rd_wr_qd}
date

#done

cd .. 

for file in ${result_dir}/*
do
  cat "$file" >> output.csv

done 

mv output.csv ${result_dir}/output.csv

sudo python3 database_insert.py fio ${result_dir}
