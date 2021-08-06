function DAG_WC3_preprocessing(Session_as_num,recordingnames,handles_in)

handles=handles_in;

cell_tracking_distance_limit=handles.WC.cell_tracking_distance_limit;

%monkey=handles.monkey;
monkey_phys=handles.monkey_phys;
current_path=pwd;
drive=DAG_get_server_IP;
DBpath=DAG_get_Dropbox_path;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey_phys '_dpz' filesep];

%% load electrode depths for selecting which electrodes are useful
% AND for defining which blocks should be concatinated per channel
run([DBfolder 'Electrode_depths_' monkey_phys(1:3)]);
handles.channels_to_process=unique([channels{cell2mat(Session)==Session_as_num}]);
channels_to_process=handles.channels_to_process;
if isempty(handles.channels_to_process)
    disp(['No matching Session' num2str(Session_as_num) 'in Electrode_depths_' monkey_phys(1:3) '.mat']);
    return;
end


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
    recordingname=recordingnames{ii};
    folder      =['WC_' recordingname ];
    handles.block_path             = [handles.tank_folder recordingname];
    handles.WC_block_folder        = [handles.sortcodes_folder folder filesep];
    handles.TDT_meta_data_file     = [handles.WC_block_folder 'tdt_meta_data'];
    
    block_char      = recordingname(strfind(recordingname,'-')+1:end);
    block_num       = str2double(block_char);
    disp(['Processing: ' monkey_phys ' ' num2str(Session_as_num) ' ' recordingname]);
    if ~exist(handles.WC_block_folder,'dir')
        mkdir(handles.sortcodes_folder,folder);
    end
    
    %% readout lag
    lag=ph_readout_broadband_lag(lag_table_num,lag_table_string,Session_as_num,str2double(block_char));
    
    %% lts and sr are saved in tdtmetadfile
    DAG_parse_data_tdt(handles,'Broadband',lag)
    load(handles.TDT_meta_data_file,'lts','sr');
    handles.WC.sr=sr; % here we make sure real TDT sr is taken; so this info needs to be saved
    handles.sr_per_block{block_num}=sr; % here we make sure real TDT sr is taken; so this info needs to be saved
    handles.block_duration_in_samples(block_num)=lts;
    
    %% apply filters
    DAG_SpikefilterChan(handles);
    state_information = TDTbin2mat_working([handles.tank_folder recordingname] , 'EXCLUSIVELYREAD',{'SVal'},'SORTNAME', 'Plexsormanually');
    
    %% get task on and offsets (to potentially cut out ITI later on) : on and offs are in seconds!
    if handles.WC.remove_ini && ~isempty(state_information.epocs) %% && isfield(state_information,'epocs') 
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
        handles.task_times_per_block{block_num}=[ons offs]; %% here i expect an error at some point - dimension mismatch
    else %% if there is no task information, take full block
        handles.task_times_per_block{block_num}=[0 (datenum(state_information.info.utcStopTime,'HH:MM:SS')-datenum(state_information.info.utcStartTime,'HH:MM:SS'))*24*3600]; %% here i expect an error at some point - dimension mismatch
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
        if abs(previous_blocks_depth-depth) <= cell_tracking_distance_limit
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
        
        handles.WC.sr=handles.sr_per_block{handles.current_blocks(1)}; % here we make sure real TDT sr is taken; so this info needs to be saved
        
        %% correct state onsets...
        blockstart_samples=0;
        handles.task_times=[];
        for cb=handles.current_blocks
            blockstart=blockstart_samples/handles.sr_per_block{cb};
            wheretofindwhat{cb}{ch}=f; % this will be important later for PLX file creation
            handles.task_times=[handles.task_times; handles.task_times_per_block{cb}+blockstart];
            blockend_samples=blockstart_samples+handles.block_duration_in_samples(cb);
            blockend=blockend_samples/handles.sr_per_block{cb};
            blocksamplesperchannel{ch}(cb,:)=[blockstart_samples blockend_samples];
            blockstart_samples=blockend_samples+1;
        end
        
        %% Detect and cluster SUs and MUs individually
        threshold_steps={'SU';'MU'};
        
        for s=1:numel(threshold_steps)
            threshold_step=threshold_steps(s);
            handles.current_threshold_step=threshold_step{:};
            handles.WC.stdmin = handles.WC.(['StdThr' handles.current_threshold_step]);
            
            %% Spike detection
            wc_extract_spikes_cat_MU_SU(handles);
            switch handles.WC.threshold
                case 'pos'
                    thresholds={'_pos'};
                case 'neg'
                    thresholds={'_neg'};
                case 'both'
                    thresholds={'_neg';'_pos'};
            end
            %% load SU threshold spikes file and remove the respective spikes
            if strcmp(threshold_step,'MU')                
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
        end
        
        %% feature computation within SU/MU
        [Ax,Bx] = ndgrid(1:numel(threshold_steps),1:numel(thresholds));
        feature_types = strcat(threshold_steps(Ax(:)),thresholds(Bx(:)));
        clear tmp
        for k=1:numel(feature_types)
            load([handles.WC_concatenation_folder 'dataspikes_ch' channelfile '_' feature_types{k} '.mat']);
            tmp.spikes{k}=spikes;
            tmp.index{k}=index;
            tmp.thr{k}=thr;
            tmp.par{k}=par;
            tmp.cluster_class{k}=cluster_class;
            
            fprintf(['Feature detection for ' channelfile feature_types{k} '...\n']);
            [tmp.features{k},tmp.feature_names,tmp.feature_sds{k}] = wc_get_features(spikes,index,handles);
            delete([handles.WC_concatenation_folder 'dataspikes_ch' channelfile '_' feature_types{k} '.mat']);
        end
        
        %% get relevant parameters
        
        %% concatinate all and order by time
        spikes=vertcat(tmp.spikes{:});
        index=vertcat(tmp.index{:});
        ccall=vertcat(tmp.features{:});
        cluster_class=vertcat(tmp.cluster_class{:});
        par=tmp.par{1};
        thr=vertcat(tmp.thr{:});
        
        [~,t_index]=sort(index);
        spikes=spikes(t_index,:);
        ccall=ccall(t_index,:);
        index=index(t_index,:);
        cluster_class=cluster_class(t_index,:);
        features_per_subset=tmp.features;
        fn=tmp.feature_names;
        feature_sds = vertcat(tmp.feature_sds{:});
        
        save([handles.WC_concatenation_folder 'dataspikes_ch' channelfile '.mat'],'spikes','index','thr','par','cluster_class')
        
        %% feature selestion across the entire dataset!
        [inspk,feature_names,inputs] = wc_feature_selection3(ccall,fn,feature_sds,features_per_subset,handles);
        
        cd(handles.WC_concatenation_folder) % for SPC to work, we have to change to the respective directory...
        wc_clustering_iterative_combined(inspk,feature_names,inputs,handles); % this one does the actual clustering. There is no way to do it in waveclus itself...
        cd(current_path)
        
        
    end
    
    %% need to document what to find where
    whattofindwhere{ch}=electrode_locations_to_process;
end
save([handles.WC_concatenation_folder 'concatenation_info'],'blocksamplesperchannel','wheretofindwhat','whattofindwhere','channels_to_process','sr')
%% save WC settings...

save([handles.WC_concatenation_folder 'settings'],'handles')
%% identify next plx file name?
%% save per plx file extension
end