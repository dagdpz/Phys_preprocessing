function ph_derive_same_cells(monkey)
% INPUT: ph_derive_same_cells('Flaffus');
% creates 'Same_cells_Fla.m' file in the dropbox/phys_dpz path
% using the 'Fla_sorted_neurons.xlsx' file (sheet 'final_sorting')
% This function should not be necessary any more, it was used to
% automatically create the first Same_cells files.

dbpath=DAG_get_Dropbox_path;
main_folder=[dbpath filesep 'DAG' filesep 'phys' filesep];
xcel_table_file=[main_folder monkey '_phys_dpz' filesep monkey(1:3) '_sorted_neurons.xlsx'];
m_file_name=[main_folder monkey '_phys_dpz' filesep 'Same_cells_' monkey(1:3) '.m'];
xcel_sheet='final_sorting';
[~,~,xcel_table]=xlsread(xcel_table_file,xcel_sheet);

unit_names={'a','b','c','d','e','f','g','h','i','j','k'};
columns_to_find={'Date','Block','Chan','Unit','Neuron_ID'};

for cols=columns_to_find
    idx.(cols{:})=DAG_find_column_index(xcel_table,cols{:});
    all.(cols{:})=xcel_table(:,idx.(cols{:}));
end

unique_units=unique(all.Neuron_ID);

k=0;
clear unit_pairs
for u=1:numel(unique_units)
    row_indexes=ismember(all.Neuron_ID,unique_units(u));
    row_indexes(1)=false;
    if sum(row_indexes)>1
        k=k+1;
        unit_pairs(k).Neuron_ID  =unique_units{u};
        unit_pairs(k).Chan       =unique([all.Chan{row_indexes}]);
        unit_pairs(k).Date       =unique([all.Date{row_indexes}]);
        unit_pairs(k).Block      =[all.Block{row_indexes}];
        
        unit_abc=all.Unit(row_indexes)';
        unit_123=[];
        for n=unit_abc
            unit_123=[unit_123 find(ismember(unit_names,n{:}))];
        end
        unit_pairs(k).Unit       =unit_123;
    end
end

%% writing to m-file
fid = fopen(m_file_name,'w');
fprintf(fid,'k=0; \n');
for k=1:numel(unit_pairs)
    to_write=['k=k+1; Session{k}=' num2str(unit_pairs(k).Date) ...
        '; channel{k}=' num2str(unit_pairs(k).Chan) ...
        '; blocks{k}= [' num2str(unit_pairs(k).Block) ']'...
        '; sortcodes{k}=[' num2str(unit_pairs(k).Unit) ']; '];
    fprintf(fid, to_write);
    fprintf(fid, '\n');    
end
fclose(fid);
end
