#!/bin/bash


#. ./path.sh || exit 1;
#. ./cmd.sh || exit 1;

ori_data_root="data"
data_root="data/hubert_18_lt"
datasets="train_tr_18_lt train_cv_18_lt test_18_lt"

new_feats_dir="exp/hubert_18_lt"
exp_affix="hubert_18_lt"
# https://huggingface.co/facebook
pretrained_model="facebook/hubert-large-ls960-ft"
stage=0

. utils/parse_options.sh || exit 1;

set -euo pipefail

if [ ! -d $data_root ]; then
    mkdir -p $data_root
fi

if [ ! -d $new_feats_dir ]; then
    mkdir -p $new_feats_dir
fi

if [ $stage -le 0 ]; then
    for dataset in $datasets; do
        datadir=$ori_data_root/${dataset}
        outdir=$data_root/${dataset}_wav
        
        if [ ! -d $outdir ]; then
            # utils/copy_data_dir.sh $datadir $outdir
            local/generate_wav.sh $datadir $outdir
        else
            continue
        fi
    done
fi


if [ $stage -le 1 ]; then
    
    for dataset in $datasets; do
        outdir=$data_root/${dataset}_wav
        hubert_outdir=$data_root/${dataset}_${exp_affix}
        python local/hubert_inference.py --data_dir $outdir --new_feats_dir $new_feats_dir --pretrained_model $pretrained_model --exp_affix $exp_affix
        
        dataset=`basename $outdir`
        cat $new_feats_dir/raw_hubert_${exp_affix}_*${dataset}*.scp > $outdir/feats.scp
        cat $outdir/feats.scp | sort > $outdir/feats.scp.tmp; mv $outdir/feats.scp.tmp $outdir/feats.scp
        utils/copy_data_dir.sh $outdir $hubert_outdir
    done
fi

#conda deactivate
exit

if [ $stage -le 2 ]; then
     
    for dataset in $datasets; do
        ori_outdir=$data_root/${dataset}_wav
        w2v_outdir=$data_root/${dataset}_${exp_affix}
        outdir=$data_root/${dataset}_d${exp_affix}
        
        utils/copy_data_dir.sh ${w2v_outdir} ${outdir}
        python local/expand_wav2vec2.py --data_dir $outdir
        
        dataset=`basename $ori_outdir`
        cat $new_feats_dir/expand_raw_wav2vec2_*${dataset}*.scp > $outdir/feats.scp
    done
fi

conda deactivate; conda deactivate

sed -i "s/ sil//g" $data_root/*/text
