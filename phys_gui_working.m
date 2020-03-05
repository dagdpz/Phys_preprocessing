function phys_gui_working(varargin)

% Last Modified by GUIDE v2.5 27-Feb-2020 15:52:57
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @phys_gui_working_OpeningFcn, ...
    'gui_OutputFcn',  @phys_gui_working_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function phys_gui_working_OpeningFcn(hObject, eventdata, handles, varargin)
%% here we set 'globals'.. need to be as handles and every time they are modified we need to call guidata(hObject, handles)
handles.output = hObject;
handles.user = getUserName;
handles.drive = DAG_get_server_IP;
handles.monkey = '';

guidata(hObject, handles);

function varargout = phys_gui_working_OutputFcn(hObject, eventdata, handles)

% DAFAULT values
varargout{1} = handles.output;
set(handles.checkbox1,'Value',0);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);
set(handles.checkbox6,'Value',0);
set(handles.checkbox6,'Value',0);
set(handles.checkbox5,'Value',0);
set(handles.checkbox7,'Value',0);
set(handles.checkbox8,'Value',0);
set(handles.checkbox9,'Value',0);
set(handles.checkbox91,'Value',0);
set(handles.checkbox92,'Value',0);
set(handles.checkbox10,'Value',0);
set(handles.checkbox101,'Value',0);
set(handles.checkbox102,'Value',0);
set(handles.checkbox103,'Value',0);

function Physio_GUI_V_Blumenkohl_Raspberry_CreateFcn(hObject, eventdata, handles)
ha = axes('units','normalized', ...
    'position',[0 0 1 1]);
uistack(ha,'bottom');
I=imread('bb_m.jpg');
hi = imagesc(I);
colormap gray
set(ha,'handlevisibility','off', 'visible','off')




%% Postprocessing
function pushbutton21_Callback(hObject, eventdata, handles)
[handles.fout handles.project handles.version handles.exit handles.guihandle]= PGUI_set_postprocessing_parameters();
%handles.fout=out;
guidata(hObject, handles);
if ischar(handles.fout)
    %     temp.drive=get(handles.edit8,'String');
    %     temp.monkey=[get(handles.text1,'String') '_phys'];
    temp.date=get(handles.listbox1,'String');
    temp.date= str2num(cell2mat(temp.date));
    temp.date=sort(temp.date);
    temp.block=get(handles.listbox2,'String');
    
    for i=1:numel(temp.date)
        if isempty(temp.block)
            %             tank_path_pre = [temp.drive ':' filesep 'Data' filesep 'TDTtanks' filesep temp.monkey filesep num2str(temp.date(i)) filesep temp.block];
            tank_path_pre = [handles.drive 'Data' filesep [handles.monkey_phys '_combined_monkeypsych_TDT'] filesep num2str(temp.date(i)) filesep];
            temp.block = [];
            combined_dir=dir(tank_path_pre);
            jj=1;
            for j=1:size(combined_dir,1)
                if findstr(combined_dir(j).name, 'block_') == 26
                    combined_files{:,jj}=combined_dir(j).name;
                    jj=jj+1;
                end
            end
        else
            %             tank_path_pre = [temp.drive ':' filesep 'Data' filesep 'TDTtanks' filesep temp.monkey filesep num2str(temp.date(i)) filesep ];
            tank_path_pre = [handles.drive 'Data' filesep [handles.monkey_phys '_combined_monkeypsych_TDT'] filesep num2str(temp.date(i)) filesep];
            combined_dir=dir(tank_path_pre);
            jj=1;
            for j=1:size(combined_dir,1)
                for hh=1:size(temp.block,1)
                    if ~isempty(temp.block{hh}) & findstr(combined_dir(j).name, ['block_' sprintf('%02d', str2num(temp.block{hh}))]) == 26
                        combined_files{:,jj}=combined_dir(j).name;
                        jj=jj+1;
                    end
                end
            end
        end
        Key   = '_block_';
        for hh=1:length(combined_files)
            bl_i = strfind(combined_files{hh}, Key);
            to_use_bl(hh,:) = str2num(combined_files{hh}(bl_i(1)+length(Key):end-4));
            to_use_ru(hh,:) = str2num(combined_files{hh}(bl_i(1)-2:end-13));
        end
        
        temp_date=repmat(temp.date(i),length(to_use_ru),1);
        temp_list{i}=[temp_date to_use_ru];
    end
    filekeys=num2cell(vertcat(temp_list{:}));
    
    %% writing to m-file
    filesep_idx=strfind(handles.fout,filesep);
    mon=handles.monkey;
    
    fid = fopen([handles.fout(1:filesep_idx(end)) 'ph_additional_settings.m'],'w');
    fprintf(fid,['keys.' mon '.filelist_formatted={... \n']);
    for f=1:size(filekeys,1)-1
        to_write=[num2str(filekeys{f,1}) ', ' num2str(filekeys{f,2}) ';... \n'];
        fprintf(fid, to_write);
    end
    to_write=[num2str(filekeys{end,1}) ', ' num2str(filekeys{end,2}) '}; \n'];
    fprintf(fid, to_write);
    fclose(fid);
end

function pushbutton22_Callback(hObject, eventdata, handles)
Button_run = hObject; % Get the caller's handle.
col_button = get(Button_run,'backg');  % Get the background color of the figure.
set(Button_run,'str','RUNNING...','backg',[1 .6 .6]) % Change color of button.

pause(.01)  % FLUSH the event queue, drawnow would work too.
% temp_date=get(handles.listbox1,'String');
% temp_date= str2num(cell2mat(temp_date));
% temp_date=sort(temp_date);
% temp_block=get(handles.listbox2,'String');

%if get(handles.checkbox101,'Value')
ph_initiation(handles.project,{handles.version},1);
%end

%% Execute button - all the action happens here
function pushbutton1_Callback(hObject, eventdata, handles)
%global cb1 cb2 cb3 cb4 cb5 cb6
Button_run = hObject; % Get the caller's handle.
col_button = get(Button_run,'backg');  % Get the background color of the figure.
set(Button_run,'str','RUNNING...','backg',[1 .6 .6]) % Change color of button.
pause(.01)  % FLUSH the event queue, drawnow would work too.
temp_date=get(handles.listbox1,'String');
temp_date= str2num(cell2mat(temp_date));
temp_date=sort(temp_date);
%temp_block=num2cell(get(handles.listbox2,'String'));

%% transform checkbox tags to fieldnames
handle_fn=fieldnames(handles);
to_check=handle_fn(cellfun(@(x) ~isempty(strfind(x,'checkbox')),handle_fn));
for ck=1:numel(to_check)
    val=get(handles.(to_check{ck}),'Value');
    fn=get(handles.(to_check{ck}),'String');
    fn=strrep(fn,' ','_');
    TODO.(fn)= val;
end
%% transform checkbox tags to fieldnames
todo_fn=fieldnames(TODO);
PLX_creation_fn=todo_fn(cellfun(@(x) ~isempty(strfind(x,'PLXFrom')),todo_fn));
for ck=1:numel(PLX_creation_fn)
    PLX_creation{ck,1}=PLX_creation_fn{ck};
    PLX_creation{ck,2}=TODO.(PLX_creation_fn{ck});
end

%% TODO
if TODO.SynapseTankToOldFormat
    if numel(temp_date)>1
        temp_date_range = [min(temp_date) max(temp_date)];
    else
        temp_date_range = temp_date;
    end
    temp_date = DAG_rename_TDT_tank(handles.drive,handles.monkey_phys,temp_date_range);
end



% TODO.TDTSnippetsSortcodeFromPLX ?


if any([PLX_creation{:,2}]) || TODO.WCFromBB
    tank_path = [handles.drive];
    for i=1:numel(temp_date)
        clear tank_b_names
%         if isempty(temp_block)
            temp_block = [];
            tank_path_pre = [handles.drive 'Data' filesep 'TDTtanks' filesep handles.monkey_phys filesep num2str(temp_date(i)) filesep temp_block];
            tank_dir=dir(tank_path_pre);
            jj=1;
            for j=1:size(tank_dir,1)
                if findstr(tank_dir(j).name, 'Block') == 1
                    tank_b_names{:,jj}=tank_dir(j).name;
                    jj=jj+1;
                end
            end
% %         else
%             
%             tank_path_pre = [handles.drive 'Data' filesep 'TDTtanks' filesep handles.monkey_phys filesep num2str(temp_date(i)) filesep ];
%             tank_dir=dir(tank_path_pre);
%             jj=1;
%             for j=1:size(tank_dir,1)
%                 for hh=1:size(temp_block,1)
%                     if ~isempty(temp_block{hh}) && findstr(tank_dir(j).name, ['Block-' num2str(temp_block{hh})]) == 1
%                         tank_b_names{:,jj}=tank_dir(j).name;
%                         jj=jj+1;
%                     end
%                 end
%             end
%             
%         %end
        
        if TODO.WCFromBB
            
            handles.threshold =get(handles.edit10,'String');
            handles.par.StdThrSU = str2double(get(handles.edit11,'String'));
            handles.par.StdThrMU = str2double(get(handles.edit20,'String'));
            handles.hp =get(handles.edit12,'String');
            handles.hpcutoff =str2double(get(handles.edit13,'String'));
            handles.lpcutoff =str2double(get(handles.edit14,'String'));
            handles.cell_tracking_distance_limit=str2double(get(handles.edit15,'String'));
            handles.remove_ini=str2double(get(handles.edit16,'String'));
            
            
            DAG_WC3_preprocessing(temp_date(i),tank_b_names,handles)
        end
        
        PLX_versions_to_create=find([PLX_creation{:,2}]);
        for v=PLX_versions_to_create
            DAG_create_PLX(temp_date(i),handles.monkey_phys,tank_b_names,PLX_creation{v,1})
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
        if ismember(X,temp_date) %X==dates(1) ||  ( X<=  dates(2) && X >  dates(1))
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
    options.preferred_SortType=get(get(handles.uipanel10,'SelectedObject'),'String');
    options.preferred_Plx_file_extension=get(get(handles.uipanel11,'SelectedObject'),'String');
    DAG_update_plx_file_table(handles.monkey_phys,temp_date,options)
end

if  TODO.CombineTDTandMP % Combine
    temp_block=[];
    if isempty(temp_block)
        temp_block=[];
    else
        temp_block= str2num(cell2mat(temp_block));
    end
    %     if numel(temp_date)>1
    %         temp_date_range = [min(temp_date) max(temp_date)];
    %     else
    %         temp_date_range = temp_date;
    %     end
    PLXVERSION=get(get(handles.uipanel11,'SelectedObject'),'String');
    ph_combine_MP_and_TDT_data(handles.drive,handles.monkey,temp_date,temp_block,'PLXVERSION',PLXVERSION,'DISREGARDLFP',TODO.DisregardLFP)
end
if  TODO.CreateExcelEntries % Sorting excel table update
    DAG_update_sorting_table(handles.monkey,temp_date);
end
set(Button_run,'str','RUN','backg',col_button)  % Now reset the button features.

%% Checkboxes

function checkbox1_CreateFcn(hObject, eventdata, handles)
function checkbox2_CreateFcn(hObject, eventdata, handles)
function checkbox3_CreateFcn(hObject, eventdata, handles)
function checkbox4_CreateFcn(hObject, eventdata, handles)
function checkbox5_CreateFcn(hObject, eventdata, handles)
function checkbox6_CreateFcn(hObject, eventdata, handles)
function checkbox7_CreateFcn(hObject, eventdata, handles)
function checkbox8_CreateFcn(hObject, eventdata, handles)
function checkbox9_CreateFcn(hObject, eventdata, handles)
function checkbox91_CreateFcn(hObject, eventdata, handles)
function checkbox92_CreateFcn(hObject, eventdata, handles)
function checkbox10_CreateFcn(hObject, eventdata, handles)
function checkbox101_CreateFcn(hObject, eventdata, handles)
function checkbox102_CreateFcn(hObject, eventdata, handles)
function checkbox103_CreateFcn(hObject, eventdata, handles)

% Reformat Synapse
function checkbox1_Callback(hObject, eventdata, handles)
update_notes('Reformatting elected Synapse tank folder (Setup 3) to match to structure of Setup 1 and 2',get(hObject,'Value'),handles,1);

% PLXFromBB
function checkbox2_Callback(hObject, eventdata, handles)
update_notes('Create WaveClus pre-clustering from broadband data',get(hObject,'Value'),handles,2);

% PLXfromTDT
function checkbox3_Callback(hObject, eventdata, handles)
update_notes('Create plx file (without extension) from waveclus',get(hObject,'Value'),handles,3);

% TDTfromPLX
function checkbox4_Callback(hObject, eventdata, handles)
update_notes('Create plx file (without extension) from Snippets',get(hObject,'Value'),handles,4);

% Realign Snippets
function checkbox5_Callback(hObject, eventdata, handles)
update_notes('Create plx file (without extension) from realigned Snippets',get(hObject,'Value'),handles,5);


function checkbox6_Callback(hObject, eventdata, handles)
update_notes('Assign waveforms from from_BB.plx to "from_BB-01.plx"',get(hObject,'Value'),handles,6);

function checkbox7_Callback(hObject, eventdata, handles)
update_notes('??',get(hObject,'Value'),handles,7);

function checkbox8_Callback(hObject, eventdata, handles)
update_notes('Update sortcode table for selected sessions',get(hObject,'Value'),handles,8);

% Combine
function checkbox9_Callback(hObject, eventdata, handles)
update_notes('Create combined mat file for postprocessing',get(hObject,'Value'),handles,9);

function checkbox91_Callback(hObject, eventdata, handles)
update_notes('Keep LFP that is stored in the combined mat files',get(hObject,'Value'),handles,10);

function checkbox92_Callback(hObject, eventdata, handles)
update_notes('Keep Spikes that are stored in the combined mat files ',get(hObject,'Value'),handles,11);

function checkbox10_Callback(hObject, eventdata, handles)
update_notes('Update sorting table for selected sessions',get(hObject,'Value'),handles,12);



function update_notes(string,addorremove,handles,n)
current_string_o=get(handles.text22,'String');
current_string=cellstr(current_string_o);
tags=get(handles.text22,'tag');
% if ischar(tags) && strcmp(tags,'text22')
%    tags=''; 
% end
if isempty(current_string_o);
    current_string={string};
    tags=num2str(n); 
    tags_num=n;
else
    instringposition=ismember(current_string,string);
    if addorremove
        %         current_string={string};
        %         tags=num2str(n);
        %     else
        tags=[tags '  ' num2str(n)];
        current_string=[current_string; string];
        tags_num=str2num(tags);
    elseif any(instringposition)
        current_string(instringposition)=[];
        tags_num=str2num(tags);
        tags_num(instringposition)=[];
    end
end
[tags_num, tag_idx]=sort(tags_num);
current_string=current_string(tag_idx);
tags=num2str(tags_num);

set(handles.text22,'String',current_string);
set(handles.text22,'tag',tags);



% outputs only
function checkbox101_Callback(hObject, eventdata, handles)
% raster plots
function checkbox102_Callback(hObject, eventdata, handles)
% psths
function checkbox103_Callback(hObject, eventdata, handles)


%% Monkey, date, Blocks
function listbox1_Callback(hObject, eventdata, handles)
%function listbox2_Callback(hObject, eventdata, handles)

% monkey
function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu1_Callback(hObject, eventdata, handles)
monkeys=get(handles.popupmenu1,'String');
monkey=get(handles.popupmenu1,'Value');
handles.monkey=monkeys{monkey};
handles.monkey_phys=[monkeys{monkey} '_phys'];
set(handles.text1,'String',handles.monkey);
guidata(hObject, handles);

% dates
function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Add dates
function pushbutton11_Callback(hObject, eventdata, handles)
current_folder=pwd;
cd([handles.drive 'Data' filesep 'TDTtanks' filesep handles.monkey_phys]);
folders = uipickfiles;
cd(current_folder);
if isempty(folders) || (~iscell(folders) && folders==0);
    folders={};
else
    %folders=cell2mat(folders(:));
    for f=1:numel(folders)
        if ~ismember('-',folders{f})
            folders{f}=folders{f}(:,end-7:end);
        else
            folders{f}=[folders{f}(:,end-12:end-7)];
        end
    end
end
handles.dates=[get(handles.listbox1,'string'); folders];
set(handles.listbox1,'String',handles.dates);
guidata(hObject, handles);
% delete dates
function pushbutton12_Callback(hObject, eventdata, handles)
handles.date_to_delete=get(handles.listbox1,{'String','Value'});
if ~isempty(handles.date_to_delete{1})
    handles.date_to_delete{1}(handles.date_to_delete{2}(:)) = [];  % Delete the selected strings.
    set(handles.listbox1,'string',handles.date_to_delete{1},'val',1) % Set the new string.
end
handles.dates=get(handles.listbox1,'string');
guidata(hObject, handles);
% 
% % block
% function listbox2_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% function edit1_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% function edit1_Callback(hObject, eventdata, handles)
% % add block
% function pushbutton13_Callback(hObject, eventdata, handles)
% additional_blocks=get(handles.edit1,'String');
% handles.blocks=[get(handles.listbox2,'string'); additional_blocks];
% set(handles.listbox2,'string',handles.blocks);
% guidata(hObject, handles);
% % delete block
% function pushbutton14_Callback(hObject, eventdata, handles)
% block_to_delete=get(handles.listbox2,{'String','Value'});
% if ~isempty(block_to_delete{1})
%     block_to_delete{1}(block_to_delete{2}(:)) = [];  % Delete the selected strings.
%     set(handles.listbox2,'string',block_to_delete{1},'val',1) % Set the new string.
% end
% handles.blocks=get(handles.listbox2,'string');
% guidata(hObject, handles);

%% Others

function text1_CreateFcn(hObject, eventdata, handles)
function text22_CreateFcn(hObject, eventdata, handles)
function text20_CreateFcn(hObject, eventdata, handles)
function text9_CreateFcn(hObject, eventdata, handles)
function text2_CreateFcn(hObject, eventdata, handles)
function text1_DeleteFcn(hObject, eventdata, handles)





%% WC parameters
function edit10_Callback(hObject, eventdata, handles)
function edit10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit11_Callback(hObject, eventdata, handles)
function edit11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit12_Callback(hObject, eventdata, handles)
function edit12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit13_Callback(hObject, eventdata, handles)
function edit13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit14_Callback(hObject, eventdata, handles)
function edit14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit15_Callback(hObject, eventdata, handles)
function edit15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit16_Callback(hObject, eventdata, handles)
function edit16_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit20_Callback(hObject, eventdata, handles)
function edit20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


