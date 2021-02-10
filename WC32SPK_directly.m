function [SPK] = WC32SPK_directly(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               TAKES WAVE_CLUS-FILES AND CREATES A SPKOBJ
%
%DESCRIPTION: This routine takes the the waveClus-files of all channels in
% 'tank' and stores them in a spkobj and neuronobj.
%
%HELPFUL INFORMATION:
%
%SYNTAX: SPK = WC32SPK_concatenated(handles)
%            handles should be defined before in DAG_create_PLX
%
%
%AUTHOR: ©Katharina Menz, German Primate Center                     Aug2011
%last modified: Lukas Schneider                                  12.03.2020
%               Katharina Menz                                   22.08.2011
%               Stefan Schaffelhofer                             20.09.2011
%               Stefan Schaffelhofer                             12.12.2011
%               Lukas
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

channels=handles.channels_to_process;         % sort the channel numbers in ascending order
sr=handles.sr;
SPK=struct('spiketimes',{[]},'sortID',{[]},'channelID',{[]},'waveforms',{[]});
SPK.int_factor = 1;
for ii = 1:length(channels)
    ch=channels(ii);
    display(['Scanning "Channel' num2str(ch) '".'])                 % display what channel is processed at the movement
    if isempty(handles.wheretofindwhat{handles.block})
        continue
    end
    fileN=[handles.concatenation_folder 'dataspikes_ch' sprintf('%03d',ch) '_' num2str(handles.wheretofindwhat{handles.block}{ch})];
    
    spkt=SPK.spiketimes;
    sortid=SPK.sortID;
    channelid=SPK.channelID;
    wf=SPK.waveforms;
    
    load(fileN,'cluster_class','index','spikes','par')               % load sort ids and spike times from WaveClus file
    
    SPK.int_factor = par.int_factor;
    
    %% reduce to only current block times
    blocksamples=handles.blocksamplesperchannel{ch}(handles.block,:);
    idx=index*sr/1000>=blocksamples(1) & index*sr/1000<=blocksamples(2); %% index at this point is in milliseconds....???
    index=index(idx)-blocksamples(1)*1000/sr;
    cluster_class=cluster_class(idx,:);
    spikes=spikes(idx,:);
    
    % spike times
    spkt=[spkt; single(index/1000)];
    SPK.spiketimes=spkt;
    
    % sort ID
    if ~isempty(cluster_class)
        sortid=[sortid; int8(cluster_class(:,1))];
    end
    SPK.sortID=sortid;
    
    % channel ID
    len = length(index);
    channelid=[channelid; uint16(ch*ones(len,1))];
    SPK.channelID=channelid;
    
    % waveforms
    wf=[wf; single(spikes)];
    SPK.waveforms=wf;
    %
    %         if ~isempty(cluster_class)
    %             maxsortid=max(cluster_class(:,1))+1; %% works, because only maximum two iterations...
    %         end
end
SPK.samplingrate=sr;
SPK.physicalunit='µV';

display('SPK was extracted sucessfully.');
