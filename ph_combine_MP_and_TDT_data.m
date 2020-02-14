function ph_combine_MP_and_TDT_data(drive,monkey,dates,blocks,varargin)

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

DONTREAD                    = {'pNeu','LED1','trig'}; %priority over ExclusivelyRead % 'BROA','Broa' (add these if you want to use online filtered LFP)
EXCLUSIVELYREAD             = {}; %(empty read everything)
CHANNELS                    = 1:48; %filter for signals
STREAMSWITHLIMITEDCHANNELS  = {'LFPx','Broa','BROA','pNeu'}; %filtered signals (only the part of the signal in the channel defined as filter will be read)
SORTNAME                    = 'Plexsormanually';
DISREGARDLFP                = 0;
PLXVERSION                  = ''; % plexon file version used, overwrites other sort codes.
% Options: 'none': all sortcodes are 0 ''
% 'Snippets': taking sortcodes from SORTNAME,i.e. 'Plexsormanually';
% 'realigned': taking sortcodes from realigned (and potentially re-sorted) PLX file
% (needs to have extension '-01', if not existing it takes SORTNAME)
% 'from_BB': taking sortcodes from broadband PLX file
% (needs to have extension '-01', if not existing it takes SORTNAME)


user                        = getUserName;
disp(['Drive= ', drive, ' User= ', user, ' Monkey= ', monkey]);

base_path                   = [drive 'Data\']; % [drive ':\Data\'];
TDT_prefolder_dir           = [base_path 'TDTtanks' filesep monkey '_phys'];
Combined_data_path          = strcat(base_path,[monkey '_phys_combined_monkeypsych_TDT']);
TDT_data_path               = strcat(base_path ,monkey, '_phys_mat_from_TDT');
MP_data_path                = strcat(base_path ,monkey);

% upper might interfere here, but we are not really using variable
% inputs anyway at this stage
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end
if DISREGARDLFP
    DONTREAD=[DONTREAD, {'BROA','Broa','LFPx'}];
    DONTREAD=unique(DONTREAD);
end
TDT_trial_struct_input      = {'SORTNAME',SORTNAME,'DONTREAD',DONTREAD,'EXCLUSIVELYREAD',EXCLUSIVELYREAD,'CHANNELS',CHANNELS,...
    'STREAMSWITHLIMITEDCHANNELS',STREAMSWITHLIMITEDCHANNELS,'PLXVERSION',PLXVERSION,'DISREGARDLFP',DISREGARDLFP};

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
    block_folders              = dir([base_path 'TDTtanks' filesep monkey '_phys' filesep date filesep 'Block-*']);
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
        TDT_trial_struct_working(base_path,[monkey '_phys'],date,block,TDT_trial_struct_input{:})
    end
end

if exist(Combined_data_path)~=7
    mkdir(base_path,[monkey '_phys_combined_monkeypsych_TDT'])
end
[filelist_complete_TDT, filelist_formatted_TDT, filelist_session_TDT]    = get_filelist_from_folder(TDT_data_path,dates);
[filelist_complete_MP, filelist_formatted_MP, filelist_session_MP]       = get_filelist_from_folder(MP_data_path,dates);
%% Here we are assuming that we will always have a task going for a block to make sense
% Well, we can not assign a trial structure if we don't have a task...!!
n_MP            = size(filelist_session_MP,1);
for l=1:n_MP
    matching_TDT_MP_session_runs(l)= any(strcmp(filelist_session_MP(l,1),filelist_session_TDT(:,1)) & strcmp(filelist_session_MP(l,2),filelist_session_TDT(:,2)));
end
folders_to_create=unique(filelist_session_MP(matching_TDT_MP_session_runs,1));
for idx_match   = 1:numel(folders_to_create)
    mkdir([base_path, monkey '_phys_combined_monkeypsych_TDT'],folders_to_create{idx_match});
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
                folder_to_save_to=[base_path, monkey '_phys_combined_monkeypsych_TDT' filesep  individual_day_folder_MP(end-7:end) ];
                disp(['saving ' folder_to_save_to filesep current_file(1:3) 'combined' current_file(4:end-4), '_block_', sprintf('%02d',block), '.mat'])
                save([folder_to_save_to filesep current_file(1:3) 'combined' current_file(4:end-4), '_block_', sprintf('%02d',block), '.mat'],'task','trial','SETTINGS','First_trial_INI')
            end
        end
    end
end

function [filelist_complete, filelist_formatted, filelist_session] = get_filelist_from_folder(folder_with_session_days,dates)

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
