function DAG_WC3_preprocessing(Session_as_num,recordingnames,handles_in)

% SYSTEM MEMORY
handles.RAM = 24;   % in GB

% RECORDING SYSTEM
handles.sys = 'TD';

% RAW DATAFILES NAME
handles.rawname = '*.tdtch';
handles.blockfile=0;

% SAMPLING RATE---> this should be taken from the actual TDT information
handles.par.sr = 24414.0625;

% Data TYPE
handles.dtyperead = 'single';                                                  % Default for BR, TD
handles.dtypewrite = handles.dtyperead;

% ARRAY CONFIGURATION -> relevant for arraynoisecancellation
handles.numArray = 6;
handles.numchan = 64;                                                       % Channels per Array
handles.arraynoisecancelation = 0;

% LINE NOISE
handles.linenoisecancelation = 0;                                           % 1 for yes; 0 for no
handles.linenoisefrequ = 50;

% FILTER OPTIONS
handles.hp = 'but'; %'med'                                                       % med = medianfiltersubtraction; int = interpolationsubtraction; but = butterworth
handles.hpcutoff = 333;%333;                                                     % in Hz
handles.lpcutoff = 5000;%5000;                                                    % in Hz
handles.par.transform_factor = 0.25;                                        % microVolts per bit for higher accuracy when saved as int16 after filtering; Default for BR
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
handles.par.stdmax = 100;
handles.threshold ='neg';


handles.par.StdThrMU = 3;%5 spike threshold in std's (based on median)
handles.par.StdThrSU = 5;%5 spike threshold in std's (based on median)

% other
handles.cell_tracking_distance_limit=50; % for concatenating blocks even when electrode depth was slightly altered
handles.remove_ini=1;
handles.monkey='unknown';
handles.monkey_phys='unknown';


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


%monkey=handles.monkey;
monkey_phys=handles.monkey_phys;
current_path=pwd;
drive=get_dag_drive_IP;
DBpath=getDropboxPath;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey_phys '_dpz' filesep];

%% load electrode depths for selecting which electrodes are useful
% AND for defining which blocks should be concatinated per channel
run([DBfolder 'Electrode_depths_' monkey_phys(1:3)]);
channels_to_process=unique([channels{cell2mat(Session)==Session_as_num}]);

%% load excel lag table if applicable
lag_table_string={'Session','Block','lag_seconds'};
lag_table_num=zeros(size(lag_table_string));
if exist([DBfolder filesep monkey_phys '_LFP_BROA_comp.xls'],'file')
    
    [lag_table_num,lag_table_string]=xlsread([DBfolder filesep monkey_phys '_LFP_BROA_comp.xls']);
end


%% folder definitions
handles.sortcodes_folder        = [drive 'Data' filesep 'Sortcodes' filesep monkey_phys filesep num2str(Session_as_num) filesep];          % path of recordings
handles.tank_folder             = [drive 'Data' filesep 'TDTtanks'  filesep monkey_phys filesep num2str(Session_as_num) filesep];
handles.WC_concatenation_folder = [handles.sortcodes_folder 'WC' filesep];
handles.task_times=[];
for ii =1:length(recordingnames)
    folder      =['WC_' recordingnames{ii} ];
    handles.block_path             = [handles.tank_folder recordingnames{ii}];
    handles.WC_block_folder        = [handles.sortcodes_folder folder filesep];
    handles.TDT_meta_data_file     = [handles.WC_block_folder 'tdt_meta_data'];
    
    block_char       =recordingnames{ii}(strfind(recordingnames{ii},'-')+1:end);
    recname     =['blocks_' block_char];
    disp(['Processing: ' recname]);
    if ~exist(handles.WC_block_folder,'dir')
        mkdir(handles.sortcodes_folder,folder);
    end
    
    %% readout lag
    lag=ph_readout_broadband_lag(lag_table_num,lag_table_string,Session_as_num,str2double(block_char));
    
    %% lts and sr are saved in tdtmetadfile
    DAG_parse_data_tdt(handles,'Broadband',channels_to_process,lag)
    load(handles.TDT_meta_data_file,'lts','sr');
    handles.sr=sr;
    handles.block_duration_in_samples(ii)=lts;
    
    %% apply filters
    DAG_SpikefilterChan(handles);
    state_information = TDTbin2mat_working([handles.tank_folder recordingnames{ii}] , 'EXCLUSIVELYREAD',{'SVal'},'SORTNAME', 'Plexsormanually');
    
    %% get task on and offsets (to potentially cut out ITI later on) : on and offs are in seconds!
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
end

blocks_in_this_session=[block{cell2mat(Session)==Session_as_num}];


if ~exist(handles.WC_concatenation_folder,'dir')
    mkdir(handles.sortcodes_folder,'WC');
end

%% if one block is skipped in the electorde depth file, depths_in_this_session is not the same as depths_temp
depths_temp=z(cell2mat(Session)==Session_as_num);
channels_temp=channels(cell2mat(Session)==Session_as_num);
for b=1:numel(blocks_in_this_session)
    depths_in_this_session(blocks_in_this_session(b))=depths_temp(b);
    channels_in_this_session(blocks_in_this_session(b))=channels_temp(b);
end

%% here we go through channels to concatinate data from same channel in same depth!
for ch=channels_to_process
    handles.current_channel = ch;
    previous_blocks_depth=0;
    electrode_locations_to_process=cell(1);
    same_depth_counter=0;
    for b=blocks_in_this_session
        depth=depths_in_this_session{b}(channels_in_this_session{b}==ch);
        if abs(previous_blocks_depth-depth) <= handles.cell_tracking_distance_limit
            electrode_locations_to_process{same_depth_counter}(end+1)=b;
        else
            same_depth_counter=same_depth_counter+1;
            electrode_locations_to_process{same_depth_counter}=b;
        end
        previous_blocks_depth=depth;
    end
    
    %% looping through all different electrode locations in this channel
    for f=1:numel(electrode_locations_to_process)
        handles.current_blocks=electrode_locations_to_process{f};
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
        
        %% Detect and cluster SUs and MUs individually
        for threshold_step={'SU','MU'}
            handles.current_threshold_step=threshold_step{:};
            handles.par.stdmin = handles.par.(['StdThr' handles.current_threshold_step]);
            
            %% Spike detection
            Extract_spikes4_cat_MU_SU(handles);
            
            %% load SU threshold spikes file and remove the respective spikes
            if strcmp(threshold_step,'MU') 
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
            
            cd(handles.WC_concatenation_folder) % for SPC to work, we have to change to the respective directory...
            Do_clustering4_redo_cat_MU_SU(handles); % this one does the actual clustering. There is no way to do it in waveclus itself...
            cd(current_path)
        end
        
    end
    
    %% need to document what to find where
    whattofindwhere{ch}=electrode_locations_to_process;
end
save([handles.WC_concatenation_folder 'concatenation_info'],'blocksamplesperchannel','wheretofindwhat','whattofindwhere','channels_to_process','sr','handles')

end