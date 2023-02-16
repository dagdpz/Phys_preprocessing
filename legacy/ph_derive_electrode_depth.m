function ph_derive_electrode_depth(monkey)
% INPUT: ph_derive_electrode_depth('Flaffus');
% creates 'Electrode_depths_Fla.m' file in the dropbox/phys_dpz path
% using the 'Fla_sorted_neurons.xlsx' file (sheet 'final_sorting')
% This function should not be necessary any more, it was used to
% automatically create the first Electrode_depths files.

% dbpath=DAG_get_Dropbox_path;
% main_folder=[dbpath filesep 'DAG' filesep 'phys' filesep];

drive=DAG_get_server_IP;
main_folder=[drive 'Data' filesep 'Sorting_tables' filesep monkey filesep];

xcel_table_file=[main_folder monkey(1:3) '_sorted_neurons.xlsx'];
m_file_name=[main_folder 'Electrode_depths_' monkey(1:3) '.m'];
xcel_sheet='final_sorting';
[~,~,xcel_table]=xlsread(xcel_table_file,xcel_sheet);
columns_to_find={'Date','Block','Chan','z'};

for cols=columns_to_find
    idx.(cols{:})=DAG_find_column_index(xcel_table,cols{:});
    all.(cols{:})=xcel_table(:,idx.(cols{:}));
end
unique_blocks=unique([[all.Date{2:end}]' [all.Block{2:end}]'],'rows');

clear electrode_depths
for b=1:size(unique_blocks,1)
    row_indexes=ismember([all.Date{2:end}],unique_blocks(b,1)) & ismember([all.Block{2:end}],unique_blocks(b,2));
    row_indexes=[false row_indexes];
    temp_z=[all.z{row_indexes}];
    temp_ch=[all.Chan{row_indexes}];
    electrode_depths(b).Date                 =unique([all.Date{row_indexes}]);
    electrode_depths(b).Block                =unique([all.Block{row_indexes}]);
    [electrode_depths(b).Chan, ch_idx]       =unique([all.Chan{row_indexes}]);
    depths_misassigned=temp_z(~ismember(temp_z,temp_z(ch_idx)));
    channel_misassigned=temp_ch(~ismember(temp_z,temp_z(ch_idx)));
    if any(channel_misassigned)
        disp([num2str(unique_blocks(b,1)) ', Block ' num2str(unique_blocks(b,2)) ' Channels ' num2str(unique(channel_misassigned)) ' have inconsistent depths']);
    end
    electrode_depths(b).z                    =[temp_z(ch_idx) depths_misassigned];
end

%% writing to m-file
fid = fopen(m_file_name,'w');
fprintf(fid,'k=0; \n');
for b=1:size(unique_blocks,1)
    to_write=['k=k+1; Session{k}=' num2str(electrode_depths(b).Date) ...
        '; block{k}=' num2str(electrode_depths(b).Block) ...
        '; channels{k}= [' num2str(electrode_depths(b).Chan) ']'...
        '; z{k}=[' num2str(electrode_depths(b).z) ']; '];
    fprintf(fid, to_write);
    fprintf(fid, '\n');    
end
fclose(fid);
end
