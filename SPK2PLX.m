function SPK2PLX(SPK,filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           CONVERT SPKOBJ INTO PLEXON FORMAT *.PLX
%
%DESCRIPTION: This routine takes the the waveClus-files of all channels in
% 'tank' and stores them in a spkobj and neuronobj.
%
%HELPFUL INFORMATION:
%
%SYNTAX: SPK2PLX(SPK,filename)
%            SPK object is the created by WC32SPK
%            filename the desired name of the plx file 
%
%
%AUTHOR: ©Katharina Menz, German Primate Center                     Aug2011
%last modified: Lukas Schneider                                  12.03.2020
%               Katharina Menz                                   22.08.2011
%               Stefan Schaffelhofer                             20.09.2011
%               Stefan Schaffelhofer                             12.12.2011
%               Lukas
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[pathstr, ~, ~]=fileparts(filename);
if ~isdir(pathstr)
    error('Path is non-existent or not a directory.');
end


ts   = cell(0,0);
wave = cell(0,0);
sort = cell(0,0);
npw=24; % dummie for no spikes
SCALE         = 1000;% waveforms are multiplied by 1000 to get MV

% CREATING PLX STRUCTURE
fs=SPK.samplingrate*SPK.int_factor; % we need and use an interpolation factor for WC pipeline 
nch=int8(max(SPK.channelID));
sortid=SPK.sortID;                                                   % add 1 to sort id because: plexon saves unsorted spikes with sortid 1, in SPKOBJ, unsorted spikes are marked with zeros;

for ch=1:nch % for all channels
    disp(['Extracting Ch' num2str(ch)]);
    ind=SPK.channelID==ch;
    
    
    n = sum(ind);
    if ~n, continue; end
    
    waveforms_temp=SPK.waveforms(ind,:); 
    spiketimes_temp=SPK.spiketimes(ind,:);
    sortids_temp=sortid(ind,:);% sort ids of a channel
    
    ts{ch}                  = spiketimes_temp;
    wave{ch}                = waveforms_temp*SCALE;
    wavesamplesize          = size(waveforms_temp,2);
    sort{ch}                = sortids_temp;
    npw = wavesamplesize; 
    
    % set sortcode 31 to the last not used sortcode...!!! -> important for
    % TDT2PLX
    if ~any(sort{ch}<26)
        sort{ch}(sort{ch}>=26)=0;
    else
        last_used_sortcode = max(sort{ch}(sort{ch}<26));
        sort{ch}(sort{ch}>=26)  = last_used_sortcode+1;
    end
end % end for ch

maxts = max(vertcat(ts{:}));

emptychs = cellfun(@isempty,ts);
ts(emptychs)   = [];
wave(emptychs) = [];
sort(emptychs) = [];
validchs = find(~emptychs);

clear SPK;
disp('Start writing PLX file ...');
tic
fid = writeplxfilehdr(filename,fs,length(validchs),npw,maxts);
for ch = validchs
    writeplxchannelhdr(fid,ch,npw)
end

for i = 1:length(validchs)
    fprintf('Writing channel% 3d\t# spikes:% 7d\n',validchs(i),length(ts{i}))
    writeplxdata(fid,validchs(i),fs,ts{i},sort{i},npw,wave{i})
end

fclose(fid);
toc
%ok=writeNex(nexstruct,filename);
disp('PLX export finished!');




function plx_id = writeplxfilehdr(filename,freq,nch,npw,maxts)
pad256(1:256) = uint8(0);

% create the file and write the file header

plx_id = fopen(filename, 'W');
if plx_id == -1
    error('Unable to open file "%s".  Maybe it''s open in another program?',filename)
end
fwrite(plx_id, 1480936528, 'integer*4');    % 'PLEX' magic code
fwrite(plx_id, 101, 'integer*4');           % the version no.
fwrite(plx_id, pad256(1:128), 'char');      % placeholder for comment
fwrite(plx_id, freq, 'integer*4');          % timestamp frequency
fwrite(plx_id, nch, 'integer*4');           % no. of DSP channels
fwrite(plx_id, 0, 'integer*4');             % no. of event channels
fwrite(plx_id, 0, 'integer*4');             % no. of A/D (slow-wave) channels
fwrite(plx_id, npw, 'integer*4');           % no. points per waveform
fwrite(plx_id, floor(npw/4), 'integer*4');         % (fake) no. pre-threshold points %% floor !!
[YR, MO, DA, HR, MI, SC] = datevec(now);    % current date & time
fwrite(plx_id, YR, 'integer*4');            % year
fwrite(plx_id, MO, 'integer*4');            % month
fwrite(plx_id, DA, 'integer*4');            % day
fwrite(plx_id, HR, 'integer*4');            % hour
fwrite(plx_id, MI, 'integer*4');            % minute
fwrite(plx_id, SC, 'integer*4');            % second
fwrite(plx_id, 0, 'integer*4');             % fast read (reserved)
fwrite(plx_id, freq, 'integer*4');          % waveform frequency
fwrite(plx_id, maxts*freq, 'double');       % last timestamp
fwrite(plx_id, pad256(1:56), 'char');       % should make 256 bytes

% now the count arrays (with counts of zero)
for i = 1:40
    fwrite(plx_id, pad256(1:130), 'char');    % first 20 are TSCounts, next 20 are WFCounts
end
for i = 1:8
    fwrite(plx_id, pad256(1:256), 'char');    % all of these make up EVCounts
end


function writeplxchannelhdr(plx_id,ch,npw)
% now the single PL_ChanHeader
pad256(1:256) = uint8(0);

% assume simple channel names
DSPname = sprintf('DSP%03d',ch);
SIGname = sprintf('SIG%03d',ch);

fwrite(plx_id, DSPname, 'char');
fwrite(plx_id, pad256(1:32-length(DSPname)));
fwrite(plx_id, SIGname, 'char');
fwrite(plx_id, pad256(1:32-length(SIGname)));
fwrite(plx_id, ch, 'integer*4');            % DSP channel number
fwrite(plx_id, 0, 'integer*4');             % waveform rate limit (not used)
fwrite(plx_id, ch, 'integer*4');            % SIG associated channel number
fwrite(plx_id, ch, 'integer*4');            % SIG reference  channel number
fwrite(plx_id, 1, 'integer*4');             % dummy for gain
fwrite(plx_id, 0, 'integer*4');             % filter off
fwrite(plx_id, -12, 'integer*4');           % (fake) detection threshold value
fwrite(plx_id, 0, 'integer*4');             % sorting method (dummy)
fwrite(plx_id, 0, 'integer*4');             % number of sorted units
for i = 1:10
    fwrite(plx_id, pad256(1:64), 'char');     % filler for templates (5 * 64 * short)
end
fwrite(plx_id, pad256(1:20), 'char');       % template fit (5 * int)
fwrite(plx_id, npw, 'integer*4');           % sort width (template only)
fwrite(plx_id, pad256(1:80), 'char');       % boxes (5 * 2 * 4 * short)
fwrite(plx_id, 0, 'integer*4');             % beginning of sorting window
fwrite(plx_id, pad256(1:128), 'char');      % comment
fwrite(plx_id, pad256(1:44), 'char');       % padding


function writeplxdata(plx_id,ch,freq,ts,units,npw,wave)
% now the spike waveforms, each preceded by a PL_DataBlockHeader
n = length(ts);

for ispike = 1:n
    fwrite(plx_id, 1, 'integer*2');           % type: 1 = spike
    fwrite(plx_id, 0, 'integer*2');           % upper byte of 5-byte timestamp
    fwrite(plx_id, ts(ispike)*freq, 'integer*4');  % lower 4 bytes
    fwrite(plx_id, ch, 'integer*2');          % channel number
    fwrite(plx_id, units(ispike), 'integer*2');  % unit no. (0 = unsorted)
    fwrite(plx_id, 1, 'integer*2');           % no. of waveforms = 1
    fwrite(plx_id, npw, 'integer*2');         % no. of samples per waveform
    fwrite(plx_id, wave(ispike, 1:npw), 'integer*2');
end

