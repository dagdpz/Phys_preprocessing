function varargout = set_parameters_phys_ui(varargin)
% SET_PARAMETERS_PHYS_UI MATLAB code for set_parameters_phys_ui.fig
%      SET_PARAMETERS_PHYS_UI, by itself, creates a new SET_PARAMETERS_PHYS_UI or raises the existing
%      singleton*.
%
%      H = SET_PARAMETERS_PHYS_UI returns the handle to a new SET_PARAMETERS_PHYS_UI or the handle to
%      the existing singleton*.
%
%      SET_PARAMETERS_PHYS_UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SET_PARAMETERS_PHYS_UI.M with the given input arguments.
%
%      SET_PARAMETERS_PHYS_UI('Property','Value',...) creates a new SET_PARAMETERS_PHYS_UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before set_parameters_phys_ui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to set_parameters_phys_ui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help set_parameters_phys_ui

% Last Modified by GUIDE v2.5 18-Apr-2017 20:35:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @set_parameters_phys_ui_OpeningFcn, ...
    'gui_OutputFcn',  @set_parameters_phys_ui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    if nargout>=5 && varargout{4}
        delete(varargout{5})
    end
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function set_parameters_phys_ui_OpeningFcn(hObject, eventdata, handles, varargin)
global GLO
% handles.output = 'Placeholder';
handles.current_project = '';
handles.current_version = '';
handles.o='Placeholder';
handles.exit=0;
guidata(hObject, handles);
dag_drive_IP=get_dag_drive_IP;
DAG_user = getUserName;
main_folder=['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];
spk_folder = dir(main_folder);
folders = spk_folder([spk_folder.isdir]); % equal
folders(strncmp({folders.name}, '.', 1)) = [];
for i=1:numel(folders)
    folders_in_spk_folder{:,i} = folders(i).name;
end
GLO.main_path =folders_in_spk_folder;
set(handles.popupmenu1,'string',folders_in_spk_folder)
uiwait

function varargout = set_parameters_phys_ui_OutputFcn(hObject, eventdata, handles)
global GlO
% varargout{1} = handles.output;
varargout{1} = handles.o;
varargout{2} = handles.project;
varargout{3} = handles.version;
varargout{4} = handles.exit;
varargout{5} = handles.set_parameters_phys_ui;
display(varargout{1})

function default_Callback(hObject, eventdata, handles)
text = fileread([fileparts(mfilename('fullpath')) filesep 'set_parameters_phys_DEFAULT.m']);
new_lines = strfind(text, sprintf('\n'));
text = text(new_lines(1)+1:end);
set(handles.text_editor,'string',text);

function text_editor_Callback(hObject, eventdata, handles)

function text_editor_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'Max', 2); %// Enable multi-line string input to the editbox


function edit1_Callback(hObject, eventdata, handles)

function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu1_Callback(hObject, eventdata, handles) %folder versions
global GLO
projects=get(handles.popupmenu1,'String');
project=get(handles.popupmenu1,'Value');
handles.current_project=projects{project};
set(handles.text2,'String',handles.current_project);
dag_drive_IP=get_dag_drive_IP;
DAG_user = getUserName;
spk_folder = dir(['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis\' handles.current_project]);
folders = spk_folder([spk_folder.isdir]);
folders(strncmp({folders.name}, '.', 1)) = [];
for i=1:numel(folders)
    folders_in_spk_folder{:,i} = folders(i).name;
end
set(handles.popupmenu2,'string',folders_in_spk_folder)
GLO.project_folder=folders_in_spk_folder;

function edit2_Callback(hObject, eventdata, handles)
handles.current_project=get(handles.edit2,'String');
display(handles.current_project)
set(handles.text2,'str',handles.current_project);

function edit2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit3_Callback(hObject, eventdata, handles)
handles.current_version=get(handles.edit3,'String');
display(handles.current_version)
set(handles.text3,'str',handles.current_version);

function edit3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu2_Callback(hObject, eventdata, handles)
versions=get(handles.popupmenu2,'String');
version=get(handles.popupmenu2,'Value');
handles.current_version=versions{version};
set(handles.text3,'String',handles.current_version);

function popupmenu2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu1_ButtonDownFcn(hObject, eventdata, handles)

function popupmenu1_CreateFcn(hObject, eventdata, handles)

function radiobutton1_ButtonDownFcn(hObject, eventdata, handles)

function text2_CreateFcn(hObject, eventdata, handles)

function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
sel = findobj(get(uipanel1,'selectedobject'));
S.SEL = find(S.rd==sel);
if (get(hObject,'Value') == 1)
    a=1
elseif (get(hObject,'Value') == 2)
    a=2
elseif (get(hObject,'Value') == 3)
    a=3
end

function popupmenu3_Callback(hObject, eventdata, handles)
settings=get(handles.popupmenu3,'String');
setting=get(handles.popupmenu3,'Value');
handles.current_setting=settings{setting};
DAG_user = getUserName;
spk_folder = ['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];
project=get(handles.text2,'str');
version=get(handles.text3,'str');
switch handles.current_setting
    case'General physiology settings'
        text = fileread([spk_folder filesep 'ph_general_settings.m']);
        new_lines = strfind(text, sprintf('\n'));
        text = text(new_lines(1)+1:end);
        set(handles.text_editor,'string',text);
    case'Project settings'
        spk_folder = ['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];
        text = fileread([spk_folder filesep project filesep 'ph_project_settings.m']);
        set(handles.text_editor,'string',text);
    case'Version settings'
        spk_folder = ['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];
        text = fileread([spk_folder filesep project filesep version filesep 'ph_project_version_settings.m']);
        set(handles.text_editor,'string',text);
    otherwise
end

function popupmenu3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function save_Callback(hObject, eventdata, handles)
project=get(handles.text2,'str');
version=get(handles.text3,'str');
copyfile_later=0;
DAG_user = getUserName;
main_folder=['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];
if ~exist([main_folder filesep project],'dir')
    mkdir(main_folder,project);
    copyfile_later=1;
end
if ~exist([main_folder filesep project filesep version],'dir')
    mkdir([main_folder filesep project],version);
end
fout = fopen([main_folder filesep project filesep version filesep 'ph_project_version_settings.m'],'w');
handles.o =[main_folder filesep project filesep version filesep 'ph_project_version_settings.m'];
handles.version =version;
handles.project =project;
guidata(hObject, handles);
text = get(handles.text_editor, 'String');
for row = 1:size(text,1)
    fprintf(fout, '%s \n', strtrim(text(row,1:end)));
end
fclose(fout);
if copyfile_later
    copyfile([main_folder filesep project filesep version filesep 'ph_project_version_settings.m'], [main_folder filesep project filesep 'ph_project_settings.m'])
end
spk_folder = dir(main_folder);
folders = spk_folder([spk_folder.isdir]); 
folders(strncmp({folders.name}, '.', 1)) = [];

for i=1:numel(folders)
    folders_in_spk_folder{:,i} = folders(i).name;
end
GLO.main_path =folders_in_spk_folder;
set(handles.popupmenu1,'string',folders_in_spk_folder)
uiresume

function pushbutton3_Callback(hObject, eventdata, handles)
pos_size = get(handles.set_parameters_phys_ui,'Position');

        
project=get(handles.text2,'str');
version=get(handles.text3,'str');
copyfile_later=0;
DAG_user = getUserName;
main_folder=['C:\Users\' DAG_user '\Dropbox\DAG\DAG_toolbox\spike_analysis'];

handles.o =[main_folder filesep project filesep version filesep 'ph_project_version_settings.m'];
handles.version =version;
handles.project =project;
handles.exit=1;
guidata(hObject, handles);
uiresume

% 
% choice = questdlg('Do you want to exit settings?', 'Exit', 'No', 'Yes', 'Yes');
% switch choice
%     case {'No'}
%     case {'Yes'}
%end
