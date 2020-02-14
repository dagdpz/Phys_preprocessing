function DAG_WC3_preprocessing(tankname,recordingnames,handles_in)
%% TODO: remove folder switching... doesnt make any sense t all



% SYSTEM MEMORY
%handles.RAM = 64;                                                           % in GB
handles.RAM = 24;                                                           % in GB

% RECORDING SYSTEM
handles.sys = 'TD';

% RAW DATAFILES NAME
handles.rawname = '*.tdtch';
handles.blockfile=0;

% SAMPLING RATE---> this should be taken from the actual TDT information
handles.par.sr = 24414.0625;

% Data TYPE
handles.dtyperead = 'single';                                                  % Default for BR, TD

if strcmp(handles.dtyperead,'float32')
    handles.dtype = 'single';
end
if strfind(handles.dtyperead,'uint');
    handles.dtypewrite = handles.dtyperead(2:end);
else
    handles.dtypewrite = handles.dtyperead;
end

% ARRAY CONFIGURATION
handles.numArray = 6;
handles.numchan = 64;                                                       % Channels per Array
handles.arraynoisecancelation = 0;

% LINE NOISE
handles.linenoisecancelation = 0;                                           % 1 for yes; 0 for no
% handles.linenoisefrequ = 100;
handles.linenoisefrequ = 50;

% FILTER OPTIONS
handles.hp = 'but'; %'med'                                                       % med = medianfiltersubtraction; int = interpolationsubtraction; but = butterworth
handles.hpcutoff = 333;%333;                                                     % in Hz
handles.lpcutoff = 5000;%5000;                                                    % in Hz
% handles.par.transform_factor = 0.25;                                      % microVolts per bit for higher accuracy when saved as int16 after filtering; Default for BR
handles.par.transform_factor = 0.25;                                           % Default for RHD2000
handles.iniartremovel = 1;
handles.drinkingartremoval = 1;

% DETECTION
% handles.par.w_pre = 20;
% handles.par.w_post = 44;
handles.par.w_pre = 10;
handles.par.w_post = 22;
handles.par.ref = 0.001;
handles.par.int_factor = 2;
handles.par.interpolation ='y';
handles.par.stdmax = 100;%100;
handles.threshold ='neg';


handles.par.StdThrMU = 3;%5 spike threshold in std's (based on median)
handles.par.StdThrSU = 5;%5 spike threshold in std's (based on median)

% other
handles.cell_tracking_distance_limit=50; 
handles.remove_ini=1; 
handles.monkey='unknown'; 


%% overwriting handles with input
handles_fn=fieldnames(handles_in)';
handles_fn=handles_fn(ismember(handles_fn,fieldnames(handles)));
for FN=handles_fn
    if isstruct(handles.(FN{:}))
        handles_fn_sub=fieldnames(handles_in.(FN{:}))';
        for fn=handles_fn_sub
            handles.(FN{:}).(fn{:})= handles_in.(FN{:}).(fn{:});            
        end        
    else
        handles.(FN{:})= handles_in.(FN{:});
    end    
end


monkey=handles.monkey;
current_path=pwd;
drive=get_dag_drive_IP;
DBpath=getDropboxPath;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey '_dpz' filesep];

%% load electrode depths for selecting which electrodes are useful
% AND for defining which blocks should be concatinated per channel
run([DBfolder 'Electrode_depths_' monkey(1:3)]);
channels_to_process=unique([channels{cell2mat(Session)==tankname}]);

%% load excel lag table if applicable
lag_table_string={'Session','Block','lag_seconds'};
lag_table_num=zeros(size(lag_table_string));
if exist([DBfolder filesep monkey '_LFP_BROA_comp.xls'],'file')
    
[lag_table_num,lag_table_string]=xlsread([DBfolder filesep monkey '_LFP_BROA_comp.xls']);
end


%% need to switch to the respective folder... -.-
tank = [drive '\Data\TDTtanks' filesep monkey filesep num2str(tankname) '\'];          % path of recordings
handles.task_times=[];
for ii =1:length(recordingnames)
    
    block_char       =recordingnames{ii}(strfind(recordingnames{ii},'-')+1:end);
    recname     =['blocks_' block_char];
    disp(['Processing: ' recname]);
    folder      =['WC_' recordingnames{ii} '\'];
    if ~exist([tank filesep folder],'dir')
        mkdir(tank,folder);
    end
    %% readout lag
    lag=ph_readout_broadband_lag(lag_table_num,lag_table_string,tankname,str2double(block_char));
    
    
    parse_data_tdt([tank recordingnames{ii}],'Broadband',channels_to_process,lag)
    
    %% lts and sr are saved in tdtmetadfile
    load([tank folder filesep 'tdt_meta_data'],'lts','sr');
    handles.sr=sr;
    handles.block_duration_in_samples(ii)=lts;
    cd([tank folder])
    DAG_SpikefilterChan(handles); % this one is the function why we need to switch folders
    state_information = TDTbin2mat_working([drive 'Data\TDTtanks' filesep monkey filesep num2str(tankname) filesep recordingnames{ii}] , 'EXCLUSIVELYREAD',{'SVal'},'SORTNAME', 'Plexsormanually');
    
    %% on and offs are in seconds!
    if ~isempty(state_information.epocs)
    offs_temp=state_information.epocs.SVal.onset(state_information.epocs.SVal.data>18);
    ons=state_information.epocs.SVal.onset(state_information.epocs.SVal.data<2);
    offs=NaN(size(ons));
    t_critical=[];
    for t=1:numel(ons)
        if any(offs_temp>ons(t))
            offs(t)=offs_temp(find(offs_temp>ons(t),1,'first')) + 0.06; % adding 60 ms so
        else
            t_critical=[t_critical t];
        end
    end
    offs(t_critical)=[];
    ons(t_critical)=[];
    handles.task_times_per_block{ii}=[ons offs]; %% here i expect an error at some point - dimension mismatch
    else %% if there is no task information, take full block
    handles.task_times_per_block{ii}=[0 (datenum(state_information.info.utcStopTime,'HH:MM:SS')-datenum(state_information.info.utcStartTime,'HH:MM:SS'))*24*3600]; %% here i expect an error at some point - dimension mismatch
    end
    cd(current_path)
end

handles.main_folder=[drive 'Data\TDTtanks' filesep monkey filesep num2str(tankname) filesep];
handles.WC_concatenation_folder=[handles.main_folder 'WC' filesep];
blocks_in_this_session=[block{cell2mat(Session)==tankname}];

%% here we go through channels to concatinate data from same channel in same depth!
if ~exist(handles.WC_concatenation_folder,'dir')
    mkdir(handles.main_folder,'WC');
end
% if one block is skipped in the electorde depth file, depths_in_this_session is not the same as depths_temp
depths_temp=z(cell2mat(Session)==tankname);
channels_temp=channels(cell2mat(Session)==tankname);
for b=1:numel(blocks_in_this_session)
    depths_in_this_session(blocks_in_this_session(b))=depths_temp(b);
    channels_in_this_session(blocks_in_this_session(b))=channels_temp(b);
end

for ch=channels_to_process
    handles.current_channel = ch;
    previous_blocks_depth=0;
    blocks_to_process=cell(1);
    same_depth_counter=0;
    for b=blocks_in_this_session
        depth=depths_in_this_session{b}(channels_in_this_session{b}==ch);
        if abs(previous_blocks_depth-depth) <= handles.cell_tracking_distance_limit
            blocks_to_process{same_depth_counter}(end+1)=b;
        else
            same_depth_counter=same_depth_counter+1;
            blocks_to_process{same_depth_counter}=b;
        end
        previous_blocks_depth=depth;
    end
    
    for f=1:numel(blocks_to_process)
        handles.current_blocks=blocks_to_process{f};
        handles.current_channel_file = f;
        
        channelfile=[sprintf('%03d',handles.current_channel) '_' num2str(handles.current_channel_file)];
        %% correct state onsets...
        blockstart_samples=0;
        handles.task_times=[];
        for cb=handles.current_blocks
            blockstart=blockstart_samples/handles.sr;
            wheretofindwhat{cb}{ch}=f; % this will be important later for PLX file creation
            handles.task_times=[handles.task_times; handles.task_times_per_block{cb}+blockstart];
            blockend_samples=blockstart_samples+handles.block_duration_in_samples(cb);
            blockend=blockend_samples/handles.sr;
            blocksamplesperchannel{ch}(cb,:)=[blockstart_samples blockend_samples];
            blockstart_samples=blockend_samples+1;
        end
        
        for threshold_step={'SU','MU'}
            handles.current_threshold_step=threshold_step{:};
            handles.par.stdmin = handles.par.(['StdThr' handles.current_threshold_step]);
            %         %%FOLDER MANAGEMENT!!   we should switch to main folder here...
            Extract_spikes4_cat_MU_SU(handles);
            
            if strcmp(threshold_step,'low') %% load high threshold spikes file and remove the respective spikes
                switch handles.threshold
                    case 'pos'
                        thresholds={'_pos'};
                    case 'neg'
                        thresholds={'_neg'};
                    case 'both'
                        thresholds={'_neg','_pos'};
                end
                for k=1:numel(thresholds)
                    filename_MU=[handles.WC_concatenation_folder 'dataspikes_ch' channelfile '_MU' thresholds{k} '.mat'];
                    filename_SU=[handles.WC_concatenation_folder 'dataspikes_ch' channelfile '_SU' thresholds{k} '.mat'];
                    load(filename_SU);
                    index_SU=index;
                    load(filename_MU);
                    
                    to_keep=~ismember(index,index_SU);
                    index=index(to_keep);
                    spikes=spikes(to_keep,:);
                    cluster_class=cluster_class(to_keep,:);                    
                    save(filename_MU,'spikes','index','thr','par','cluster_class')
                end
            end
            
            cd(handles.WC_concatenation_folder) %-.-
            Do_clustering4_redo_cat_MU_SU(handles); % this one does the actual clustering. There is no way to do it in waveclus itself...
            cd(current_path)
        end
        
    end
    
    %% need to document what to find where
    whattofindwhere{ch}=blocks_to_process;
end
save([handles.WC_concatenation_folder 'concatenation_info'],'blocksamplesperchannel','wheretofindwhat','whattofindwhere','channels_to_process','sr','handles')

end