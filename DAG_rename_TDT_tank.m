function out_date_range = DAG_rename_TDT_tank(drive,monkey,temp_date_range)
% restructures and renames folder formats of physiology data recorded with
% Synapse (New TDT software since 2017, first introduced in setup 3 only).

Main_path = [drive ':' filesep 'Data' filesep 'TDTtanks' filesep monkey ];

folders=dir(Main_path);
foldernames={folders(cellfun(@numel, {folders.name})>8).name};
for k=1:size(foldernames,2)
    ft(1,k)=str2num(foldernames{k}(end-12:end-7));
end
foldernames=foldernames(ismember(ft,temp_date_range));
out_date_range = str2num([repmat('20',size(temp_date_range,2),1), num2str(temp_date_range')]);
for FN=1:numel(foldernames)
    rename_files([Main_path filesep foldernames{FN}]);
end
end


function rename_files(Tank_path)
% rename_files('X:\Data\TDTtanks\Cornelius_phys\Cornz-160506-110358 - Copy')

Tank_folder = dir(Tank_path);
Tank_folder = Tank_folder([Tank_folder.isdir]);
Blocks = {Tank_folder.name};
Blocks(strncmp(Blocks, '.', 1)) = [];
for iBlock = 1:numel(Blocks)
    Block_path   = fullfile(Tank_path, Blocks{iBlock});
    Block_files    = dir(fullfile(Block_path));
    Files = {Block_files.name};
    Files(strncmp(Files, '.', 1)) = [];
    new_block_name = ['Block-' num2str(iBlock)];
    for iFile = 1:numel(Files)
        if ~isempty(strfind(Files{iFile},'Block'))
            continue
        end
        Files = strrep(Files, 'BROA', 'Broa');
        k = strfind(Files{iFile},'-') ;
        if ~isempty(k)
            current_date=['20' Files{iFile}(k(1)+1:(k(2)-1))];
            current_file_name{iFile}=[current_date '_' new_block_name Files{iFile}(k(3)+7:end)];
            movefile([Block_path filesep Files{iFile}], fullfile(Block_path, filesep, current_file_name{iFile}),'f');
        end
    end
    movefile(Block_path, fullfile(Tank_path, new_block_name),'f');
end
kt=strfind(Tank_path,'phys\') ;
movefile(Tank_path, fullfile(Tank_path(1:kt+4), current_date));
end