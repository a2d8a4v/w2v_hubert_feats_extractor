#!/bin/bash

nj=20
cmd=queue.pl

. ./cmd.sh
. ./path.sh
. parse_options.sh

if [ $# -ne 2 ];then
    echo "Using: $0 <data> <outdir>"
    echo "It takes <data>/wav.scp, then generates wav to <outdir>"
    echo "egs. $0 --cmd queue.pl --nj 20 data/train data/train_wav"
    exit 0
fi
#echo $nj
#echo $cmd

data=$1
wdir=$2

logdir=$data/log
name=`basename $data`

echo "$0 $@"
mkdir -p $logdir

utils/copy_data_dir.sh $data $wdir
mkdir -p $wdir/wav

# split the list for parallel processing
split_wavfiles=""
for n in `seq $nj`; do
    split_wavfiles="$split_wavfiles $logdir/wav.${name}.$n.scp"
done

utils/split_scp.pl $data/wav.scp $split_wavfiles || exit 1;
rm $logdir/.error 2>/dev/null

echo "Parallel processing wav.scp to $wdir ..... "
$cmd JOB=1:$nj $logdir/make_wav_${name}.JOB.log \
  local/make_wav.sh $logdir/wav.${name}.JOB.scp $wdir || exit 1

rm $logdir/wav.${name}.*.scp
cat $wdir/wav.${name}.*.scp > $wdir/wav.scp
sort -k1,1 $wdir/wav.scp > $wdir/wav.scp.tmp; mv $wdir/wav.scp.tmp $wdir/wav.scp
rm -rf $wdir/wav.${name}.*.scp

echo "Done generate wav to $wdir"
