function DAG_SpikefilterChan(handles)


%% simplifying handles
limit_to_channels   = handles.channels_to_process;
stop_f              = handles.WC.linenoisefrequ;
sr                  = handles.WC.sr;
hpcutoff            = handles.WC.hpcutoff;
lpcutoff            = handles.WC.lpcutoff;
tf_factor           = handles.WC.transform_factor;
rawname             = handles.rawname;
dtyperead           = handles.dtyperead;
dtypewrite          = handles.dtypewrite;
hp                  = handles.WC.hp;

%% defining number of samples for median filter
if strcmp(hp,'med')
    n = floor(sr/hpcutoff);
    if ~mod(n,2)
        n = n+1;
    end
end

%% get filelist
if handles.blockfile %% always 0 as far as i can see?
    files = dir('dataraw_ch*.mat');
    files = {files.name};
else
    files = dir([handles.WC_block_folder rawname]);
    files = {files.name};
end

warning off % turn off annoying concatenation warnings

for i = 1 : length(files)
    tic
    
    filename =  files{i};
    chan_num=str2double(filename(strfind(filename,'_')+1:end-6));
    if ~ismember(chan_num,limit_to_channels)
        continue;
    end
    switch handles.sys
        case 'TD'
            channel_file_handle = fopen([handles.WC_block_folder filename], 'r');      %'r' - read the indicated channel file
            data = fread(channel_file_handle, [dtyperead '=>' dtyperead]);             %reads out the data, int16 - class of input and output values
            fclose(channel_file_handle);
            data = double(data)/tf_factor;
            if handles.WC.iniartremovel
                data(1:40) = nanmean(data(41:80));
            end
    end
    
    if size(data,2) == 1 % for only one channel? this should either always or never be the case...
        data = data';
    end
    
    if handles.WC.linenoisecancelation
        [b,a]=ellip(2,0.1,40,[stop_f-1 stop_f+1]*2/sr,'stop');
        data=filtfilt(b,a,data);
        [b,a]=ellip(2,0.1,40,[2*stop_f-1 2*stop_f+1]*2/sr, 'stop');
        data=filtfilt(b,a,data);
        [b,a]=ellip(2,0.1,40,[3*stop_f-1 3*stop_f+1]*2/sr, 'stop');
        data=filtfilt(b,a,data);
    end
    
    if strcmp(hp,'med')
        xx = DAG_median_filter(data,n);
        data = data-xx;
        clear xx;
    else
        [b,a] = butter(2,hpcutoff*2/sr,'high');
        data=filtfilt(b,a,data);
    end
    
    [b,a] = butter(2,lpcutoff*2/sr,'low'); % butterworth for low pass in any case
    data=filtfilt(b,a,data);
    
    data = eval([dtypewrite '(data)']);
    fil=[handles.WC_block_folder 'datafilt_ch' sprintf('%03d',chan_num)];
    save(fil,'data');
    
    clear data
    disp([hp ' filtering channel ' sprintf('%03d',chan_num) ' took ' num2str(round(toc*10)/10) ' seconds']);
end

warning on



