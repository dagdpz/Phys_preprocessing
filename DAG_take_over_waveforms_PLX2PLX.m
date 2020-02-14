function DAG_take_over_waveforms_PLX2PLX(waveform_PLX_file,sortcode_PLX_file)
% This function was created to take over good waveforms from unsorted PLX files
% to already existing sorted PLX files with waveform resolution bug

if ~exist(waveform_PLX_file,'file') || ~exist(sortcode_PLX_file,'file')
    disp([waveform_PLX_file ' or ' sortcode_PLX_file 'not found']);
    return;
else
    disp(['replacing waveforms in ' sortcode_PLX_file ' with ' waveform_PLX_file]);
end

waveforms=[];
SPK=PLX2SPK(waveform_PLX_file);
for c=unique(SPK.channelID)'
    idx=SPK.channelID==c;
    wave   = SPK.waveforms(idx,:);
    t      = SPK.spiketimes(idx);
    [~, idx]=sort(t); % sort the times of a channel and save order
    wave   = wave(idx,:); % sort the waveforms by this
    waveforms=[waveforms; wave];
end

spiketimes=[];
sortID=[];
channelID=[];
SPK=PLX2SPK(sortcode_PLX_file);
for c=unique(SPK.channelID)'
    idx=SPK.channelID==c;
    sortID_temp = SPK.sortID(idx);
    t           = SPK.spiketimes(idx);
    [t idx]=sort(t); % sort the times of a channel and save order
    sortID_temp=sortID_temp(idx);
    spiketimes=[spiketimes; t];
    sortID=[sortID; sortID_temp];
    channelID=[channelID; ones(numel(t),1) * c];
end

SPK.waveforms=waveforms/1000;
SPK.sortID   =sortID;
SPK.channelID=channelID;
SPK.spiketimes=spiketimes;
SPK.samplingrate=24414.0625;
SPK.int_factor=2;


SPK2PLX(SPK,sortcode_PLX_file);

end