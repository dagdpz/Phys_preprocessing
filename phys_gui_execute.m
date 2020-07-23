function phys_gui_execute(handles)
%% save attempted action
save_internal(handles,'All_phys_preprocessing_log',handles.monkey_phys,'attempted_');


dates_to_loop=handles.dates;
TODO=handles.TODO;
%temp_block=num2cell(get(handles.listbox2,'String'));


%% transform checkbox tags to fieldnames
todo_fn=fieldnames(TODO);
PLX_creation_fn=todo_fn(cellfun(@(x) ~isempty(strfind(x,'PLXFrom')),todo_fn));
for ck=1:numel(PLX_creation_fn)
    PLX_creation{ck,1}=PLX_creation_fn{ck};
    PLX_creation{ck,2}=TODO.(PLX_creation_fn{ck});
end

%% TODO
if TODO.SynapseTankToOldFormat
    if numel(dates_to_loop)>1
        temp_date_range = [min(dates_to_loop) max(dates_to_loop)];
    else
        temp_date_range = dates_to_loop;
    end
    dates_to_loop = DAG_rename_TDT_tank(handles.drive,handles.monkey_phys,temp_date_range);
end

% TODO.TDTSnippetsSortcodeFromPLX ?

if any([PLX_creation{:,2}]) || TODO.WCFromBB
    tank_path = [handles.drive];
    for i=1:numel(dates_to_loop)
        clear tank_b_names
        temp_block = [];
        tank_path_pre = [handles.drive 'Data' filesep 'TDTtanks' filesep handles.monkey_phys filesep num2str(dates_to_loop(i)) filesep temp_block];
        sortcode_path_pre = [handles.drive 'Data' filesep 'Sortcodes' filesep handles.monkey_phys filesep num2str(dates_to_loop(i)) filesep temp_block];
        tank_dir=dir(tank_path_pre);
        jj=1;
        for j=1:size(tank_dir,1)
            if findstr(tank_dir(j).name, 'Block') == 1
                tank_b_names{:,jj}=tank_dir(j).name;
                jj=jj+1;
            end
        end
        
        if TODO.WCFromBB
            DAG_WC3_preprocessing(dates_to_loop(i),tank_b_names,handles)
        end
        PLX_versions_to_create=find([PLX_creation{:,2}]);
        for v=PLX_versions_to_create
            plx_extension=ph_get_new_plx_extension(sortcode_path_pre,PLX_creation{v,1});
            handles.plx_version_per_block.([handles.monkey_phys(1:3) '_' num2str(dates_to_loop(i))])=plx_extension;
            DAG_create_PLX(dates_to_loop(i),handles.monkey_phys,tank_b_names,PLX_creation{v,1})
        end
    end
end


if TODO.Assign_WC_waveforms_to_PLX
    % Kind of complicated scripting for just looping through all selected
    % sessions/blocks, but this is only temporary anyway
    TDT_prefolder_dir           = [handles.drive 'Data' filesep 'Sortcodes' filesep handles.monkey_phys];
    
    dir_folder_with_session_days=dir(TDT_prefolder_dir); % dir
    session_folders=[];
    ctr=1;
    for k=1: length(dir_folder_with_session_days)
        X=str2double(dir_folder_with_session_days(k).name);
        if ismember(X,dates_to_loop) %X==dates(1) ||  ( X<=  dates(2) && X >  dates(1))
            session_folders{ctr}= dir_folder_with_session_days(k).name;
            ctr=ctr+1;
        end
    end
    for fol=1:numel(session_folders)
        date=session_folders{fol};
        block_folders              = dir([TDT_prefolder_dir filesep date filesep 'Block-*']);
        block_folders              = block_folders([block_folders.isdir]);
        if ~isempty(temp_block)
            for b=1:numel(temp_block)
                blocks_string(b,:)={['Block-' num2str(blocks(b))]};
            end
        else
            blocks_string={block_folders.name}';
        end
        for i=1:numel(blocks_string);
            block = blocks_string{i};
            block = block(strfind(block,'-')+1:end);
            waveform_PLX_file=[TDT_prefolder_dir filesep date filesep date '_from_BB_' 'blocks_' block '.plx'];
            sortcode_PLX_file=[TDT_prefolder_dir filesep date filesep date '_from_BB_' 'blocks_' block '-01' '.plx'];
            DAG_take_over_waveforms_PLX2PLX(waveform_PLX_file,sortcode_PLX_file)
        end
    end
end

if  TODO.UpdateSortcodeExcel % Combine
    DAG_update_plx_file_table(dates_to_loop,handles) 
end

if  TODO.CombineTDTandMP % Combine
    temp_block=[];
    if isempty(temp_block)
        temp_block=[];
    else
        temp_block= str2num(cell2mat(temp_block));
    end
    %handles.TDT.PLXVERSION=get(get(handles.uipanel11,'SelectedObject'),'String');
    ph_combine_MP_and_TDT_data(handles,dates_to_loop,temp_block); %,'PLXVERSION',PLXVERSION,'DISREGARDLFP',TODO.DisregardLFP,'DISREGARDSPIKES',TODO.DisregardSpikes)
    %handles.plx_table_sheet='list_of_used_plx_files';
    %DAG_update_plx_file_table(dates_to_loop,handles)
end
if  TODO.CreateExcelEntries % Sorting excel table update
    DAG_update_sorting_table(handles.monkey_phys,dates_to_loop);
end

%% save executed action ... where? -> dependent on TODO? Shouldnt safe in combined files folders! (monkey folders - combined/protocol/executed_2020102
save_internal(handles,'All_phys_preprocessing_log',handles.monkey_phys,'executed_');
end

function save_internal(handles,folder,subfolder,executed)

if ~exist([handles.drive  'Data' filesep folder  filesep ],'dir')
    mkdir([handles.drive  'Data' filesep,folder]);
end

if ~exist([handles.drive  'Data' filesep folder filesep subfolder filesep],'dir')
    mkdir([handles.drive  'Data' filesep folder filesep ,subfolder]);
end
path=[handles.drive  'Data' filesep folder  filesep subfolder filesep];

    handles=DAG_rmobjects_from_struct(handles);
save([path executed '_' datestr(clock,'YYYYmmDD-HHMM')],'handles');
%% save executed action ... where? -> dependent on TODO? Shouldnt safe in combined files folders! (monkey folders - combined/protocol/executed_2020102
a=1;
end
