function [SPK] = WC32SPK(handles)

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
tank=handles.foldername;
%check tank input
if ischar(tank) == 0            %check if tank is a string
    error('Wrong input argument: Second input parameter has to be a string specifying a folder.')
end

if isdir(tank) == 0             %check if tank is a folder
    error('Wrong input argument: Second input parameter has to be an existing folder.');
end


%############################ SAVE AS SPK ##############################
content = dir(tank);                                                        %list all files folders in "tank"
filesep_positions=strfind(tank,filesep);
block=tank(filesep_positions(end-1)+4:end-1);
numfiles=length(content);

%% modify this part to match with the folder structure
idx=1;
for ff=1:numfiles                                                          % scan file names
    tempname=content(ff,1).name;
    charpos=strfind(tempname,'_');
    if any(strfind(tempname,'mat')) && ~isempty(charpos)
    
      channels(idx)=str2double(tempname(charpos(1)+3:charpos(1)+5));                   % save the number of each channel folder
      idx=idx+1;
    end
end

channels=unique(channels(~isnan(channels)));                                                   % sort the channel numbers in ascending order
SPK=struct('spiketimes',{[]},'sortID',{[]},'channelID',{[]},'waveforms',{[]});
for ii = 1:length(channels)
    ch=channels(ii);
    display(['Scanning folder "Channel' num2str(ch) '".'])                 % display what channel is processed at the movement
    
    switch handles.threshold
        case 'pos', filenames={[tank '\dataspikes_ch' sprintf('%03d',ch) '_onethr.mat' ]};
        case 'neg',  filenames={[tank '\dataspikes_ch' sprintf('%03d',ch) '_onethr.mat' ]};
        case 'both', filenames={[tank '\dataspikes_ch' sprintf('%03d',ch) '_negthr.mat' ],[tank '\dataspikes_ch' sprintf('%03d',ch) '_posthr.mat' ]};
    end
    
    %load([tank '\times_' block '_' num2str(ch) '.mat'],'cluster_class','spikes', 'par')               % load sort ids and spike times from WaveClus file
    %load([tank '\dataspikes_ch' sprintf('%03d',ch) '_negthr.mat' ],'index','spikes')               % load sort ids and spike times from WaveClus file
    
    
    spkt=SPK.spiketimes;
    sortid=SPK.sortID;
    channelid=SPK.channelID;
    wf=SPK.waveforms;
    maxsortid=0;
    for f=1:numel(filenames) % important for case of both thresholds...!
    load(filenames{f},'cluster_class','index','spikes')               % load sort ids and spike times from WaveClus file
    
    % spike times
    spkt=[spkt; single(index/1000)];
    SPK.spiketimes=spkt;
         
    % sort ID
    sortid=[sortid; int8(cluster_class(:,1))+maxsortid];
    SPK.sortID=sortid;
    
    % channel ID
    len = length(index);
    channelid=[channelid; uint16(ch*ones(len,1))];
    SPK.channelID=channelid;
    
    % waveforms
    wf=[wf; single(spikes)];
    SPK.waveforms=wf;
    
    maxsortid=numel(unique(cluster_class(:,1))); %% works, because only maximum two iterations...
%% don't know where they get the info variable from    

%     load([tank '\Channel' num2str(ch) '\Ch' ...
%           num2str(ch) '_spikes.mat'],'info');
%     % threshold
%     th=SPK.threshold;
%     th{1,ch}=info.par.thr;
%     SPK.threshold=th;
%     
%     % pretrigger
%     pretrig=SPK.pretrigger;
%     pretrig{1,ch}=info.par.w_pre;
%     SPK.pretrigger=pretrig;
% 
%     % posttrigger
%     posttrig=SPK.posttrigger;
%     posttrig{1,ch}=info.par.w_post;
%     SPK.posttrigger=posttrig;
%     
%     % noiselevel
%     nl=SPK.noiselevel;
%     nl{1,ch}=info.par.noisestd;
%     SPK.noiselevel=nl;
    end
end

SPK.samplingrate=handles.par.sr;
SPK.physicalunit='µV';

%############################ Create Neuronobj ############################

t = toc(c);
display(['Creation of SPK took ' num2str(t) ' sec, which is ' num2str(t/60) ' min.'])
display(['SPK was extracted sucessfully.']);
