function ph_debugging_GUI
f = figure('Visible','on','units','normalized','outerposition',[0 0 1 1],'name','Phys preprocessing debug GUI','KeyPressFcn',@keycall);
Gui_version(0,0,0)

window_length=100;
start_t=0;
channel=1;
monkey='';
session='';

LFP_path='Load file first';
WC_path='';
WC_data=[];
LFP_data=[];


spike_data=[];

% spikes=[];
% index=[];
% cluster_class=[];

spike_data=[];
spike_t =[];
cluster =[];
SU={''};

WC_sr=24414.0625;
LFP_sr=WC_sr/24;

LFP_block_samples=0;
WC_block_t=0;

WC_thr1=0;
WC_thr2=0;
WC_ylim=[0 1];
LFP_ylim=[0 1];


uicontrol('Style','pushbutton','String','Plot',     'units','normalized','Position',[0.4,0.9,0.08,0.05],'Callback',@plot_it);
uicontrol('Style','pushbutton','String','Previous Window', 'units','normalized','Position',[0.5,0.9,0.08,0.05],'Callback',@previous_window);
uicontrol('Style','pushbutton','String','Next Window',     'units','normalized','Position',[0.6,0.9,0.08,0.05],'Callback',@next_window);

uicontrol('Style','pushbutton','String','Load',     'units','normalized','Position',[0.8,0.9,0.08,0.05],'Callback',@load_file);


filename_box=uicontrol('Style','text','String',LFP_path,'units','normalized','Position',[0.1,0.85,0.8,0.03]);


uicontrol('Style','text','String','Start (s)','units','normalized','Position',[0.1,0.95,0.08,0.02]);
textboxes.start_t       = uicontrol('Style','edit','units','normalized','String',num2str(start_t),'Position',[0.1,0.9,0.08,0.05],'Callback',@apply_start_t);
uicontrol('Style','text','String','Window (s)','units','normalized','Position',[0.2,0.95,0.08,0.02]);
textboxes.window_length = uicontrol('Style','edit','units','normalized','String',num2str(window_length),'Position',[0.2,0.9,0.08,0.05],'Callback',@apply_window_length);
uicontrol('Style','text','String','Channel','units','normalized','Position',[0.3,0.95,0.08,0.02]);
textboxes.channel       = uicontrol('Style','edit','units','normalized','String',num2str(channel),'Position',[0.3,0.9,0.08,0.05],'Callback',@apply_channel);


panhandle = uipanel('Position', [0.05,0.05,0.9,0.8]);
sp1 = subplot(2,3,1:2,'Parent', panhandle);
        hold on
sp2 = subplot(2,3,4:5,'Parent', panhandle);
        hold on

sp3 = subplot(2,3,3,'Parent', panhandle);
sp4 = subplot(2,3,6,'Parent', panhandle);

    

    function load_file(source,~)
        temp_path=pwd;
        cd(['Y:' filesep 'Data' filesep 'TDTtanks' filesep]);
        folders = uipickfiles;
        cd(temp_path);
        [FP,session]=fileparts(folders{:});
        [FP,monkey]=fileparts(FP);
        
        
        %% now load
        %% a) LFP data from preprocessed trial_structure
        LFP_path=fullfile('Y:','Data',[monkey '_mat_from_TDT'],num2str(session));
        LFP_data=load_LFP;
        
        %% b) preprocessed (filtered) broadband for WC
        WC_path=fullfile('Y:','Data','Sortcodes',monkey,num2str(session));
        WC_data=load_WC;
        
        %% c) spikes (MU and SU)
        
        [spike_data,spike_t,cluster,SU]=load_spikes;
        
        %% Now plot!
        plot_it;
        set(filename_box,'String',LFP_path);
    end

    function WC_data=load_WC
        sub_folders=dir([WC_path filesep 'WC_Block*']);
        data=[];
        WC_data=[];
        for b=1:numel(sub_folders)
            load([WC_path filesep sub_folders(b).name filesep 'datafilt_ch' num2str(channel, '%03.f') '.mat']);
            WC_data=[WC_data data];
            WC_block_samples(b)=numel(WC_data);
        end
        WC_block_t=WC_block_samples/WC_sr;
        WC_ylim=[min(WC_data) max(WC_data)];
        set(sp1,'ylim',WC_ylim);
        
        median_std=median(abs(WC_data))/0.6745;
        WC_thr1=median_std*3;
        WC_thr2=median_std*6;
    end

    function LFP_data=load_LFP
        files=dir([LFP_path filesep '*.mat']);
        LFP_data=[];
        TDT_trial=struct();
        preprocessing_settings=struct();
        First_trial_INI=struct();
        for b=1:numel(files)
            load([LFP_path filesep files(b).name])
            LFP_data=[LFP_data First_trial_INI.LFPx TDT_trial.LFPx];
            LFP_block_samples(b)=size(LFP_data,2);
        end
        if isempty(LFP_data)
        else
            LFP_data=LFP_data(channel,:);
            LFP_sr=TDT_trial.LFPx_samplingrate; %%blockdata?
            
            LFP_ylim=[min(LFP_data) max(LFP_data)];
            set(sp2,'ylim',LFP_ylim);
        end
    end

    function [spike_data,spike_t,cluster,SU]=load_spikes
        
        SU_files=dir([WC_path filesep 'WC' filesep 'dataspikes_ch' num2str(channel, '%03.f') '*SU_neg.mat']);
        
        spikes=[];
        index=[];
        cluster_class=[];
        spike_data=[];
        spike_t=[];
        cluster=[];
        SU={};
        block_t=0;
        for N=1:numel(SU_files)
            load([WC_path filesep 'WC' filesep SU_files(N).name],'spikes','index','cluster_class');
            spike_data=[spike_data; spikes];
            spike_t =[spike_t; index+block_t];
            cluster =[cluster; cluster_class];
            SU=[SU; cellstr(repmat('SU',size(index,1),1))];
            block_t=index(end); %% not correct actually
        end
        
        MU_files=dir([WC_path filesep 'WC' filesep 'dataspikes_ch' num2str(channel, '%03.f') '*MU_neg.mat']);
        
        block_t=0;
        for N=1:numel(MU_files)
            load([WC_path filesep 'WC' filesep MU_files(N).name],'spikes','index','cluster_class');
            spike_data=[spike_data; spikes];
            spike_t =[spike_t; index+block_t];
            cluster =[cluster; cluster_class];
            SU=[SU; cellstr(repmat('MU',size(index,1),1))];
            block_t=index(end); %% not correct actually
        end
        
    end

    function plot_it(~,~)
        %        end_t=floor(end_t*LFP_sr)/LFP_sr;
        %         wc_indexes=(round(start_t*WC_sr+1):round(end_t*WC_sr));
        %         lfp_indexes=(round(start_t*LFP_sr+1):round(end_t*LFP_sr));
        wc_bins=1/WC_sr:1/WC_sr:numel(WC_data)/WC_sr;
        lfp_bins=1/LFP_sr:1/LFP_sr:numel(LFP_data)/LFP_sr;
        cla(sp1)
        plot(sp1,wc_bins,WC_data);
        plot(sp1,[wc_bins(1) wc_bins(end)],[-WC_thr1 -WC_thr1],'color','r');
        plot(sp1,[wc_bins(1) wc_bins(end)],[-WC_thr2 -WC_thr2],'color','g');
        plot(sp2,lfp_bins,LFP_data);
        
        plot(sp1, repmat(WC_block_t,2,1),repmat(WC_ylim',1,numel(WC_block_t)),'k');
        
        
        title(sp1,'Waveclus prefiltered');
        title(sp2,'LFP');
        set_axes_limits;
    end

    function set_axes_limits
        if ~isempty(LFP_data)
            end_t=min([start_t+window_length numel(WC_data)/WC_sr numel(LFP_data)/LFP_sr]);
        else
            end_t=min([start_t+window_length numel(WC_data)/WC_sr]);
        end
        set(sp1,'xlim',[start_t end_t]);
        set(sp2,'xlim',[start_t end_t]);
        set(sp1,'ylim',WC_ylim);
        set(sp1,'ylim',LFP_ylim);
        plot_spikes(start_t,end_t)
    end

    function plot_spikes(start_t,end_t)
        idx_s=start_t < (spike_t/1000) & end_t > (spike_t/1000) & strcmp(SU,'SU');
        idx_m=start_t < (spike_t/1000) & end_t > (spike_t/1000) & strcmp(SU,'MU');
        plot(sp3,spike_data(idx_m,:)','r');
        plot(sp4,spike_data(idx_s,:)','g');
        title(sp3,'MUs');
        title(sp4,'SUs');
        
    end

    function keycall(source,event)
        
        key = event.Key; % get the pressed key value
        if strcmp(key,'leftarrow')
            previous_window; % left value
        elseif strcmp(key,'rightarrow')
            next_window; % right value
        end
    end

    function next_window(~,~)
        start_t=start_t+window_length;
        set(textboxes.start_t,'String',num2str(start_t));
        set_axes_limits;
    end

    function previous_window(~,~)
        start_t=min([0, start_t-window_length]);
        set(textboxes.start_t,'String',num2str(start_t));
        set_axes_limits;
        
    end

    function apply_channel(source,~)
        channel=str2double(get(source,'String'));
        LFP_data=load_LFP;
        WC_data=load_WC;
        plot_it;
    end

    function apply_start_t(source,~)
        start_t=str2double(get(source,'String'));
        set_axes_limits;
    end

    function apply_window_length(source,~)
        window_length=str2double(get(source,'String'));
        set_axes_limits;
    end

end

function Gui_version(~, ~, ~)

ha = axes('units','normalized', ...
    'position',[0 0 1 1]);
uistack(ha,'bottom');
colormap gray
set(ha,'handlevisibility','off', ...
    'visible','off')
end

function ph_plot_BB(session2read,stream_name,channels,save2dir)
if false
    session2read='Y:\Data\TDTtanks\Bacchus_phys\20201217';
    stream_name='Broa';
    channels=[1,9,19,32];
    save2dir='Y:\Projects\Debugging\Bacchus_20201217';
    %
    session2read='Y:\Data\TDTtanks\Bacchus_phys\20201209';
    stream_name='Broa';
    channels=[33,34,35,45,46];%[1,9,19,32];
    save2dir='Y:\Projects\Debugging\Bacchus_20201209';
end
N_ch_per_fig=5;
filtertype='filtered'; %'broadband';

STD=3;

%% FILTER
preprocessing_settings.LFP_notch_filter1= [49.9 50.1] ;
preprocessing_settings.LFP_notch_filter2= [99.9 100.1] ;
preprocessing_settings.LFP_HP_filter= 1 ;
preprocessing_settings.LFP_LP_median_filter= 150 ; %250



% Read TDT data even when there was no task, so no trials, which means the regular phys pipeline can not be used
% E.g.
% bsa_read_TDT_data_without_behavior('Y:\Data\TDTtanks\Magnus_phys\20190124', 'Y:\Projects\PhysiologicalRecording\Data\Magnus\20190124\bodysignals_without_behavior');

% addpath('F:\Dropbox\DAG\DAG_toolbox\Phys_scripts');

blocknames=dir([session2read filesep 'Block*']);
blocknames_wrongly_sorted = {blocknames.name};
a = asort(blocknames_wrongly_sorted,'-s','descend');
blocknames_correctly_sorted = a.anr;
blocknames=strcat(session2read, filesep, blocknames_correctly_sorted);

for b=1:numel(blocknames)
    blockname=blocknames{b};
    data=TDTbin2mat_working(blockname,'EXCLUSIVELYREAD',{stream_name},'STREAMSWITHLIMITEDCHANNELS',{stream_name},'CHANNELS',channels);
    dat.(stream_name){b}=data.streams.(stream_name).data;
    dat.([stream_name '_ch']){b}=data.streams.(stream_name).channels;
end

concatinated_data=[dat.(stream_name){:}];
all_channels=dat.([stream_name '_ch']){b};
concatinated_data=concatinated_data(~isnan(all_channels),:);
all_channels=all_channels(~isnan(all_channels));
samplingrate=data.streams.(stream_name).fs;
SR_factor=round(samplingrate/1010);
N_samples_original=round(size(concatinated_data,2)/SR_factor); %% this is rather stupid baclk and forth samplingrate estimation, but we want to keep the original function here...
tic
for ch=1:size(concatinated_data,1)
    Filtered(ch,:)=filter_function(concatinated_data(ch,:),samplingrate,SR_factor,N_samples_original,preprocessing_settings);
end
toc

if ~exist(save2dir,'dir'),
    [suc,mes] = mkdir(save2dir);
end
switch filtertype
    case 'filtered'
        data_plotted=Filtered;
        sr=round(samplingrate/SR_factor);
    case 'broadband'
        data_plotted=concatinated_data;
        sr=samplingrate;
end
t_bins=1/sr:1/sr:size(data_plotted,2)/sr;
for ch_split=1:ceil(numel(all_channels)/N_ch_per_fig)
    ch_idx=((ch_split-1)*N_ch_per_fig+1):ch_split*N_ch_per_fig;
    if ch_split==ceil(numel(all_channels)/N_ch_per_fig)
        ch_idx=((ch_split-1)*N_ch_per_fig+1):numel(all_channels);
    end
    channels=all_channels(ch_idx);
    
    
    data= data_plotted(ch_idx,:);
    figure('units','normalized','outerposition',[0 0 1 1]);
    clear thresholds
    for c=1:size(data,1)
        spix=(c-1)*2+1;
        sph(spix)=subplot(N_ch_per_fig,2,spix);
        hold on;
        thresholds(c)=STD*std(data(c,:));
        means(c)=mean(data(c,:));
        title(['channel' num2str(channels(c))])
        plot(t_bins,data(c,:)) %% add threshold
        line([0 max(t_bins)],[means(c)-thresholds(c) means(c)-thresholds(c)],'color','r')
        
        ylims=get(gca,'ylim');
        x=0;
        for b=1:numel(blocknames)
            x=x+size(dat.(stream_name){b},2)/samplingrate;
            line([x x],ylims,'color','g');
        end
    end
    %     export_fig([save2dir, filesep, 'concatenated_raw ch '  num2str(channels)], '-pdf','-transparent');
    %     close(gcf);
    
    N_bins=1000;
    norm_factor=size(data,2)/sr/N_bins;
    bins=1:size(data,2)/N_bins:size(data,2);
    t_bins_hist=bins/sr;
    for c=1:size(data,1)
        spix=c*2;
        sph(spix)=subplot(N_ch_per_fig,2,spix);
        hold on;
        indexes=data(c,:)<(means(c)-thresholds(c));
        idx_int=find(indexes);
        spiketimes=idx_int([true diff(idx_int)>1]);
        histc=hist(spiketimes,bins);
        
        title(['channel' num2str(channels(c))])
        plot(t_bins_hist,smooth(histc/norm_factor,5));
        
        ylims=get(gca,'ylim');
        x=0;
        for b=1:numel(blocknames)
            x=x+size(dat.(stream_name){b},2)/samplingrate;
            line([x x],ylims,'color','g');
        end
    end
    
    linkaxes(sph,'x');
    %     export_fig([save2dir, filesep, 'concatenated_FR_'  num2str(STD) 'stds ch '  num2str(channels)], '-pdf','-transparent');
    %     close(gcf);
end

end

function  Output_stream=filter_function(Input_stream,samplingrate,SR_factor,N_samples_original,preprocessing_settings)
%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP_notch_filter1*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(Input_stream));

%bandstop filter 50 Hz
[b,a]=butter(2,preprocessing_settings.LFP_notch_filter2*2/samplingrate,'stop');
datafilt=  filtfilt(b,a, double(datafilt));

% highpass
[b,a]=butter(4, preprocessing_settings.LFP_HP_filter*2/samplingrate, 'high'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);

% lowpass
% n = floor(samplingrate/preprocessing_settings.LFP_LP_median_filter);
% datafilt = DAG_median_filter(datafilt,n);

[b,a]=butter(4, preprocessing_settings.LFP_LP_median_filter*2/samplingrate, 'low'); % 'low', 'high
datafilt=  filtfilt(b,a, datafilt);


% downsampling --> easy way
% duplicate first 12 samples => in the resampling step the nanmean corresponds to that time point
% also, cut off last 12 samples (to have the same length in the as in the input)
datafilt=[datafilt(1:round(SR_factor/2)) datafilt(1:end-round(SR_factor/2))];

%% How does it work in TDT to assign LFP samples... Can't get to the same amount (+/- 1 sample)?
% Problem occurs, when numel(datafilt)/SR_factor<=N_samples_original
% Try without cutting off last 12 samples first ?
RR=N_samples_original*SR_factor-numel(datafilt);
if abs(RR)>50000
    disp(['LFP and Boradband time do not match! t(LFP-Broa)=~ ' num2str(round(RR/24000)) 's']);
end

if RR<0
    %remove last few samples so the total number divided by SR_factor is integer
    datafilt(end+RR+1:end)=[];
else
    %duplicate last few samples so the total number divided by SR_factor is integer
    datafilt(end+1:end+RR)=datafilt(end-RR+1:end);
end

%take nanmean of every 24 samples
Output_stream=nanmean(reshape(datafilt,SR_factor,numel(datafilt)/SR_factor),1);
end


%
% for b=1:numel(blocknames)
%     data= dat.(stream_name){b};
%     channels=dat.([stream_name '_ch']){b};
%     figure;
%     clear thresholds
%     for c=1:size(data,1)
%         subplot(numel(channels),1,c)
%         hold on;
%         thresholds(c)=3*std(data(c,:));
%         means(c)=mean(data(c,:));
%         title(['channel' num2str(channels(c))])
%         plot(data(c,:)) %% add threshold
%         line([0 size(data,2)],[means(c)-thresholds(c) means(c)-thresholds(c)],'color','r')
%     end
%     export_fig([save2dir, filesep, blocknames_correctly_sorted{b} '_raw'], '-pdf','-transparent');
%     close(gcf);
%
%     figure;
%     for c=1:size(data,1)
%         subplot(numel(channels),1,c)
%         indexes=data(c,:)<(means(c)-thresholds(c));
%         idx_int=find(indexes);
%         spiketimes=idx_int([true diff(idx_int)>1]);
%         histc=hist(spiketimes,100);
%         plot(histc);
%     end
%     export_fig([save2dir, filesep, blocknames_correctly_sorted{b} '_FR'], '-pdf','-transparent');
%
%     close(gcf);
% end