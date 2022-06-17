import soundfile as sf
import torch
from transformers import Wav2Vec2Processor, HubertModel
import kaldiio
from kaldiio import WriteHelper
from tqdm import tqdm
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--data_dir', type=str, default='data/train')
parser.add_argument('--new_feats_dir', type=str, default='hubert')
parser.add_argument('--pretrained_model', type=str, default='facebook/hubert-large-ls960-ft')
parser.add_argument('--exp_affix', type=str, default='hubert')
args = parser.parse_args()

wavscp = {}
feats_scps = set()
d = os.path.basename(args.data_dir)

with open(args.data_dir + "/wav.scp", "r") as fn:
    for line in fn.readlines():
        utt_id, wav_path = line.split()
        wavscp[utt_id] = wav_path

# read feats.scp
with open(args.data_dir + "/feats.scp", "r") as fn:
    for line in fn.readlines():
        info = line.split()
        utt_id = info[0]
        scp_info = info[1].split(":")[0].replace(".ark", ".scp")
        feats_scps.add(scp_info)       

# load pretrained model
processor = Wav2Vec2Processor.from_pretrained(args.pretrained_model)


device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
#device = torch.device("cpu")
model = HubertModel.from_pretrained(args.pretrained_model).to(device)

for feats_scp in tqdm(feats_scps):
    feat_reader = kaldiio.load_scp(feats_scp)
    split_idx = os.path.basename(feats_scp).split(".")[1]
    new_feats_scp_name = args.new_feats_dir + "/raw_hubert_" + args.exp_affix + "_" + d + "." + str(split_idx)
    new_feats_scp = {}
    
    #try:
    #    done_feat_reader = kaldiio.load_scp('{0}.scp'.format(new_feats_scp_name))
    #
    #except:
    #    done_feat_reader = {}
    
    for utt_id, v in feat_reader.items():
        # skip if the feats. have already been computed.
        #if utt_id in done_feat_reader:
        #    new_feats_scp[utt_id] = done_feat_reader[utt_id]
        #    continue
        
        wav_path = wavscp[utt_id]
        
        # load audio
        try:
            audio_input, sample_rate = sf.read(wav_path)
        except:
            continue
        # pad input values and return pt tensor
        wav2vec_values_pt = processor(audio_input, sampling_rate=sample_rate, return_tensors="pt").input_values
        wav2vec_values_pt = wav2vec_values_pt.to(device)
        with torch.no_grad():
            hubert_values_np = model(wav2vec_values_pt).last_hidden_state.detach().cpu().numpy()[0]
            new_feats_scp[utt_id] = hubert_values_np
    
    with WriteHelper('ark,scp:{0}.ark,{0}.scp'.format(new_feats_scp_name)) as writer:
        for k, v in new_feats_scp.items():
            writer(k, v)


