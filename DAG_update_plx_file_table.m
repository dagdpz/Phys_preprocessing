function DAG_update_plx_file_table(dates,handles)
% This function is used to automatically update the plx file table
% INPUT: 
% dates is a cell array of sessions to be updated; f.e.: dates={'20160608','20160609'}
% handles is a structure containing (at least) the following fields:
% handles.monkey_phys:                  
%           monkey name with 'phys' affix, f.e.: 'Flaffus_phys'
% handles.preferred_SortType:           
%           Preferred type of sorting (will be taken if present) 
%           Possible values: 'Snippets','from_BB','realigned','none'
% handles.preferred_Plx_file_extension: 
%           if several (-01,-02,-03) versions are present, preference will be given to
%           a) 'first'      : the lowest number
%           b) 'last'       : the highest number
%           c) 'latest'     : the latest created version

monkey=handles.monkey_phys;
if nargin<2
    handles.preferred_SortType='Snippets';
    handles.preferred_Plx_file_extension='first';
end
dag_drive=DAG_get_server_IP;

main_folder=[dag_drive 'Data' filesep 'Sortcodes' filesep monkey filesep];
main_folder_content=dir(main_folder);
main_folder_content=main_folder_content([main_folder_content.isdir]);
main_folder_content(1:2)=[];
subfolders={main_folder_content.name};
if nargin>=2
    subfolders=subfolders(cellfun(@(x) ismember(str2double(x),dates),subfolders));
end

DBpath=DAG_get_Dropbox_path;
DBfolder=[DBpath filesep 'DAG' filesep 'phys' filesep monkey '_dpz' filesep];
sheets_available={};
if exist([DBfolder  monkey(1:3) '_plx_files.xlsx'],'file')
    [~, sheets_available]=xlsfinfo([DBfolder  monkey(1:3) '_plx_files.xlsx']);
end
if ismember('to_use',sheets_available)
    [~, ~, plx_file_table]=xlsread([DBfolder  monkey(1:3) '_plx_files.xlsx'],'to_use');
else
    plx_file_table={'Monkey','Date','Block','Sorttype','Plx_file_extension'};
end
old_table=plx_file_table;
dateindex_old=DAG_find_column_index(old_table,'Date');
if ~isempty(dateindex_old)
    dates_old=[old_table{2:end,dateindex_old}];
    unique_old_dates=unique(dates_old);
else
    unique_old_dates=[];
end
plx_file_table=plx_file_table(1,:);

for c=1:size(plx_file_table,2)
    column_name = strrep(plx_file_table{1,c},' ','_');
    column_name = strrep(column_name,'?','');
    plx_file_table{1,c}=column_name;
    idx.(column_name)=DAG_find_column_index(plx_file_table,column_name);
end

n_row=1;
new_sessions_counter=0;
for s =1:numel(subfolders)
    date=subfolders{s};
    session=str2double(date);
    if ~ismember(session,unique_old_dates)
        new_sessions_counter=new_sessions_counter+1;
    end
    plxfiles=dir([main_folder date filesep '*.plx']);
    plxfiledates=[plxfiles.datenum];
    plxfiles={plxfiles.name};
    
    %% take only plx files with a hyphen in their name
    clear file_valid
    file_valid=logical([]);
    for f=1:numel(plxfiles)
        hyphenidx=strfind(plxfiles{f},'-');
        if any(hyphenidx)
            file_valid(f)=true;
        else
            file_valid(f)=false;
        end
    end
    plxfiledates=plxfiledates(file_valid);
    plxfiles=plxfiles(file_valid);
    
    %% find corresponding block for each plx file
    clear blocks
    blocks=[];
    for f=1:numel(plxfiles)
        startidx=strfind(plxfiles{f},'blocks_')+7;
        hyphenidx=strfind(plxfiles{f}(startidx:end),'-');
        endidx=numel(plxfiles{f})-7;
        blocks(f)=str2num(plxfiles{f}(startidx:endidx));
    end
    
    %% find corresponding block for each plx file
    for b=unique(blocks)
        blockfiles=plxfiles(blocks==b);
        blockdates=plxfiledates(blocks==b);
        
        %% select which is the desired plxfile
        issnippet       = cellfun(@(x) ~isempty(strfind(x,[date '_blocks'])),blockfiles);
        is_WC           = cellfun(@(x) ~isempty(strfind(x,[date '_from_BB_blocks'])),blockfiles);
        is_realigned    = cellfun(@(x) ~isempty(strfind(x,[date '_realigned_blocks'])),blockfiles);
        
        %% only include preferred SortType if present
        if strcmp(handles.preferred_SortType,'Snippets') && any(issnippet)
            blockfiles=blockfiles(issnippet);
            blockdates=blockdates(issnippet);
        elseif strcmp(handles.preferred_SortType,'realigned') && any(is_realigned)
            blockfiles=blockfiles(is_realigned);
            blockdates=blockdates(is_realigned);
        elseif strcmp(handles.preferred_SortType,'from_BB') && any(is_WC)
            blockfiles=blockfiles(is_WC);
            blockdates=blockdates(is_WC);
        end
        
        %% check file extension (-01 f.e.)
        clear block_plx_extensions
        for f=1:numel(blockfiles)
            block_plx_extensions(f)=str2num(blockfiles{f}(end-5:end-4));
        end
        
        %% selected desired extension
        if strcmp(handles.preferred_Plx_file_extension,'first')
            [~,x]=min(block_plx_extensions);
        elseif strcmp(handles.preferred_Plx_file_extension,'last')
            [~,x]=max(block_plx_extensions);
        elseif strcmp(handles.preferred_Plx_file_extension,'latest')
            [~,x]=max(blockdates);
        end
        
        %% this is your selected plx file
        selected_file=blockfiles{x};
        
        %% Now check whats the corresponding SortType and extension
        issnippet       = ~isempty(strfind(selected_file,[date '_blocks']));
        is_WC           = ~isempty(strfind(selected_file,[date '_from_BB_blocks']));
        is_realigned    = ~isempty(strfind(selected_file,[date '_realigned_blocks']));
        
        if issnippet
            Sorttype='Snippets';
        elseif is_realigned
            Sorttype='realigned';
        elseif is_WC
            Sorttype='from_BB';
        end
        
        Plx_file_extension=selected_file(end-5:end-4);
        
        %% add info to table
        n_row=n_row+1;
        plx_file_table{n_row,idx.Monkey}=monkey(1:3);
        plx_file_table{n_row,idx.Date}=str2num(date);
        plx_file_table{n_row,idx.Block}=b;
        plx_file_table{n_row,idx.Sorttype}=Sorttype;
        plx_file_table{n_row,idx.Plx_file_extension}=Plx_file_extension;
    end
end

[complete_mastertable]=DAG_update_cell_table(old_table,plx_file_table,'Date');
xlswrite([DBfolder filesep monkey(1:3) '_plx_files.xlsx'],complete_mastertable,'to_use');
end

