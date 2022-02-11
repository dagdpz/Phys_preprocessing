function DAG_take_over_sortcode_PLX2PLX(other_channels_PLX_file,specific_channel_PLX_file,channel)
% This function was created to take over good waveforms from unsorted PLX files
% to already existing sorted PLX files with waveform resolution bug

if ~exist(other_channels_PLX_file,'file') || ~exist(specific_channel_PLX_file,'file')
    disp([other_channels_PLX_file ' or ' specific_channel_PLX_file 'not found']);
    return;
else
    disp(['replacing sortcodes for channel ' num2str(channel) ' in ' other_channels_PLX_file  ' with ' specific_channel_PLX_file ]);
end

spiketimes=[];
sortID=[];
channelID=[];
waveforms=[];
SPKa=PLX2SPK(other_channels_PLX_file);
SPKs=PLX2SPK(specific_channel_PLX_file);
for c=unique(SPKa.channelID)'
    if c==channel
        SPK = SPKs;
    else
        SPK = SPKa;
    end
    idx         = SPK.channelID==c;
    t           = SPK.spiketimes(idx);
    sortID_temp = SPK.sortID(idx);
    wave        = SPK.waveforms(idx,:);
    [t idx]     = sort(t); % sort the times of a channel and save order
    spiketimes  = [spiketimes; t];
    wave        = wave(idx,:); % sort the waveforms by this
    sortID_temp = sortID_temp(idx);
    sortID      = [sortID; sortID_temp];
    channelID   = [channelID; ones(numel(t),1) * c];
    waveforms   = [waveforms; wave];
end

SPK.waveforms=waveforms/1000;
SPK.sortID   =sortID;
SPK.channelID=channelID;
SPK.spiketimes=spiketimes;
SPK.samplingrate=24414.0625;
SPK.int_factor=1;

SPK2PLX(SPK,other_channels_PLX_file);
end