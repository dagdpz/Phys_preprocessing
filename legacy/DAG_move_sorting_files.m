function success=DAG_move_sorting_files(old_location,new_location,deleteorigin,folders_to_not_move,fileparts_to_not_move)
% This code was used to move Sortcodes to Y:\Data\Sortcodes and should not be needed any more
% f.e.:
% new_location='Y:\Data\TDTtanks\Flaffus_phys\20160722\';
% old_location='Y:\Data\Sortcodes\Flaffus_phys\20160722\';
if nargin<3
    deleteorigin=0;
end
if nargin<4
    folders_to_not_move={'Block-'};
end
if nargin<5
    fileparts_to_not_move={'desktop.ini'};
end
success=1;

%% create folders if not existent
filesep_idx=strfind(new_location,filesep);
for idx=2:numel(filesep_idx)
    if ~exist(new_location(1:filesep_idx(idx)),'dir');
        mkdir(new_location(1:filesep_idx(idx-1)),new_location(filesep_idx(idx-1)+1:filesep_idx(idx)-1));
    end
end

D=dir(old_location);
if numel(D)<3
    if deleteorigin
        rmdir(old_location);
    end
    return
end
D=D(3:end);
D_dirs=D([D.isdir]);
D_files=D(~[D.isdir]);

%% copy/move directories
if ~isempty(D_dirs)
    found_not_to_move_files_in_position=zeros(1,numel(D_dirs));
    for idx=1:numel(folders_to_not_move)
        temp=strfind({D_dirs.name},folders_to_not_move{idx});
        temp(cellfun(@isempty,temp))={0}; % to remove empties
        found_not_to_move_files_in_position(idx,:)=cell2mat(temp);
    end
    to_move_idx=~any(found_not_to_move_files_in_position==1,1);
    D_dirs=D_dirs(to_move_idx);
    
    for d=1:numel(D_dirs)
        copy_folder_successful(d)=DAG_move_sorting_files([old_location D_dirs(d).name filesep],[new_location D_dirs(d).name filesep],deleteorigin,folders_to_not_move,fileparts_to_not_move);
    end
    if any(~to_move_idx) || any(~copy_folder_successful) %% keep main folder if subfolders are kept
        success=0;
    end
end

%% copy/move_files
if ~isempty(D_files)
    found_not_to_move_files_in_position=zeros(numel(fileparts_to_not_move),numel(D_files));
    for idx=1:numel(fileparts_to_not_move)
        temp=strfind({D_files.name},fileparts_to_not_move{idx});
        temp(cellfun(@isempty,temp))={0}; % to remove empties
        found_not_to_move_files_in_position(idx,:)=cell2mat(temp);
    end
    to_move_idx=~any(found_not_to_move_files_in_position,1);
    if any(~to_move_idx) %% keep main folder if any file inside is kept
        success=0;
    end
    
    D_files=D_files(to_move_idx);
    for d=1:numel(D_files)        
        copy_file_successful = copyfile([old_location D_files(d).name],[new_location D_files(d).name]);
        if copy_file_successful && deleteorigin
            delete([old_location D_files(d).name]);
        else
            success=0; %% keep main folder if any copy process was not successful
        end
    end
end

%% delete origin if successful
if success && deleteorigin
    rmdir(old_location);
end
end