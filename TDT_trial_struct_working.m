function TDT_trial_struct_working(data_path,monkey,dates,block,varargin)
% TDT_trial_struct_working('L:\Data\','Linus_phys','20150520','block-1')
% Last modified: 20170531: Added Broadband filtering and did some major
% restructuring for stream_state_info separation
% Last modified: 20170515: Fixed bug in chopping streamed data into trials
% (was using the same sample for end of this as well as for beginning of
% next trial)
% Danial Arabali & Lukas Schneider


settings.LFP_notch_filter1= [49.9 50.1];
settings.LFP_notch_filter2= [99.9 100.1];
settings.LFP_HP_filter= 1;
settings.LFP_LP_bw_filter= 150;
settings.LFP_LP_median_filter= 250;

%% crate folders
mainraw_folder                  = strcat([data_path monkey '_mat_from_TDT']);
temp_raw_folder                 = strcat([mainraw_folder filesep dates]);
if exist(mainraw_folder,'dir')~=7
    mkdir(mainraw_folder)
end
if exist(temp_raw_folder,'dir')~=7
    mkdir(temp_raw_folder)
end

%% to check if epoch stores are computed correctly in TDT, there is still the possibility of using the streamed state data (not sure if it works correctly though):
stream_state_info=0; % 1: using the stat stream data, 0: using only epoch stores (faster !!)
% here we can derive the key for which plx-file to use
PLXVERSION='';
DISREGARDLFP=0;
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end
data             =TDTbin2mat_working([data_path 'TDTtanks' filesep monkey filesep dates filesep block], varargin{:});
clc;
Block_N=block(strfind(block,'-')+1:end);
%% overwriting snippets with plx file (in case it exists and waveclus option was selected)
% not entirely clean, but we want to keep the format we already have
if strcmp(PLXVERSION,'Snippets')
    plxfile=[data_path 'TDTtanks' filesep monkey filesep dates filesep dates  '_blocks_' Block_N '-01.plx'];
else
    plxfile=[data_path 'TDTtanks' filesep monkey filesep dates filesep dates '_' PLXVERSION '_blocks_' Block_N '-01.plx'];
end
if exist(plxfile,'file')
    SPK=PLX2SPK(plxfile);            % convert the sorted plexon file into spkobj-format; merge the new sorted waveforms with the old SPKOBJ to geht thresholds and noiselevels as well.
    %backscaling (see DAG_create_PLX)
    if strcmp(PLXVERSION,'from_BB') 
    load([data_path 'TDTtanks' filesep monkey filesep dates filesep 'WC' filesep 'concatenation_info'],'wf_scale');
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
%
% trials_start_mark       = [false diff(data.streams.stat.data==stopper_INI_trial)==1];
% find_stopper_INI_trial  = [find(trials_start_mark) numel(trials_start_mark)+1];
% trials_end_mark         = [diff(data.streams.stat.data==stopper_INI_states)==-1 false];
% find_stopper_END_trial  = [find(trials_end_mark) numel(trials_end_mark)];


%% Extracting Session, Run, Trial, and time o�nformation
% Either from stat header or from epocs
%for counter=1:1
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


%% check what kind of data is available => why should this ever be empty?
%
% stream_fieldnames={};epoc_fieldnames={};snippet_fieldnames={};scalar_fieldnames={};
% if ~isempty (data.streams);     stream_fieldnames=fieldnames(data.streams);end
% if ~isempty (data.epocs);       epoc_fieldnames=fieldnames(data.epocs);end
% if ~isempty (data.snips);       snippet_fieldnames=fieldnames(data.snips);end
% if ~isempty (data.scalars);     scalar_fieldnames=fieldnames(data.scalars);end

%% Snippet selection
if isstruct(data.snips)
snippet_fieldnames=fieldnames(data.snips);
snip_index=ismember(snippet_fieldnames,{'eNeu'});
else
snip_index=[];
end
%% Stream Selections (for LFP)
stream_fieldnames=fieldnames(data.streams);
BB_index=ismember(stream_fieldnames,{'BROA','Broa'});
LFP_index=ismember(stream_fieldnames,{'LFPx'});
settings.LFP_from='Broa';
% don't consider broadband if its sampling rate is below 5000 Hz
if ~any(BB_index) || data.streams.(stream_fieldnames{BB_index}).fs<5000
    stream_fieldnames(BB_index)=[];
    BB_index=false(size(stream_fieldnames));
    settings.LFP_from='LFPx';
end

%% load excel lag table if applicable
DBpath=getDropboxPath;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey '_dpz' filesep];

lag_table_string={'Session','Block','lag_seconds'};
lag_table_num=zeros(size(lag_table_string));
if exist([DBfolder filesep monkey '_LFP_BROA_comp.xls'],'file')    
[lag_table_num,lag_table_string]=xlsread([DBfolder filesep monkey '_LFP_BROA_comp.xls']);
end

% use Broadband for LFP if available
if any(BB_index)
    BB=stream_fieldnames{BB_index};
    stream_fieldnames{BB_index}='LFPx';
    stream_fieldnames(LFP_index)=[];
    %% create LFP based on filtering broadband
    samplingrate=data.streams.(BB).fs;              %Hz ?
    SR_factor=round(samplingrate/1010);             % LFP sampling rate should be exactly 1/24th of boradband
    data.streams.LFPx.fs=samplingrate/SR_factor;
    
    %% correct for lag here
    lag=ph_readout_broadband_lag(lag_table_num,lag_table_string,str2double(dates),Block_N);
    lag_in_samples=round(lag*samplingrate);
     if lag_in_samples>0
       data.streams.(BB).data(:,1:lag_in_samples)=[];
     else
       data.streams.(BB).data=[zeros(size(data.streams.(BB).data,1),abs(lag_in_samples)) data.streams.(BB).data];         
     end
     
    for channel=1: size(data.streams.(BB).data,1)
        %% filter BB to LFP
        data.streams.LFPx.data(channel,:)=filter_function(data.streams.(BB).data(channel,:),samplingrate,SR_factor,size(data.streams.LFPx.data,2),settings);
    end
elseif any(LFP_index)
    samplingrate=data.streams.LFPx.fs;  
    for channel=1: size(data.streams.LFPx.data,1)
        %% filter LFP 1000 Hz
        data.streams.LFPx.data(channel,:)=filter_function_simple(data.streams.LFPx.data(channel,:),samplingrate,settings);
    end
end

%% separate each trial
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
            trial_samples_for_state         =[find_stopper_END_trial(tr_block): find_stopper_END_trial(tr_block+1)-1];
            trial_time                      =[trial_samples_for_state(1) trial_samples_for_state(end)]./data.streams.stat.fs;
            TDT_DATA.Trial(tr).purestates   = data.streams.stat.data(trial_samples_for_state);
            % finding time of target acquisition in this state
            FIX_ACQ_start_time              =find(TDT_DATA.Trial(tr).purestates==2)./data.streams.stat.fs;
            FIX_ACQ_start_time              =FIX_ACQ_start_time(1);
            
            
            %             trial_samples_for_state=[find_stopper_INI_trial(tr_block): find_stopper_INI_trial(tr_block+1)-1];
            %             trial_time=[trial_samples_for_state(1) trial_samples_for_state(end)]./data.streams.stat.fs;
            %             TDT_DATA.Trial(tr).completestates= data.streams.stat.data(trial_samples_for_state);
            %
            %             % removing header data from states
            %             TDT_DATA.Trial(tr).purestates= TDT_DATA.Trial(tr).completestates;
            %             TDT_DATA.Trial(tr).purestates(ismember(trial_samples_for_state,find_stopper_INI_trial(tr_block):find_stopper_END_trial(tr_block)))= 1;
            %             % finding time of target acquisition in this state
            %             FIX_ACQ_start_time          =find(TDT_DATA.Trial(tr).purestates==2)./data.streams.stat.fs;
            %             FIX_ACQ_start_time          =FIX_ACQ_start_time(1);
            
        else
            trial_time                  =[trialonsets(tr_block) trialonsets(tr_block+1)];
            trial_states_indexes        =data.epocs.SVal.onset>=trial_time(1) & data.epocs.SVal.onset<=trial_time(2);
            TDT_DATA.Trial(tr).states   =data.epocs.SVal.data(trial_states_indexes);
            state_onsets_temp           =data.epocs.SVal.onset(trial_states_indexes);
            FIX_ACQ_start_time          =state_onsets_temp(TDT_DATA.Trial(tr).states==2)-trial_time(1);
        end
        if isempty(FIX_ACQ_start_time);
            Invalidtrials=[Invalidtrials tr];
            continue;
        elseif ~stream_state_info
            TDT_DATA.Trial(tr).state_onsets=state_onsets_temp-FIX_ACQ_start_time-trial_time(1);
        end
        
        %% Streams
        for current_fieldname=1:numel(stream_fieldnames)
            samplingrate=data.streams.(stream_fieldnames{current_fieldname}).fs;
            start_end_samples=round(trial_time*samplingrate);
            end_sample=min([start_end_samples(end)-1, size(data.streams.(stream_fieldnames{current_fieldname}).data,2)]);
            for channel=1: size(data.streams.(stream_fieldnames{current_fieldname}).data,1)
                TDT_DATA.Trial(tr).(stream_fieldnames{current_fieldname})(channel,:)=data.streams.(stream_fieldnames{current_fieldname}).data(channel,start_end_samples(1):end_sample);
            end
            % cutting off INI trial and create new structure to append to
            % previous trial ... WHAT HAPPENS IF TRIAL IS CORRUPTED (Invalid)???
            samples_to_skip=round((FIX_ACQ_start_time-(start_end_samples(1)/samplingrate-trial_time(1)))*samplingrate);
            DATA_TO_APPEND.Trial(tr).(stream_fieldnames{current_fieldname})=TDT_DATA.Trial(tr).(stream_fieldnames{current_fieldname})(:,1:samples_to_skip);
            TDT_DATA.Trial(tr).(stream_fieldnames{current_fieldname})(:,1:samples_to_skip)=[];
            TDT_DATA.Trial(tr).([stream_fieldnames{current_fieldname} '_samplingrate'])=samplingrate;
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
                    if unique_sortcodes(sortcode)==0 %% drop unsorted spikes
                        TDT_DATA.Trial(tr).eNeu_t{chan,sortcode}=[];
                        TDT_DATA.Trial(tr).eNeu_w{chan,sortcode}=[];
                    else
                        TDT_DATA.Trial(tr).eNeu_t{chan,sortcode-any(unique_sortcodes==0)}=...
                            [data.snips.eNeu.ts(trial_snippet_indexes & channel_idx & sortcodeidx)-trial_time(1)-FIX_ACQ_start_time];
                        TDT_DATA.Trial(tr).eNeu_w{chan,sortcode-any(unique_sortcodes==0)}=...
                            [data.snips.eNeu.data(trial_snippet_indexes & channel_idx & sortcodeidx,:)];
                    end
                end
            end
        end
        
        %         for FN=1:numel(snippet_fieldnames)
        %             trial_snippet_indexes=[data.snips.(snippet_fieldnames{FN}).ts>=trial_time(1) & data.snips.(snippet_fieldnames{FN}).ts<=trial_time(2)];
        %             unique_channels=unique(data.snips.(snippet_fieldnames{FN}).chan);
        %             for chan=unique_channels'
        %                 channel_idx=data.snips.(snippet_fieldnames{FN}).chan==chan;
        %                 unique_sortcodes=unique([data.snips.(snippet_fieldnames{FN}).sortcode]);
        %                 for sortcode=1:numel(unique_sortcodes)
        %                     sortcodeidx=data.snips.(snippet_fieldnames{FN}).sortcode==unique_sortcodes(sortcode);
        %                     if unique_sortcodes(sortcode)==0 %% drop unsorted spikes
        %                         TDT_DATA.Trial(tr).([snippet_fieldnames{FN} '_t']){chan,sortcode}=[];
        %                         TDT_DATA.Trial(tr).([snippet_fieldnames{FN} '_w']){chan,sortcode}=[];
        %                     else
        %                         TDT_DATA.Trial(tr).([snippet_fieldnames{FN} '_t']){chan,sortcode-any(unique_sortcodes==0)}=...
        %                             [data.snips.(snippet_fieldnames{FN}).ts(trial_snippet_indexes & channel_idx & sortcodeidx)-trial_time(1)-FIX_ACQ_start_time];
        %                         TDT_DATA.Trial(tr).([snippet_fieldnames{FN} '_w']){chan,sortcode-any(unique_sortcodes==0)}=...
        %                             [data.snips.(snippet_fieldnames{FN}).data(trial_snippet_indexes & channel_idx & sortcodeidx,:)];
        %                     end
        %                 end
        %             end
        %         end
        
        
        %% save date , run, trials, session, block
        %         if stream_state_info
        %             trial_samples_for_state         = find_stopper_INI_trial(tr_block):find_stopper_END_trial(tr_block);
        %             DateRunTrial_states             = data.streams.stat.data(trial_samples_for_state);
        %             DateRunTrial                    = DateRunTrial_states([false diff(DateRunTrial_states==stopper_no_change)==-1]);
        %             % date or session
        %             TDT_DATA.Trial(tr).session    = 20000000 + DateRunTrial(1)*10000 + DateRunTrial(2)*100 + DateRunTrial(3);
        %             TDT_DATA.Trial(tr).time       = DateRunTrial(4:6);
        %             TDT_DATA.Trial(tr).run        = DateRunTrial(7);
        %             TDT_DATA.Trial(tr).trial      = DateRunTrial(8)*10 + DateRunTrial(9);
        %             TDT_DATA.Trial(tr).block      = sprintf('%02d',str2double(block(7:end)));
        %         else
        TDT_DATA.Trial(tr).time       = [Hour(tr_block) Minute(tr_block) Second(tr_block)];
        TDT_DATA.Trial(tr).run        = Runs(tr_block);
        TDT_DATA.Trial(tr).session    = 20000000+Session(tr_block);
        TDT_DATA.Trial(tr).trial      = tr;
        TDT_DATA.Trial(tr).block      = sprintf('%02d',str2double(block(7:end)));
        %        end
        
        
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
    
    %% In case we were using stream_state_info, we have to separate runs, and assign trial numbers at this stage
    %% Actually not, should work as it is now... DOUBLECHECK!
    %for idx_run=1: max(unique([TDT_DATA.Trial.run]))
    %for idx_run=unique([TDT_DATA.Trial.run])
    run=unique([TDT_DATA.Trial.run]);
    clear TDT_trial TDT_trial_temp 
    for tr=runtrials
        %% here exclude the ones that didnt have fix_acq....!!!
        %if ~isempty(TDT_DATA.Trial(tr).run) && TDT_DATA.Trial(tr).run==idx_run
        TDT_trial_temp(TDT_DATA.Trial(tr).trial) = TDT_DATA.Trial(tr); % This is temp, because we potentially overwrite the file we load!!!
        %end
    end
    First_trial_INI_temp=First_trial_INI;
    
    filename=[temp_raw_folder, filesep, monkey(1:3), 'TDT', dates(1:4), '-', dates(5:6), '-', dates(7:8), '_', sprintf('%02d',run) ];
    Validtrials=find(~arrayfun(@(x) isempty(x.trial),TDT_trial_temp));
    if exist([filename '.mat'],'file')
        load(filename,'TDT_trial','First_trial_INI');
        if DISREGARDLFP && isfield(TDT_trial,'LFPx')
            % take over LFP from the file that is already saved - what
            % happens with First_trial_INI? If there is such a thing, it
            % will never be updated?
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial_temp(vt).LFPx=TDT_trial(vt).LFPx;
                TDT_trial_temp(vt).LFPx_samplingrate=TDT_trial(vt).LFPx_samplingrate;
            end
            if isfield(First_trial_INI,'LFPx') %% new bug?? Lin 20151119 probably because it didnt exist from before
                First_trial_INI_temp.LFPx=First_trial_INI.LFPx;
            end
            
        elseif isfield(TDT_trial_temp,'LFPx') && ~isfield(TDT_trial,'LFPx')
            
            for vt=Validtrials % really, a loop is needed for this?
                TDT_trial(vt).LFPx=TDT_trial_temp(vt).LFPx;
                TDT_trial(vt).LFPx_samplingrate=TDT_trial_temp(vt).LFPx_samplingrate;
            end
        end
        TDT_trial=orderfields(TDT_trial);
    end
    TDT_trial_temp=orderfields(TDT_trial_temp);
    TDT_trial(Validtrials)=TDT_trial_temp(Validtrials);
    First_trial_INI=First_trial_INI_temp;
    save(filename,'TDT_trial','First_trial_INI')
    save([mainraw_folder filesep dates '_settings'],'settings');
    %end
end
end

function  Output_stream=filter_function(Input_stream,samplingrate,SR_factor,N_samples_original,settings)
%bandstop filter 50 Hz
[b,a]=butter(2,settings.LFP_notch_filter1*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(Input_stream));

%bandstop filter 50 Hz
[b,a]=butter(2,settings.LFP_notch_filter2*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(datafilt));

% highpass
[b,a]=butter(4, settings.LFP_HP_filter*2/samplingrate, 'high'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);

% lowpass
n = floor(samplingrate/settings.LFP_LP_median_filter);
datafilt = DAG_median_filter(datafilt,n);


% downsampling --> easy way
% duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
% also, cut off last 12 samples (to have the same length in the as in the input)
datafilt=[datafilt(1:round(SR_factor/2)) datafilt(1:end-round(SR_factor/2))];
% duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
% datafilt=[datafilt(1:round(SR_factor/2)) datafilt];

RR=N_samples_original*SR_factor-numel(datafilt);

%% How does it work in TDT to assign LFP samples... Can't get to the same amount (+/- 1 sample)?
% Problem occurs, when numel(datafilt)/SR_factor<=N_samples_original
% Try without cutting off last 12 samples first ?

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

% R=mod(numel(datafilt),SR_factor);
% if numel(datafilt)/SR_factor>N_samples_original %&& R<SR_factor/2
%     %remove last few samples so the total number divided by SR_factor is integer
%     datafilt(end-R+1:end)=[];%
% elseif numel(datafilt)/SR_factor<=N_samples_original %&& R>=SR_factor/2
%     datafilt(end+1:end+SR_factor-R)=datafilt(end-SR_factor+R+1:end);
% else
%     %  error('LFP sample amount problem');
% end
%take nanmean of every 24 samples
Output_stream=nanmean(reshape(datafilt,SR_factor,numel(datafilt)/SR_factor),1);
end

function  Output_stream=filter_function_simple(Input_stream,samplingrate,settings)
% %bandstop filter 50 Hz
% filter_frq= [49.9 50.1];
% [b,a]=butter(2,filter_frq*2/samplingrate,'stop');
% datafilt=  filtfilt(b,a, double(Input_stream));
% 
% %bandstop filter 50 Hz
% filter_frq= [99.9 100.1];
% [b,a]=butter(2,filter_frq*2/samplingrate,'stop');
% datafilt=  filtfilt(b,a, double(datafilt));
% 
% % highpass
% filter_frq= 1;
% [b,a]=butter(4, filter_frq*2/samplingrate, 'high'); % 'low', 'high
% datafilt=  filtfilt(b,a, datafilt);
% 
% % lowpass
% filter_frq= 150;
% [b,a]=butter(4, filter_frq*2/samplingrate, 'low'); % 'low', 'high
% Output_stream=  filtfilt(b,a, datafilt);

%bandstop filter 50 Hz
[b,a]=butter(2,settings.LFP_notch_filter1*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(Input_stream));

%bandstop filter 50 Hz
[b,a]=butter(2,settings.LFP_notch_filter2*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(datafilt));

% highpass
[b,a]=butter(4, settings.LFP_HP_filter*2/samplingrate, 'high'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);

% lowpass
[b,a]=butter(4, settings.LFP_LP_bw_filter*2/samplingrate, 'low'); % 'low', 'high
Output_stream=  filtfilt(b,a, datafilt);

end