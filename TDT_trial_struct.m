function TDT_trial_struct(handles,date_str,block,spike_settings,varargin)
% TDT_trial_struct_working('L:\Data\','Linus_phys','20150520','block-1')
% Last modified: 20170531: Added Broadband filtering and did some major
% restructuring for stream_state_info separation
% Last modified: 20170515: Fixed bug in chopping streamed data into trials
% (was using the same sample for end of this as well as for beginning of
% next trial)
% Danial Arabali & Lukas Schneider

drive=handles.drive;
monkey=handles.monkey_phys;
data_path                   = [drive 'Data' filesep]; 

%% crate folders
plxfilefolder                   = [data_path 'Sortcodes' filesep monkey filesep date_str filesep];
TDTblockfolder                  = [data_path 'TDTtanks' filesep monkey filesep date_str filesep block];
matfromTDT_folder               = strcat([data_path monkey '_mat_from_TDT']);
temp_raw_folder                 = strcat([matfromTDT_folder filesep date_str]);
DBpath                          = DAG_get_Dropbox_path;
DBfolder                        = [DBpath filesep 'DAG' filesep 'phys' filesep monkey '_dpz' filesep];
if exist(matfromTDT_folder,'dir')~=7
    mkdir(matfromTDT_folder)
end
if exist(temp_raw_folder,'dir')~=7
    mkdir(temp_raw_folder)
end

%% to check if epoch stores are computed correctly in TDT, there is still the possibility of using the streamed state data (not sure if it works correctly though):
stream_state_info=0; % 1: using the stat stream data, 0: using only epoch stores (faster !!)
% here we can derive the key for which plx-file to use
PLXVERSION='';
PLXEXTENSION='-01';
DISREGARDLFP=0;
DISREGARDSPIKES=0;
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
    eval(['preprocessing_settings.(upper(varargin{i}))' '=varargin{i+1};']);
end

%% read in info only first, so we can load channel by channel (of broadband/LFP) later on
datainfo             =TDTbin2mat_working(TDTblockfolder, varargin{:}, 'HEADERS',1);

%% varargin for reading in spikes only (disregarding broadband)
varargin_wo_broadband=varargin;
for i = 1:2:length(varargin_wo_broadband)
    if strcmpi(varargin{i},'DONTREAD')
        varargin_wo_broadband{i+1}=[varargin_wo_broadband{i+1}, 'BROA','Broa'];
        if DISREGARDSPIKES;
            varargin_wo_broadband{i+1}=[varargin_wo_broadband{i+1}, 'eNeu'];
        end
        varargin_wo_broadband{i+1}=unique(varargin_wo_broadband{i+1});
    end
end

%% reading in data without broadband
data             =TDTbin2mat_working(TDTblockfolder, varargin_wo_broadband{:});
clc;
Block_N=block(strfind(block,'-')+1:end);

%% define plx file and preprocesing settings
if strcmp(PLXVERSION,'Snippets')
    plxfile=[plxfilefolder date_str  '_blocks_' Block_N PLXEXTENSION '.plx'];
else
    plxfile=[plxfilefolder date_str '_' PLXVERSION '_blocks_' Block_N PLXEXTENSION '.plx'];
end
if ~DISREGARDSPIKES
    preprocessing_settings.SPK=spike_settings;
    preprocessing_settings.SPK.plxfile=plxfile;
end
if ~DISREGARDLFP
    preprocessing_settings.LFP.notch_filter1    = handles.LFP.notch_filter1;
    preprocessing_settings.LFP.notch_filter2    = handles.LFP.notch_filter2;
    preprocessing_settings.LFP.HP_filter        = handles.LFP.HP_filter;
    preprocessing_settings.LFP.LP_bw_filter     = handles.LFP.LP_bw_filter;
    preprocessing_settings.LFP.LP_median_filter = handles.LFP.LP_median_filter;
    preprocessing_settings.LFP.from             ='Broa';
end

%% overwriting snippets with plx file (in case it exists)
if exist(plxfile,'file')
    SPK=PLX2SPK(plxfile);            % convert the sorted plexon file into spkobj-format; merge the new sorted waveforms with the old SPKOBJ to geht thresholds and noiselevels as well.
    %backscaling (see DAG_create_PLX)
    if strcmp(PLXVERSION,'from_BB')
        load([plxfilefolder 'WC' filesep 'concatenation_info'],'wf_scale');
        scaleperchannel=wf_scale(str2double(Block_N),:);
        for chan=unique(SPK.channelID)'
            idx=SPK.channelID==chan;
            SPK.waveforms(idx,:)=SPK.waveforms(idx,:)*scaleperchannel(chan);
        end
    end
    snipfield=fieldnames(data.snips);
    data.snips.(snipfield{1}).data      =SPK.waveforms;
    data.snips.(snipfield{1}).chan      =SPK.channelID;
    data.snips.(snipfield{1}).sortcode  =SPK.sortID;
    data.snips.(snipfield{1}).ts        =SPK.spiketimes;
    disp([plxfile ' used']);
    
elseif strcmp(PLXVERSION,'none')
    disp('No sorting used');
    % MP try to avoid error when only D/A input
    if isstruct(data.snips) % just remove this line and the end (63) to remove thr MP try
        snipfield=fieldnames(data.snips);
        data.snips.(snipfield{1}).sortcode  =zeros(size(data.snips.(snipfield{1}).sortcode ));
    end
else
    disp('Plexsormanually snippets used');
end

%% Trial information markers sent as stream.stat
stopper_INI_trial   =252; % initial of a trial  (here we send date, run and trial number)
stopper_end_trial   =253; % end of sending trial number information
stopper_no_change   =254; % stopper between each data during tr
stopper_INI_states  =255; % start of sending states
stopper_control     =0;   % before sending states, to control if digital connections are working

%% Extracting Session, Run, Trial, and time oínformation
% Either from stat header or from epocs
if stream_state_info
    trials_start_mark       = [false diff(data.streams.stat.data==stopper_INI_trial)==1];
    find_stopper_INI_trial  = [find(trials_start_mark) numel(trials_start_mark)+1];
    trials_end_mark         = [diff(data.streams.stat.data==stopper_INI_states)==-1 false];
    find_stopper_END_trial  = [find(trials_end_mark) numel(trials_end_mark)];
    
    Runs=NaN(size(find_stopper_INI_trial));Session=Runs;Hour=Runs;Minute=Runs;Second=Runs;Trials=Runs;
    for t=1:numel(find_stopper_INI_trial)
        trial_samples_for_state         = find_stopper_INI_trial(t):find_stopper_END_trial(t);
        DateRunTrial_states             = data.streams.stat.data(trial_samples_for_state);
        DateRunTrial                    = DateRunTrial_states([false diff(DateRunTrial_states==stopper_no_change)==-1]);
        Session(t)      =DateRunTrial(1)*10000 + DateRunTrial(2)*100 + DateRunTrial(3);
        Hour(t)         =DateRunTrial(4);
        Minute(t)       =DateRunTrial(5);
        Second(t)       =DateRunTrial(6);
        Runs(t)         =DateRunTrial(7);
        Trials(t)       =DateRunTrial(8)*10 + DateRunTrial(9);
    end
    
    %% replace stat stream trial information with state 50 (ITI)
    % NOT 1, because we start the trial AFTER trial information is sent
    samples_to_replace      = [];
    for s=1:numel(find_stopper_INI_trial)
        samples_to_replace=[samples_to_replace find_stopper_INI_trial(s):find_stopper_END_trial(s)];
    end
    data.streams.stat.data(samples_to_replace)=single(50);
    
else
    if ~isfield(data.epocs,'Tnum')
        disp('No trials associated to this block')
        return %break
    end
    Trials      =data.epocs.Tnum.data;
    Runs        =data.epocs.RunN.data;
    Session     =data.epocs.Sess.data;
    Hour        =data.epocs.Hour.data;
    Minute      =data.epocs.Minu.data;
    Second      =data.epocs.Scnd.data;
    % strange bug for counters in TDT not being set correctly in the first trial, fixed in TDT (on ??)...
    if numel(Trials)>1
        Trials(1)   =Trials(2)-1;
        Runs(1)     =Runs(2);
        Session(1)  =Session(2);
        Hour(1)     =Hour(2);
        Minute(1)   =Minute(2);
        Second(1)   =Second(2);
    end
    temp_duration   =datevec(datenum(data.info.duration));
    temp_duration   =temp_duration(4)*3600+temp_duration(5)*60+temp_duration(6);
    trialonsets     =[data.epocs.Tnum.onset; temp_duration];
    
    if sum(Trials==1)>1
        disp(['Warning: multiple Runs in one block! Run onsets at TDT trials : ' mat2str(find(Trials==1))]);
    end
    
    % To fix bug in Linus_20150703, block 5, THIS SHOULD NOT HAPPEN!!!!
    % check if this still happens
    if numel(Trials)>1 && Trials(2)==1
        Trials(1)       =[];
        Runs(1)         =[];
        Session(1)      =[];
        Hour(1)         =[];
        Minute(1)       =[];
        Second(1)       =[];
        trialonsets(1)  =[];
        disp(['Additional trial in the beginning of ' block ' removed']);
    end
end

%% Snippet selection
if isstruct(data.snips)
    snippet_fieldnames=fieldnames(data.snips);
    snip_index=ismember(snippet_fieldnames,{'eNeu'});
else
    snip_index=[];
end

%% Stream Selections (for LFP)
stream_fieldnames=fieldnames(datainfo.stores);
BB_index=ismember(stream_fieldnames,{'BROA','Broa'});
LFP_index=ismember(stream_fieldnames,{'LFPx'});
% don't consider broadband if its sampling rate is below 5000 Hz
if ~any(BB_index) || datainfo.stores.(stream_fieldnames{BB_index}).fs<5000
    stream_fieldnames(BB_index)=[];
    BB_index=false(size(stream_fieldnames));
    preprocessing_settings.LFP.from='LFPx';
end

%% load excel lag table if applicable
lag_table_string={'Session','Block','lag_seconds'};
lag_table_num=zeros(size(lag_table_string));
if exist([DBfolder filesep monkey '_LFP_BROA_comp.xls'],'file')
    [lag_table_num,lag_table_string]=xlsread([DBfolder filesep monkey '_LFP_BROA_comp.xls']);
end

%% use Broadband for LFP if available
if any(BB_index)
    BB=stream_fieldnames{BB_index};
    stream_fieldnames{BB_index}='LFPx';
    stream_fieldnames(LFP_index)=[];
    varargin_per_channel={'SORTNAME',SORTNAME,'DISREGARDLFP',DISREGARDLFP,'STREAMSWITHLIMITEDCHANNELS',STREAMSWITHLIMITEDCHANNELS,'EXCLUSIVELYREAD',{BB}};
    
    %% create LFP based on filtering broadband
    samplingrate=datainfo.stores.(BB).fs;           % Hz ?
    SR_factor=round(samplingrate/1010);             % LFP sampling rate should be exactly 1/24th of boradband
    data.streams.LFPx.fs=samplingrate/SR_factor;
    
    %% get lag for current block
    lag=ph_readout_broadband_lag(lag_table_num,lag_table_string,str2double(date_str),Block_N);
    lag_in_samples=round(lag*samplingrate);
    
    %% process broadband per channel
    for channel=unique(datainfo.stores.(BB).chan)
        chandata=TDTbin2mat_working(TDTblockfolder, varargin_per_channel{:},'CHANNEL',channel);
        chandata=chandata.streams.(BB).data;
        %% correct for lag here
        if lag_in_samples>0
            chandata(1:lag_in_samples)=[];
        else
            chandata=[zeros(1,abs(lag_in_samples)) chandata];
        end
        %% filter BB to LFP
        data.streams.LFPx.data(channel,:)=filter_function(chandata,samplingrate,SR_factor,size(data.streams.LFPx.data,2),preprocessing_settings);
    end
    clear chandata
elseif any(LFP_index)
    samplingrate=data.streams.LFPx.fs;
    for channel=1: size(data.streams.LFPx.data,1)
        %% filter LFP 1000 Hz
        data.streams.LFPx.data(channel,:)=filter_function_simple(data.streams.LFPx.data(channel,:),samplingrate,preprocessing_settings);
    end
end

%% separate each trial (the actual trial structure creation)

stream_fieldnames=fieldnames(data.streams);
unique_runs=unique(Runs);           % important to separate Blocks with several runs
tr_block=0;                         % trial index in the block
tr_processed=0;                     % accumulator for keeping track of previous trials in this block
First_trial_INI=struct;             % because this might be not assigned if trial(1) is not 1
for r=1:numel(unique_runs)          % looping through runs
    clear TDT_DATA DATA_TO_APPEND
    runtrials=Trials(Runs==unique_runs(r))'; % Only the trials that corrspond to current run
    Invalidtrials=[];               % keeping track of trials that we want to exclude afterwards (Inconsistency between MP and TDT, FIX_ACQ_start_time empty)
    for tr=runtrials
        tr_block=tr_block+1;
        % check consistency for block and run trial
        if tr+tr_processed~=tr_block+Trials(1)-1
            disp(['Inconsistent block trial ' num2str(tr_block) 'and Monkeypsych trial' num2str(tr) ', run '  num2str(unique_runs(r)) '. skipping trial']);
            Invalidtrials=[Invalidtrials tr];
            continue;
        end
        
        %% Current trial timing
        if stream_state_info
            trial_samples_for_state         =[find_stopper_END_trial(tr_block): find_stopper_END_trial(tr_block+1)-1]; % end of trial info is beginning of fix_acq_state
            trial_time                      =[trial_samples_for_state(1) trial_samples_for_state(end)]./data.streams.stat.fs;
            TDT_DATA.Trial(tr).purestates   = data.streams.stat.data(trial_samples_for_state);
            % finding time of target acquisition in this state
            FIX_ACQ_start_time              =find(TDT_DATA.Trial(tr).purestates==2)./data.streams.stat.fs;
            FIX_ACQ_start_time              =FIX_ACQ_start_time(1);
        else
            trial_time                  =[trialonsets(tr_block) trialonsets(tr_block+1)];
            trial_states_indexes        =data.epocs.SVal.onset>=trial_time(1) & data.epocs.SVal.onset<=trial_time(2);
            TDT_DATA.Trial(tr).states   =data.epocs.SVal.data(trial_states_indexes);
            state_onsets_temp           =data.epocs.SVal.onset(trial_states_indexes);
            FIX_ACQ_start_time          =state_onsets_temp(TDT_DATA.Trial(tr).states==2)-trial_time(1);
        end
        %% only consider trials with fix_acq_state, correct state_onsets
        if isempty(FIX_ACQ_start_time);
            Invalidtrials=[Invalidtrials tr];
            continue;
        elseif ~stream_state_info % why no correction if we use stream_state_info?
            TDT_DATA.Trial(tr).state_onsets=state_onsets_temp-FIX_ACQ_start_time-trial_time(1);
        end
        
        %% Streams
        for current_field=1:numel(stream_fieldnames)
            current_fieldname   =stream_fieldnames{current_field};
            samplingrate        =data.streams.(current_fieldname).fs;
            start_end_samples   =round(trial_time*samplingrate);                                                    % used to cut into trials
            end_sample          =min([start_end_samples(end)-1, size(data.streams.(current_fieldname).data,2)]);    % if last trial is not complete, only take what is there
            for channel=1: size(data.streams.(current_fieldname).data,1)
                TDT_DATA.Trial(tr).(current_fieldname)(channel,:)=data.streams.(current_fieldname).data(channel,start_end_samples(1):end_sample);
            end
            % cutting off INI trial and create new structure to append to
            % previous trial ... WHAT HAPPENS IF TRIAL IS CORRUPTED (Invalid)???
            samples_to_skip=round((FIX_ACQ_start_time-(start_end_samples(1)/samplingrate-trial_time(1)))*samplingrate);
            DATA_TO_APPEND.Trial(tr).(current_fieldname)=TDT_DATA.Trial(tr).(current_fieldname)(:,1:samples_to_skip);   % to append to preivous trial
            TDT_DATA.Trial(tr).(current_fieldname)(:,1:samples_to_skip)=[];
            TDT_DATA.Trial(tr).([current_fieldname '_samplingrate'])=samplingrate;
        end
        
        %% snippets
        if any(snip_index)
            trial_snippet_indexes=data.snips.eNeu.ts>=trial_time(1) & data.snips.eNeu.ts<=trial_time(2); %logical index for snippets belonging to current trial
            unique_channels=unique(data.snips.eNeu.chan);                                                 %this could go to the beginning..?
            for chan=unique_channels'
                channel_idx=data.snips.eNeu.chan==chan;
                unique_sortcodes=unique([data.snips.eNeu.sortcode]);
                for sortcode=1:numel(unique_sortcodes)
                    sortcodeidx=data.snips.eNeu.sortcode==unique_sortcodes(sortcode);
                    if unique_sortcodes(sortcode)==0            %% drop unsorted spikes
                        TDT_DATA.Trial(tr).eNeu_t{chan,sortcode}=[];
                        TDT_DATA.Trial(tr).eNeu_w{chan,sortcode}=[];
                    else                                        %% align fixation acquisition to 0
                        TDT_DATA.Trial(tr).eNeu_t{chan,sortcode-any(unique_sortcodes==0)}=...
                            [data.snips.eNeu.ts(trial_snippet_indexes & channel_idx & sortcodeidx)-trial_time(1)-FIX_ACQ_start_time];
                        TDT_DATA.Trial(tr).eNeu_w{chan,sortcode-any(unique_sortcodes==0)}=...
                            [data.snips.eNeu.data(trial_snippet_indexes & channel_idx & sortcodeidx,:)];
                    end
                end
            end
        end
        TDT_DATA.Trial(tr).time       = [Hour(tr_block) Minute(tr_block) Second(tr_block)];
        TDT_DATA.Trial(tr).run        = Runs(tr_block);
        TDT_DATA.Trial(tr).session    = 20000000+Session(tr_block);
        TDT_DATA.Trial(tr).trial      = tr;
        TDT_DATA.Trial(tr).block      = sprintf('%02d',str2double(block(7:end)));
    end
    
    tr_processed=tr_processed+numel(runtrials);
    runtrials(ismember(runtrials,Invalidtrials))=[];
    if isempty(runtrials)
        continue;
    end
    
    %% Annoying part for adding INI of next trials
    for current_fieldname=1:numel(stream_fieldnames)
        for tr=runtrials(1:end-1)
            TDT_DATA.Trial(tr).(stream_fieldnames{current_fieldname})=[...
                TDT_DATA.Trial(tr).(stream_fieldnames{current_fieldname}) ...
                DATA_TO_APPEND.Trial(tr+1).(stream_fieldnames{current_fieldname})];
        end
        if runtrials(1)==1 %% should always be the case, careful with blocks containing several runs
            First_trial_INI.(stream_fieldnames{current_fieldname})=DATA_TO_APPEND.Trial(1).(stream_fieldnames{current_fieldname});
        end
    end
    
    %% DOUBLECHECK if In case we were using stream_state_info, we have to separate runs, and assign trial numbers at this stage, should work as it is now...
    % This is temp, because we potentially overwrite the file we load!!!
    run=unique([TDT_DATA.Trial.run]);
    clear TDT_trial TDT_trial_temp
    for tr=runtrials
        %% here exclude the ones that didnt have fix_acq....!!!
        TDT_trial_temp(TDT_DATA.Trial(tr).trial) = TDT_DATA.Trial(tr);
    end
    First_trial_INI_temp=First_trial_INI;
    preprocessing_settings_temp=preprocessing_settings;
    
    %% load already existing file (if it exists) and merge structures
    filename=[temp_raw_folder, filesep, monkey(1:3), 'TDT', date_str(1:4), '-', date_str(5:6), '-', date_str(7:8), '_', sprintf('%02d',run) ];
    Validtrials=find(~arrayfun(@(x) isempty(x.trial),TDT_trial_temp));
    if exist([filename '.mat'],'file')
        warning ('off','all');
        load(filename,'TDT_trial','First_trial_INI','preprocessing_settings'); %yes, we load preprocessing_settings as well,
        warning ('on','all'); %suppress warning if something is not present?
        
        %% display message for empty variables
        
        if DISREGARDLFP && isfield(TDT_trial,'LFPx')
            %% take over LFP from the file that was already saved if it's there and we disregarded LFP this time
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial_temp(vt).LFPx=TDT_trial(vt).LFPx;
                TDT_trial_temp(vt).LFPx_samplingrate=TDT_trial(vt).LFPx_samplingrate;
            end
            if isfield(First_trial_INI,'LFPx') %% new bug?? Lin 20151119 probably because it didnt exist from before
                First_trial_INI_temp.LFPx=First_trial_INI.LFPx;
            end
            
        elseif isfield(TDT_trial_temp,'LFPx') && ~isfield(TDT_trial,'LFPx')
            %% this is only here so that structures have the same fieldnames in the end; first trial does not matter here, we either keep it or overwrite it
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial(vt).LFPx=TDT_trial_temp(vt).LFPx;
                TDT_trial(vt).LFPx_samplingrate=TDT_trial_temp(vt).LFPx_samplingrate;
            end
        end
        if DISREGARDSPIKES && isfield(TDT_trial,'eNeu_t')
            %% take over spikes from the file that was already saved if it's there and we disregarded spikes this time
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial_temp(vt).eNeu_t=TDT_trial(vt).eNeu_t;
                TDT_trial_temp(vt).eNeu_w=TDT_trial(vt).eNeu_w;
            end
            
        elseif isfield(TDT_trial_temp,'eNeu_t') && ~isfield(TDT_trial,'eNeu_t')
            %% this is only here so that structures have the same fieldnames in the end
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial(vt).eNeu_t=TDT_trial_temp(vt).eNeu_t;
                TDT_trial(vt).eNeu_w=TDT_trial_temp(vt).eNeu_w;
            end
        end
        TDT_trial=orderfields(TDT_trial);
    end
    TDT_trial_temp=orderfields(TDT_trial_temp);
    TDT_trial(Validtrials)=TDT_trial_temp(Validtrials);
    First_trial_INI=First_trial_INI_temp;
    pp_fns=fieldnames(preprocessing_settings_temp);
    %% save only really used preprocessing settings (LFP settings not taken over if Disregard_LFP, SPK settings not taken over if DISREGARD_SPIKES)
    for f=1:numel(pp_fns)
        preprocessing_settings.(pp_fns{f})=preprocessing_settings_temp.(pp_fns{f});
    end
    save(filename,'TDT_trial','First_trial_INI','preprocessing_settings');
end
end

function  Output_stream=filter_function(Input_stream,samplingrate,SR_factor,N_samples_original,preprocessing_settings)
%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP.notch_filter1*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(Input_stream));

%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP.notch_filter2*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(datafilt));

% highpass
[b,a]=butter(4, preprocessing_settings.LFP.HP_filter*2/samplingrate, 'high'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);

% lowpass
n = floor(samplingrate/preprocessing_settings.LFP.LP_median_filter);
datafilt = DAG_median_filter(datafilt,n);


% downsampling --> easy way
% duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
% also, cut off last 12 samples (to have the same length in the as in the input)
datafilt=[datafilt(1:round(SR_factor/2)) datafilt(1:end-round(SR_factor/2))];

%% How does it work in TDT to assign LFP samples... Can't get to the same amount (+/- 1 sample)?
% Problem occurs, when numel(datafilt)/SR_factor<=N_samples_original
% Try without cutting off last 12 samples first ?
RR=N_samples_original*SR_factor-numel(datafilt);
if abs(RR)>50000
    disp(['LFP and Boradband time do not match! t(LFP-Broa)=~ ' num2str(round(RR/24000)) 's']);
end

if RR<0
    %remove last few samples so the total number divided by SR_factor is integer
    datafilt(end+RR+1:end)=[];
else
    %duplicate last few samples so the total number divided by SR_factor is integer
    datafilt(end+1:end+RR)=datafilt(end-RR+1:end);
end

%take nanmean of every 24 samples
Output_stream=nanmean(reshape(datafilt,SR_factor,numel(datafilt)/SR_factor),1);
end

function  Output_stream=filter_function_simple(Input_stream,samplingrate,preprocessing_settings)
%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP.notch_filter1*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(Input_stream));

%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP.notch_filter2*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(datafilt));

% highpass
[b,a]=butter(4, preprocessing_settings.LFP.HP_filter*2/samplingrate, 'high'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);

% lowpass
[b,a]=butter(4, preprocessing_settings.LFP.LP_bw_filter*2/samplingrate, 'low'); % 'low', 'high
Output_stream=  filtfilt(b,a, datafilt);
end
