#!/bin/bash


#. ./path.sh || exit 1;
#. ./cmd.sh || exit 1;

ori_data_root="data"
datasets="train_tr train_cv test"
age="18"

stage=0

# if ! [[ $age =~ '^([0-9])+$' ]] ; then
#    echo "error: Not a number" >&2; exit 1
# fi

. utils/parse_options.sh || exit 1;

set -euo pipefail

# if [ $stage -le 0 ]; then
#     for dataset in $datasets; do
#         datadir=${ori_data_root}/${dataset}

#     done
# fi

if [ $stage -le 1 ]; then
    for dataset in $datasets; do
        datadir=${ori_data_root}/${dataset}
        outdir_be=${ori_data_root}/${dataset}_${age}_be
        outdir_lt=${ori_data_root}/${dataset}_${age}_lt

        echo " - cut data bigger or equal than $age"
        awk -v var="$age" -F'\t' '$2>=var' ${datadir}/spk2age | cut -f1 -d$'\t' > ${datadir}/spk2id.list.be
        ./utils/subset_data_dir.sh --spk-list ${datadir}/spk2id.list.be ${datadir} ${outdir_be}
        ./utils/fix_data_dir.sh ${outdir_be}
        rm ${datadir}/spk2id.list.be -R

        echo " - cut data less than $age"
        awk -v var="$age" -F'\t' '$2<var' ${datadir}/spk2age | cut -f1 -d$'\t' > ${datadir}/spk2id.list.lt
        ./utils/subset_data_dir.sh --spk-list ${datadir}/spk2id.list.lt ${datadir} ${outdir_lt}
        ./utils/fix_data_dir.sh ${outdir_lt}
        rm ${datadir}/spk2id.list.lt -R
    done
fi

