function [SPK] = WC32SPK_concatenated(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               TAKES WAVE_CLUS-FILES AND CREATES A SPKOBJ
%
%DESCRIPTION: This routine takes the the waveClus-files of all channels in
% 'tank' and stores them in a spkobj and neuronobj.
%
%HELPFUL INFORMATION:
%
%SYNTAX: SPK = wClus2spkobj(spkobj, tank)
%            necessary inputs are marked with *
%            spkobj*    ... SPKOBJ
%            neuronobj* ... NEURONOBJ
%            tank*      ... path string where the channel-folders with the
%                      WaveClus-files are stored
%
%EXAMPLE: [Recording2a_SPK Recording2a_NO] = wClus2spkobj(spkobj,
%                       'Volumes/data/Tanks/Zara/Recording2a/Wave_Clus')
%
%AUTHOR: ©Katharina Menz, German Primate Center                     Aug2011
%last modified: Katharina Menz                                   22.08.2011
%               Stefan Schaffelhofer                             20.09.2011
%               Stefan Schaffelhofer                             12.12.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c = tic;

%######################## CHECK INPUT PARAMETERS ##########################

% %check tank input
% if ischar(tank) == 0            %check if tank is a string
%     error('Wrong input argument: Second input parameter has to be a string specifying a folder.')
% end
%
% if isdir(tank) == 0             %check if tank is a folder
%     error('Wrong input argument: Second input parameter has to be an existing folder.');
% end


%############################ SAVE AS SPK ##############################
% content = dir(tank);                                                        %list all files folders in "tank"
% filesep_positions=strfind(tank,filesep);
% block=tank(filesep_positions(end-1)+4:end-1);
% numfiles=length(content);


channels=handles.channels;                                                   % sort the channel numbers in ascending order
SPK=struct('spiketimes',{[]},'sortID',{[]},'channelID',{[]},'waveforms',{[]});
for ii = 1:length(channels)
    ch=channels(ii);
    display(['Scanning "Channel' num2str(ch) '".'])                 % display what channel is processed at the movement
    
    fileN=handles.wheretofindwhat{handles.block}{ch};
    
    switch handles.threshold
        case 'pos',     filenames={[handles.WC_concatenation_folder 'dataspikes_ch' sprintf('%03d',ch) '_' num2str(fileN) '_onethr.mat' ]};
        case 'neg',     filenames={[handles.WC_concatenation_folder 'dataspikes_ch' sprintf('%03d',ch) '_' num2str(fileN) '_onethr.mat' ]};
        case 'both',    filenames={[handles.WC_concatenation_folder 'dataspikes_ch' sprintf('%03d',ch) '_' num2str(fileN) '_negthr.mat' ],...
                [handles.WC_concatenation_folder 'dataspikes_ch' sprintf('%03d',ch) '_' num2str(fileN) '_posthr.mat' ]};
    end
    
    spkt=SPK.spiketimes;
    sortid=SPK.sortID;
    channelid=SPK.channelID;
    wf=SPK.waveforms;
    maxsortid=0;
    
    for f=1:numel(filenames) % important for case of both thresholds...!
        load(filenames{f},'cluster_class','index','spikes')               % load sort ids and spike times from WaveClus file
        
        %% reduce to only current block times
        blocksamples=handles.blocksamplesperchannel{ch}(handles.block,:);
        idx=index*handles.sr/1000>=blocksamples(1) & index*handles.sr/1000<=blocksamples(2); %% index at this point is in milliseconds....???
        index=index(idx)-blocksamples(1)*1000/handles.sr;
        cluster_class=cluster_class(idx,:);
        spikes=spikes(idx,:);
        
        % spike times
        spkt=[spkt; single(index/1000)];
        SPK.spiketimes=spkt;
        
        % sort ID
        if ~isempty(cluster_class)
            
            
        sortid=[sortid; int8(cluster_class(:,1))+maxsortid];
        end
        SPK.sortID=sortid;
        
        % channel ID
        len = length(index);
        channelid=[channelid; uint16(ch*ones(len,1))];
        SPK.channelID=channelid;
        
        % waveforms
        wf=[wf; single(spikes)];
        SPK.waveforms=wf;
        
        if ~isempty(cluster_class)
        maxsortid=max(cluster_class(:,1))+1; %% works, because only maximum two iterations...
        end
    end
end

SPK.samplingrate=handles.par.sr;
SPK.physicalunit='µV';

%############################ Create Neuronobj ############################

t = toc(c);
display(['Creation of SPK took ' num2str(t) ' sec, which is ' num2str(t/60) ' min.'])
display(['SPK was extracted sucessfully.']);
