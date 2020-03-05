function ph_create_sorting_table(monkey,daterange)

%daterange=[20161001 20161207];
dag_drive=DAG_get_server_IP;
if nargin<1
    monkey='Tesla';
end


main_folder=[dag_drive filesep 'Data' filesep monkey '_phys_combined_monkeypsych_TDT' filesep];
main_folder_content=dir(main_folder);
main_folder_content=main_folder_content([main_folder_content.isdir]);
main_folder_content(1:2)=[];
subfolders={main_folder_content.name};
if nargin>=2
    subfolders=subfolders(~cellfun(@(x) str2double(x)<daterange(1) || str2double(x)>daterange(2),subfolders));
end


dropboxpath=['C:\Users\' getUserName '\Dropbox' filesep 'DAG' filesep 'phys' filesep monkey '_phys_dpz'];
[~, sheets_available]=xlsfinfo([dropboxpath filesep monkey(1:3) '_sorted_neurons.xlsx']);
if ismember('final_sorting',sheets_available)
    [~, ~, sorting_table]=xlsread([dropboxpath filesep monkey(1:3) '_sorted_neurons.xlsx'],'final_sorting');
elseif ismember('automatic_sorting',sheets_available)
    [~, ~, sorting_table]=xlsread([dropboxpath filesep monkey(1:3) '_sorted_neurons.xlsx'],'automatic_sorting');
else
    sorting_table={'Monkey','Session','Date','Run','Block','Chan','z','Unit','N_spk','Neuron_ID','Times_same_unit','Site_ID'};
end
old_table=sorting_table;
dateindex_old=DAG_find_column_index(old_table,'Date');
if ~isempty(dateindex_old)
    dates_old=[old_table{2:end,dateindex_old}];
    unique_old_dates=unique(dates_old);
else
    unique_old_dates=[];
end
sorting_table=sorting_table(1,:);

unit_names={'a','b','c','d','e','f','g','h','i','j','k'};

for c=1:numel(sorting_table)
    column_name = strrep(sorting_table{c},' ','_');
    column_name = strrep(column_name,'?','');
    sorting_table{c}=column_name;
    idx.(column_name)=DAG_find_column_index(sorting_table,column_name);
end
old_table(1,:)=sorting_table;

%% load same cells
%% nonmatching channels for same cells would lead to an error
clear Session channel blocks sortcodes
run([dropboxpath  filesep 'Same_cells_' monkey(1:3)]);
Same_cells=struct('Session',Session,'channel',channel,'blocks',blocks,'sortcodes',sortcodes,'Neuron_ID',cell(size(Session)));

%% load electrode depths
clear Session block channels z
run([dropboxpath  filesep 'Electrode_depths_' monkey(1:3)]);
Electrode_depths=struct('Session',Session,'block',block,'channels',channels,'z',z);

%% Check for apparent mistakes (nonmatching channels for same cells would lea)

for c=1:numel(Electrode_depths)
    if numel(Electrode_depths(c).channels) ~= numel(Electrode_depths(c).z)
        disp(['Problem in ' num2str(Electrode_depths(c).Session) ', block ' num2str(Electrode_depths(c).block), ' channels and depths dont match']);
    end
end
for c=1:numel(Same_cells)
    if numel(Same_cells(c).blocks) ~= numel(Same_cells(c).sortcodes)
        disp(['Problem in ' num2str(Same_cells(c).Session) ', channel ' num2str(Same_cells(c).channel), ' blocks and sortcodes dont match']);
    end
    d=[Electrode_depths.Session]==Same_cells(c).Session & [Electrode_depths.block]==Same_cells(c).blocks(1);
    z=Electrode_depths(d).z(Electrode_depths(d).channels==Same_cells(c).channel);
    for s2=2:numel(Same_cells(c).blocks)
        d=[Electrode_depths.Session]==Same_cells(c).Session & [Electrode_depths.block]==Same_cells(c).blocks(s2);
        if z~=Electrode_depths(d).z(Electrode_depths(d).channels==Same_cells(c).channel)
            disp(['Problem in ' num2str(Same_cells(c).Session) ', channel ' num2str(Same_cells(c).channel), ' block ' num2str(Same_cells(c).blocks(s2)) ', same cell in different depths']);
        end
    end
    
end



n_row=1;
new_sessions_counter=0;
for s =1:numel(subfolders)
    date=subfolders{s};
    session=str2double(date);
    if ~ismember(session,unique_old_dates)
        new_sessions_counter=new_sessions_counter+1;
    end
    matfiles=dir([main_folder date filesep '*.mat']);
    matfiles={matfiles.name};
    unit_per_session_counter=0;
    site_per_session_counter=0;
    Sites_per_session=struct('channel',{[]},'z',{[]});
    for f=1:numel(matfiles)
        matfile=matfiles{f};
        load([main_folder date filesep matfile])
        
        str_idx=strfind(matfile,'_');
        Run=str2double(matfile(str_idx(1)+1:str_idx(1)+2));
        block=str2double(matfile(str_idx(3)+1:str_idx(3)+2));
        
        d=find(ismember([Electrode_depths.Session],session) &...
            ismember([Electrode_depths.block],block));
        if isempty(d)
            continue
        end
        ch_considered=Electrode_depths(d).channels';
        %% here the fun starts
        %% retrieving channels and units recorded in this run
        %n_chans = size(trial(1).TDT_eNeu_t,1);
        channel_units=[0 0];
        channel_units(1,:)=[];
        trial=trial(~cellfun(@isempty,{trial.TDT_states})); %% some trials are empty...
        for t=1:numel(trial)
            nonempties=find(~cellfun(@isempty, trial(t).TDT_eNeu_t));
            [ch,un]=ind2sub(size(trial(t).TDT_eNeu_t),nonempties);
            channel_units=unique([channel_units; ch(:) un(:)],'rows');
        end
        ch_no_units=ch_considered(~ismember(ch_considered,channel_units(:,1)));
        ch_no_units=[ch_no_units NaN(size(ch_no_units))];
        channel_units=unique([channel_units; ch_no_units],'rows');
        
        for u=1:size(channel_units,1)
            n_row=n_row+1;
            channel=channel_units(u,1);
            sortcode=channel_units(u,2);
            z=Electrode_depths(d).z([Electrode_depths(d).channels]==channel);
            if channel==0 || isempty(z)
                z=NaN;
            end
            sorting_table{n_row,idx.Monkey}=monkey(1:3);
            sorting_table{n_row,idx.Session}=sum(unique_old_dates<=session)+new_sessions_counter;
            sorting_table{n_row,idx.Date}=session;
            sorting_table{n_row,idx.Block}=block;
            sorting_table{n_row,idx.Run}=Run;
            sorting_table{n_row,idx.Chan}=channel;
            sorting_table{n_row,idx.z}=z;
            if ~isnan(sortcode) % there is a cell
                sorting_table{n_row,idx.Unit}=char(96+sortcode);
                sorting_table{n_row,idx.N_spk}=sum(arrayfun(@(x) numel(x.TDT_eNeu_t{channel,sortcode}),trial));
                
                cellrepeated=arrayfun(@(x) any(x.Session==session) && any(x.channel==channel) && any(x.blocks==block & x.sortcodes==sortcode),Same_cells);
                if ~any(cellrepeated) %% unit is unique
                    unit_per_session_counter=unit_per_session_counter+1;
                    
                    sorting_table{n_row,idx.Neuron_ID}=[monkey(1:3) '_' date  '_' sprintf('%02d',unit_per_session_counter)];
                    sorting_table{n_row,idx.Times_same_unit}=1;
                else
                    n_block=find(Same_cells(cellrepeated).blocks==block & Same_cells(cellrepeated).sortcodes==sortcode); %% is it the first block in which this cell appears?
                    
                    if n_block==1 && isempty(Same_cells(cellrepeated).Neuron_ID) %% is it the first block in which this cell appears (and it has not been assigned yet -> from different run)
                        unit_per_session_counter=unit_per_session_counter+1;
                        Same_cells(cellrepeated).Neuron_ID= [monkey(1:3) '_' date  '_' sprintf('%02d',unit_per_session_counter)];
                        n_Times_same_unit_counter=1;
                    else %% this cell was already processed
                        n_Times_same_unit_counter=sum(ismember(sorting_table(1:end-1,idx.Neuron_ID),Same_cells(cellrepeated).Neuron_ID))+1;
                    end
                    sorting_table{n_row,idx.Neuron_ID}=Same_cells(cellrepeated).Neuron_ID;
                    sorting_table{n_row,idx.Times_same_unit}=n_Times_same_unit_counter;
                end
            else % there is no cell
                sorting_table{n_row,idx.Unit}='z';
                sorting_table{n_row,idx.N_spk}=0;
                sorting_table{n_row,idx.Neuron_ID}=[monkey(1:3) '_' date  '_00'];
                sorting_table{n_row,idx.Times_same_unit}=0;
            end
            
            %% LFP sites
            Site_repeated=find(ismember([Sites_per_session.channel],channel) & ismember([Sites_per_session.z],z));
            if isempty(Site_repeated) %not in the table yet
                site_per_session_counter=site_per_session_counter+1;
                Sites_per_session(site_per_session_counter).channel=channel;
                Sites_per_session(site_per_session_counter).z=z;
                sorting_table{n_row,idx.Site_ID}=[monkey(1:3) '_' date  '_Site_' sprintf('%02d',site_per_session_counter)];
            else
                sorting_table{n_row,idx.Site_ID}=[monkey(1:3) '_' date  '_Site_' sprintf('%02d',Site_repeated)];
            end
        end
    end
end

%% append old information for each line in the new table
if size(old_table,1)>1
    for r=2:size(sorting_table,1)
        line_exists=[true;
            ismember(vertcat(old_table{2:end,idx.Date}),sorting_table{r,idx.Date}) &...
            ismember(vertcat(old_table{2:end,idx.Run}),sorting_table{r,idx.Run}) &...
            ismember(vertcat(old_table{2:end,idx.Block}),sorting_table{r,idx.Block}) &...
            ismember(vertcat(old_table{2:end,idx.Chan}),sorting_table{r,idx.Chan}) &...
            ismember(old_table(2:end,idx.Unit),sorting_table(r,idx.Unit))];
        
        if sum(line_exists)>1
            new_line=DAG_update_cell_table(old_table(line_exists,:),sorting_table([1 r],:),'Date');
            sorting_table(r,:)=new_line(2,:);
        end
    end
    old_table([false, ismember([old_table{2:end,idx.Date}],[sorting_table{2:end,idx.Date}])],:)=[];
end

[complete_mastertable]=DAG_update_cell_table(sorting_table,old_table,'Date');
xlswrite([dropboxpath filesep monkey(1:3) '_sorted_neurons.xlsx'],complete_mastertable,'automatic_sorting');
end

