function ph_combine_MP_and_TDT_data(handles,dates,blocks)

% ph_combine_MP_and_TDT_data('L','Linus_phys',[20150508 20150525],[])
% Converts TDT data into trial structure format (using TDT_trial_struct_working)
% and combines behavioural data with ephys data into a separate folder

% % % % % % % % % % % % % % % %
%  Potential parameters to read
%
% Streams   'stat'      'RWRD'    'senL'    'senR'    'LED1'    'trig'
%           'pNeu'      'LFPx'    'Broa'    'toxy'
% Epocs     'VStt'    'VPos'    'Tnum'    'TrPo'    'TrCh'    'TrTy'    'TrEf'    'SVal'    'StPo'    'StCh'    'StTy'    'StEf'
%           'Sess'    'RunN'    'Hour'    'Minu'    'Scnd'
% Snips     'eNeu'
%
% ??        'Tick'
% % % % % % % % % % % % % % % %
drive=handles.drive;
monkey=handles.monkey;
monkey_phys=handles.monkey_phys;
DISREGARDLFP                = handles.TODO.DisregardLFP;
DISREGARDSPIKES             = handles.TODO.DisregardSpikes;
%varargin={'PLXVERSION',handles.TDT.PLXVERSION,'DISREGARDLFP',handles.TODO.DisregardLFP,'DISREGARDSPIKES',Thandles.ODO.DisregardSpikes};

DONTREAD                    = {'pNeu','LED1','trig'}; %priority over ExclusivelyRead % 'BROA','Broa' (add these if you want to use online filtered LFP)
EXCLUSIVELYREAD             = {}; %(empty read everything)
CHANNELS                    = 1:128; %filter for signals
STREAMSWITHLIMITEDCHANNELS  = {'LFPx','Broa','BROA','pNeu'}; %filtered signals (only the part of the signal in the channel defined as filter will be read)
SORTNAME                    = 'Plexsormanually';
% Options: 'none': all sortcodes are 0 ''
% 'Snippets': taking sortcodes from SORTNAME,i.e. 'Plexsormanually';
% 'realigned': taking sortcodes from realigned (and potentially re-sorted) PLX file
% (needs to have extension '-01', if not existing it takes SORTNAME)
% 'from_BB': taking sortcodes from broadband PLX file
% (needs to have extension '-01', if not existing it takes SORTNAME)


user                        = getUserName;
disp(['Drive= ', drive, ' User= ', user, ' Monkey= ', monkey]);

DBpath=DAG_get_Dropbox_path;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey '_phys_dpz' filesep];
base_path                   = [drive 'Data' filesep]; % [drive ':\Data\'];
TDT_prefolder_dir           = [base_path 'TDTtanks' filesep monkey '_phys' filesep];
Combined_data_path          = strcat(base_path,[monkey '_phys_combined_monkeypsych_TDT' filesep]);
TDT_data_path               = strcat(base_path ,monkey, '_phys_mat_from_TDT', filesep);
MP_data_path                = strcat(base_path ,monkey, filesep);

%% get plx_file_table_to use
[~, ~, plx_file_table_to_use]=xlsread([DBfolder  monkey(1:3) '_plx_files.xlsx'],'to_use');
[~, ~, plx_file_table_in_use]=xlsread([DBfolder  monkey(1:3) '_plx_files.xlsx'],'in_use');
for c=1:size(plx_file_table_to_use,2)
    column_name = strrep(plx_file_table_to_use{1,c},' ','_');
    column_name = strrep(column_name,'?','');
    plx_file_table_to_use{1,c}=column_name;
    idx.(column_name)=DAG_find_column_index(plx_file_table_to_use,column_name);
end
settings=ph_get_preprocessing_settings(monkey_phys,'executed');
% % upper might interfere here, but we are not really using variable
% % inputs anyway at this stage
% for i = 1:2:length(varargin)
%     eval([upper(varargin{i}) '=varargin{i+1};']);
% end
if DISREGARDLFP
    DONTREAD=[DONTREAD, {'BROA','Broa','LFPx'}];
    DONTREAD=unique(DONTREAD);
end

dir_folder_with_session_days=dir(TDT_prefolder_dir); % dir
session_folders=[];
ctr=1;
for k=1: length(dir_folder_with_session_days)
    X=str2double(dir_folder_with_session_days(k).name);
    if ismember(X,dates) %X==dates(1) ||  ( X<=  dates(2) && X >  dates(1))
        session_folders{ctr}= dir_folder_with_session_days(k).name;
        ctr=ctr+1;
    end
end
for fol=1:numel(session_folders)
    date=session_folders{fol};
    date_num=str2num(date);
    block_folders              = dir([TDT_prefolder_dir date filesep 'Block-*']);
    block_folders              = block_folders([block_folders.isdir]);
    if ~isempty(blocks)
        for b=1:numel(blocks)
            blocks_string(b,:)={['Block-' num2str(blocks(b))]};
        end
    else
        blocks_string={block_folders.name}';
    end
    
    for i=1:numel(blocks_string);
        block = blocks_string{i};
        block_num=str2num(block(findstr(block,'-')+1:end));
        
        plx_file_idx=[false, [plx_file_table_to_use{2:end,idx.Date}]==date_num] & [false, [plx_file_table_to_use{2:end,idx.Block}]==block_num];
        if sum(plx_file_idx)>1
            disp('More than one sortcode entry, skipping')
            plx_file_idx=find(plx_file_idx,'first');
        end
        if ~any(plx_file_idx) || DISREGARDSPIKES % to make sure it also runs without associated plx files
            PLXVERSION='none';
            PLXEXTENSION='-00';
        else
            PLXVERSION=plx_file_table_to_use{plx_file_idx,idx.Sorttype};
            PLXEXTENSION=sprintf('-%02d',plx_file_table_to_use{plx_file_idx,idx.Plx_file_extension});
        end
        %% WC settings saved here as well, from ALL_preprocessing_logs history
        substruct=[PLXVERSION '_blocks_' num2str(block_num) '_sortcode_' PLXEXTENSION(2:end)];
        if isfield(settings,[monkey(1:3) '_' date]) && isfield(settings.([monkey(1:3) '_' date]),'WC_per_sortcode') ...
                && isfield(settings.([monkey(1:3) '_' date]).WC_per_sortcode, substruct)
            spike_settings=settings.([monkey(1:3) '_' date]).WC_per_sortcode.(substruct);
        else
            spike_settings=struct;
        end
        TDT_trial_struct_input      = {'SORTNAME',SORTNAME,'DONTREAD',DONTREAD,'EXCLUSIVELYREAD',EXCLUSIVELYREAD,'CHANNELS',CHANNELS,...
            'STREAMSWITHLIMITEDCHANNELS',STREAMSWITHLIMITEDCHANNELS,'PLXVERSION',PLXVERSION,'PLXEXTENSION',PLXEXTENSION,'DISREGARDLFP',DISREGARDLFP,'DISREGARDSPIKES',DISREGARDSPIKES};
        %TDT_trial_struct(base_path,[monkey '_phys'],date,block,spike_settings,TDT_trial_struct_input{:})
         TDT_trial_struct(handles,date,block,spike_settings,TDT_trial_struct_input{:})
       
        %% storing used sortcode information in plx table
        tmp_plx_file_table=plx_file_table_to_use(1,:);
        tmp_plx_file_table{2,idx.Monkey}=monkey(1:3);
        tmp_plx_file_table{2,idx.Date}=date_num;
        tmp_plx_file_table{2,idx.Block}=block_num;
        tmp_plx_file_table{2,idx.Sorttype}=PLXVERSION;
        tmp_plx_file_table{2,idx.Plx_file_extension}=PLXEXTENSION;
        tmp_plx_file_idx=[false, [plx_file_table_in_use{2:end,idx.Date}]==date_num] & [false, [plx_file_table_in_use{2:end,idx.Block}]==block_num];
        if DISREGARDSPIKES && any(plx_file_idx) 
            tmp_plx_file_table{2,idx.Sorttype}              =plx_file_table_in_use{tmp_plx_file_idx,idx.Sorttype};
            tmp_plx_file_table{2,idx.Plx_file_extension}    =plx_file_table_in_use{tmp_plx_file_idx,idx.Plx_file_extension};
        end
    end
    xlswrite([TDT_data_path date filesep monkey(1:3) '_plx_files.xlsx'],plx_file_table_to_use,'list_of_used_plx_files');
    
[plx_file_table_in_use]=DAG_update_cell_table(plx_file_table_in_use,tmp_plx_file_table,'Date');
xlswrite([DBfolder  monkey(1:3) '_plx_files.xlsx'],plx_file_table_in_use,'in_use');
end

if exist(Combined_data_path)~=7
    mkdir(base_path,[monkey '_phys_combined_monkeypsych_TDT'])
end
[filelist_complete_TDT, filelist_formatted_TDT, filelist_session_TDT]    = DAG_get_filelist_from_folder(TDT_data_path,dates);
[filelist_complete_MP, filelist_formatted_MP, filelist_session_MP]       = DAG_get_filelist_from_folder(MP_data_path,dates);
%% Here we are assuming that we will always have a task going for a block to make sense
% Well, we can not assign a trial structure if we don't have a task...!!
n_MP            = size(filelist_session_MP,1);
for l=1:n_MP
    matching_TDT_MP_session_runs(l)= any(strcmp(filelist_session_MP(l,1),filelist_session_TDT(:,1)) & strcmp(filelist_session_MP(l,2),filelist_session_TDT(:,2)));
end
folders_to_create=unique(filelist_session_MP(matching_TDT_MP_session_runs,1));
for idx_match   = 1:numel(folders_to_create)
    if ~exist([Combined_data_path folders_to_create{idx_match}],'dir')
    mkdir(Combined_data_path,folders_to_create{idx_match});
    end
end
folders_to_combine=unique(filelist_formatted_MP(matching_TDT_MP_session_runs));

for idx_c       = 1:numel(folders_to_combine)
    individual_day_folder_MP=folders_to_combine{idx_c};
    d_individual_day_folder=dir([individual_day_folder_MP filesep '*.mat']); % dir
    files_inside_session_folder={d_individual_day_folder.name}'; % files inside session folders
    for number_of_files = 1:length(files_inside_session_folder) % start looping within the session folder
        current_file=files_inside_session_folder{number_of_files};
        if exist([TDT_data_path filesep individual_day_folder_MP(end-7:end) filesep current_file(1:3) 'TDT' current_file(4:end)])~=0
            load([individual_day_folder_MP filesep current_file]);
            load([TDT_data_path filesep individual_day_folder_MP(end-7:end) filesep current_file(1:3) 'TDT' current_file(4:end)])
            if numel(trial)>numel(TDT_trial)
                TDT_trial(numel(trial)).trial=[]; %this adds all missing elements to TDT_trial, though fields will be empty
            end
            clear blocks
            for t = 1: numel(trial)
                if  ~isempty(TDT_trial(t).block)
                    blocks(t)=str2num(TDT_trial(t).block);
                else
                    blocks(t)=NaN;
                end
            end
            TDT_fieldnames=fieldnames(TDT_trial);
            u_blocks=unique(blocks(~isnan(blocks)));
            if numel(u_blocks)>1
                disp('there is more than one block in here...');
            end
            trial_tmp=trial;
            for block=u_blocks
                trial=trial_tmp;
                block_index=blocks==block;
                for idx_names = 1:numel(TDT_fieldnames)
                    temp_name=TDT_fieldnames(idx_names);
                    [trial(block_index).(['TDT_' temp_name{:}])]=TDT_trial(block_index).(temp_name{:});
                end
                current_file_path=[Combined_data_path  individual_day_folder_MP(end-7:end) filesep current_file(1:3) 'combined' current_file(4:end-4), '_block_', sprintf('%02d',block), '.mat'];
                disp(['saving ' current_file_path])
                save(current_file_path,'task','trial','preprocessing_settings','SETTINGS','First_trial_INI')
            end
        end
    end
end

function [filelist_complete, filelist_formatted, filelist_session] = DAG_get_filelist_from_folder(folder_with_session_days,dates)

dir_folder_with_session_days=dir(folder_with_session_days); % dir
session_folders=[];
ctr=1;
for k=1: length(dir_folder_with_session_days)
    X=str2double(dir_folder_with_session_days(k).name);
    if ismember(X,dates) %X==dates(1) ||  ( X<=  dates(2) && X >  dates(1))
        session_folders{ctr}= dir_folder_with_session_days(k).name;
        ctr=ctr+1;
    end
end

i_run=1;
for in_folders = 1:length(session_folders)
    individual_day_folder = [folder_with_session_days filesep session_folders{in_folders}]; % session of interest
    d_individual_day_folder=dir(individual_day_folder); % dir
    files_inside_session_folder={d_individual_day_folder.name}'; % files inside session folders
    for number_of_files = 1:length(files_inside_session_folder) % start looping within the session folder
        if length(files_inside_session_folder{number_of_files}) > 4 && strcmp(files_inside_session_folder{number_of_files}(end-3:end),'.mat')
            filelist_complete(i_run,:)=[individual_day_folder filesep files_inside_session_folder{number_of_files}];
            filesepindx=findstr(filelist_complete(i_run,:), filesep);
            filelist_formatted(i_run,:)= {filelist_complete(i_run,1:filesepindx(end)-1) str2double(filelist_complete(i_run,end-5:end-4))};
            filelist_session(i_run,:)= {filelist_complete(i_run,filesepindx(end-1)+1:filesepindx(end)-1) filelist_complete(i_run,end-5:end-4)};
            i_run=i_run+1;
        end
    end
end
