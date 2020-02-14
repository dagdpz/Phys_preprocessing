function parse_data_tdt(Block, input_stream, limit_to_channels,lag)
%This code required OpenDeveloper (Tucker-Davis Technologies)

folder = fileparts(Block);

if isempty(folder)
    Tank = pwd;
else
    Tank = folder;
    fseps=strfind(Block,filesep);
    Block=Block(fseps(end)+1:end);
end
TDT_block_file=[Tank filesep Block];
    
    
if strcmp(input_stream,'Broadband')
streamnames={'Broa','BROA'}; %'Broa','BROA',
data = TDTbin2mat_working(TDT_block_file, 'EXCLUSIVELYREAD',streamnames, 'T1',0,'T2',1);
streamname=streamnames{ismember(streamnames,fieldnames(data.streams))};
elseif strcmp(input_stream,'snippets')
streamnames={'eNeu'};
data = TDTbin2mat_working(TDT_block_file, 'EXCLUSIVELYREAD',streamnames, 'T1',0,'T2',1);
streamname='eNeu'; %'Broa','BROA',
end
sr = data.streams.(streamname).fs;
lag_in_samples=round(lag*sr);

%% Channel selection
if isfield(data.streams.(streamname),'channels')
channels = unique(data.streams.(streamname).channels);
else
channels = 1:size(data.streams.(streamname).data,1);
end
if ~isstr(limit_to_channels) && ~all(isnan(limit_to_channels)) && ~isempty(limit_to_channels)
    channels=channels(ismember(channels,limit_to_channels));
end
fprintf('%d channels in the block\n', numel(channels))

for ch = channels
     fout = fopen([Tank filesep 'WC_' Block filesep Block '_' num2str(ch) '.tdtch'],'w','l');
     data = TDTbin2mat_working(TDT_block_file, 'EXCLUSIVELYREAD',streamnames,'CHANNEL',ch);
     
     %% use lag info
     if lag_in_samples>0
       data.streams.(streamname).data(1:lag_in_samples)=[];
     else
       data.streams.(streamname).data=[zeros(1,abs(lag_in_samples)) data.streams.(streamname).data];         
     end
     
     fwrite(fout,data.streams.(streamname).data,'single');
     lts = numel(data.streams.(streamname).data);
     clear data
end

save([Tank filesep 'WC_' Block filesep 'tdt_meta_data'],'sr','lts','channels')



