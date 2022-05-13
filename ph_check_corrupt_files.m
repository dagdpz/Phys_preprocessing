function corrupted_table=ph_check_corrupt_files(monkey)

%monkey='Bacchus_phys';
mainfolder=['Y:\Data\TDTtanks' filesep monkey];

D=dir(mainfolder);
Sessions={D([D.isdir]).name};Sessions(1:2)=[];

row_counter=1;

for s=1:numel(Sessions)
    
    Session=Sessions{s};
    Sessionfolder=[mainfolder filesep Session];
    
    D=dir(Sessionfolder);
    Blocks={D([D.isdir]).name};Blocks(1:2)=[];
    
    for b=1:numel(Blocks)
        Block=Blocks{b};
        
        
        TDTblockfolder=[Sessionfolder filesep Block];
        
        %TDT_trial_struct_input      = {'SORTNAME',SORTNAME,'DONTREAD',DONTREAD,'EXCLUSIVELYREAD',EXCLUSIVELYREAD,'CHANNELS',CHANNELS,'STREAMSWITHLIMITEDCHANNELS',STREAMSWITHLIMITEDCHANNELS};
        EXCLUSIVELYREAD={'Sess'};
        TDT_trial_struct_input      = {'EXCLUSIVELYREAD',EXCLUSIVELYREAD};
        try
        data             =TDTbin2mat_working(TDTblockfolder, TDT_trial_struct_input{:});
        if isstruct(data.epocs) && isfield(data.epocs,'Sess') && isstruct(data.epocs.Sess) && isfield(data.epocs.Sess,'data')
            Session_data     =data.epocs.Sess.data;
            if numel(Session_data)>1
                Session_data(1)=Session_data(2);
            end
            invalid=        Session_data<100000|Session_data>800000;
        else
            invalid=NaN;
        end
        catch
            invalid=-1;
            Block
        end
        
        corrupted_table(row_counter,1)=str2double(Session);
        corrupted_table(row_counter,2)=str2double(Block(7:end));
        corrupted_table(row_counter,3)=sum(invalid);
        
        
        row_counter=row_counter+1;
    end
    
end
corrupted_blocks=corrupted_table(:,3)~=0;
corrupted_table=corrupted_table(corrupted_blocks,:);