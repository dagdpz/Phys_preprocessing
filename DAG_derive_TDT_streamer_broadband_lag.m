function DAG_derive_TDT_streamer_broadband_lag(monkey)
% INPUT: DAG_derive_TDT_streamer_broadband_lag('Magnus_phys')
% creates an excel table and .m file containing estimated lag between LFP and Broadband
% data for each block (using cross correlation). This is used to counteract a (by now hopefully solved) bug
% that caused a delay when using the streamer and not switching to IDLE mode at the right time

%monkey='test';
excel_filename=[monkey '_LFP_BROA_comp'];
dag_drive=DAG_get_server_IP;
raw_analysis_folder=[dag_drive filesep 'data' filesep '_Raw_data_analysis'];
folder_to_save_figures=[raw_analysis_folder filesep monkey '_broadband_lag_figures'];
if ~exist(folder_to_save_figures,'dir')
   mkdir(raw_analysis_folder,[monkey '_broadband_lag_figures']); 
end

basepath=['Y:\Data\TDTtanks\' monkey];
sessions=dir(basepath);
sessions={sessions([sessions.isdir]).name};
sessions(1:2)=[];
fid = fopen([monkey '_LFP_BROA_comp.m'],'w');

DONTREAD                    = {'pNeu','LED1','trig'}; %priority over ExclusivelyRead % 'BROA','Broa' (add these if you want to use online filtered LFP)
EXCLUSIVELYREAD             = {'LFPx','Broa','BROA'}; %(empty read everything)
CHANNELS                    = 1; %filter for signals
STREAMSWITHLIMITEDCHANNELS  = {'LFPx','Broa','BROA','pNeu'}; %filtered signals (only the part of the signal in the channel defined as filter will be read)
SORTNAME                    = 'Plexsormanually';
DISREGARDLFP                = 0;
PLXVERSION                  = '';


TDT_trial_struct_input      = {'SORTNAME',SORTNAME,'DONTREAD',DONTREAD,'EXCLUSIVELYREAD',EXCLUSIVELYREAD,'CHANNELS',CHANNELS,...
    'STREAMSWITHLIMITEDCHANNELS',STREAMSWITHLIMITEDCHANNELS,'PLXVERSION',PLXVERSION,'DISREGARDLFP',DISREGARDLFP};

cell_out={'Session','Block','samples_Broa','samples_LFP','diff','lag_seconds','lag_samples'};

row=1;
for s=1:numel(sessions)
    session=sessions{s};
    blocks=dir([basepath filesep session]);
    blocks={blocks([blocks.isdir]).name};
    blocks(1:2)=[];
    if isempty(blocks)
        continue
    end
    blocks=blocks(cellfun(@(x) ~isempty(x) && x==1,strfind(blocks,'Block')));
    
    for b=1:numel(blocks)
        block=blocks{b};
        data             =TDTbin2mat_working([basepath filesep session filesep block], TDT_trial_struct_input{:});
        
        stream_fieldnames=fieldnames(data.streams);
        if ~ismember('Broa',stream_fieldnames) || ~ismember('LFPx',stream_fieldnames)
            continue
        end
        
        tBroa=size(data.streams.Broa.data,2)/data.streams.Broa.fs;
        tLFP=size(data.streams.LFPx.data,2)/data.streams.LFPx.fs;
        to_write=['Data: ' session ' ' block '; Broadband: ' num2str(tBroa) 's, LFP: ' num2str(tLFP) 's \n'];
        
        
        SR_factor=round(data.streams.Broa.fs/data.streams.LFPx.fs);
        N_samples_original=size(data.streams.LFPx.data,2);
        % highpass
        [bb,a]=butter(4, 1*2/data.streams.Broa.fs, 'high'); % 'low', 'high
        datafilt=  filtfilt(bb,a, double(data.streams.Broa.data));
        
        % lowpass
        [bb,a]=butter(4, 150*2/data.streams.Broa.fs, 'low'); % 'low', 'high
        datafilt=  filtfilt(bb,a, datafilt);
        
        
        % downsampling --> easy way
        % duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
        % also, cut off last 12 samples (to have the same length in the as in the input)
        datafilt=[datafilt(1:round(SR_factor/2)) datafilt(1:end-round(SR_factor/2))];
        % duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
        % datafilt=[datafilt(1:round(SR_factor/2)) datafilt];
        
        RR=N_samples_original*SR_factor-numel(datafilt);
        
        %% How does it work in TDT to assign LFP samples... Can't get to the same amount (+/- 1 sample)?
        % Problem occurs, when numel(datafilt)/SR_factor<=N_samples_original
        % Try without cutting off last 12 samples first ?
        
        if abs(RR)>50000
            warning(['LFP and Boradband time do not match! t(LFP-Broa)=~ ' num2str(round(RR/24000)) 's']);
        end
        RR=mod(RR,SR_factor);
        if RR<0
            %remove last few samples so the total number divided by SR_factor is integer
            datafilt(end+RR+1:end)=[];
        else
            %duplicate last few samples so the total number divided by SR_factor is integer
            datafilt(end+1:end+RR)=datafilt(end-RR+1:end);
        end
        
        LFP_from_BB=nanmean(reshape(datafilt,SR_factor,numel(datafilt)/SR_factor),1);
        %% filter LFP as well
        
        % highpass
        [bb,a]=butter(4, 1*2/data.streams.LFPx.fs, 'high'); % 'low', 'high
        datafilt=  filtfilt(bb,a, double(data.streams.LFPx.data));
        
        % lowpass
        [bb,a]=butter(4, 150*2/data.streams.LFPx.fs, 'low'); % 'low', 'high
        datafilt=  filtfilt(bb,a, datafilt);
        
        %take nanmean of every 24 samples
        LFP_from_LFPx=datafilt;
        
        [r,lags] = xcorr(double(LFP_from_BB),double(LFP_from_LFPx));
        [~,maxidx]=max(r);
        lag=lags(maxidx);
        
        row=row+1;
        cell_out{row,1}=session;
        cell_out{row,2}=block;
        cell_out{row,3}=tBroa;
        cell_out{row,4}=tLFP;
        cell_out{row,5}=tBroa-tLFP;
        cell_out{row,6}=lag/data.streams.LFPx.fs;
        cell_out{row,7}=lag;
        fprintf(fid, to_write);
        
        figure_handle=figure;
        figurename=[session '_' block];
        hold on
        plot(LFP_from_LFPx,'b');
        plot((1:numel(LFP_from_BB))-lag,LFP_from_BB,'r');
        legend('LFPX','Broa');
        
        mtit(figure_handle,  figurename, 'xoff', 0, 'yoff', 0.05, 'color', [0 0 0], 'fontsize', 8,'Interpreter', 'none');
        wanted_size=[50 30];
        set(figure_handle, 'Paperunits','centimeters','PaperSize', wanted_size,'PaperPositionMode', 'manual','PaperPosition', [0 0 wanted_size])
        export_fig([folder_to_save_figures filesep figurename], '-pdf','-transparent') % pdf by run
        close all
    end
    
    row=row+1;
end
fclose(fid);
xlswrite(excel_filename,cell_out);
end