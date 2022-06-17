#!/bin/bash

. ./cmd.sh
. ./path.sh

. parse_options.sh


if [ $# -ne 2 ]; then
    echo "Usage: $0 <wav.scp> <out_dir>"
    exit 0
fi

wavscp=$1
wavscp_fn=`basename $wavscp`
outdir=$(pwd)/$2/wav
rm -rf $outdir/../wav.scp

mkdir -p $outdir

total=`wc -l $wavscp | cut -f 1 -d " "`
count=0
while read line; do
(
    ### get outwav name
    basename=`echo $line | cut -f 1 -d " "`
    outwav="${outdir}/$basename.wav"

    if [ -f $outwav ]; then
        continue
    fi

    pipe=`echo $line | awk -F " " '{print $NF}'`
    speed=`echo $line | rev | cut -f3 -d" " | rev`

    ### check if command exists pipeline

    ### process speed
    if [ "$speed" == "speed" ]; then
        temp=`echo $line | cut -f 2- -d " " | rev | cut -f 5- -d " "| rev`
        temp2=`echo $line | rev | cut -f2,3 -d" " | rev`
        command="$temp $outwav $temp2"
    elif [ "$pipe" == "|" ]; then
        ### get command
        ### rev | cut | rev (cut from the right-most side), remove wav.scp : - | ,and replace with its ID
        temp=`echo $line | cut -f 2- -d " " | rev | cut -f 3- -d " "| rev`
        command="$temp $outwav"
    ### process clean
    else
        temp=`echo $line | cut -f 2- -d " "`
        #command="cp -s $temp $outwav"
        command="cp $temp $outwav"
    fi

    ### run command background, not shown on screen
    eval $command 2>/dev/null
    echo "$basename $outwav" >> $outdir/../$wavscp_fn
    #printf "[%5s/%-5s] %5s\n" $count $total $basename.wav
)
let count++
#[ $[count%100] == 0 ] && echo "Sleep..."
done < $wavscp
