function SPK=PLX2SPK(filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           CONVERT PLEXON FORMAT *.PLX INTO SPKOBJ
%
%DESCRIPTION: This routine imports the waveforms and spiketimes located in
%a *.PLX file into MATLAB and saves them as spkobj. NEX-files are a format
%of Plexon Offlinesorter
%
%SYNTAX: SPK = PLX2SPK(filename)
%
%            filename ... path and filename of *.PLX file
%
%EXAMPLE: plexon2spkobj(SPK,'C:\Recording11_SPK_sorted.nex)
%
%AUTHOR: ©Stefan Schaffelhofer, German Primate Center            6.Dez 2011
%last modified: Lukas Schneider                                  12.03.2020
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ERROR-CHECKING

% check what happens with empty channels

[tscounts, ~, ~, ~] = plx_info(filename,1);
tscounts(:,1) = []; % remove empty channel
[npossunits,nchans] = size(tscounts);
CHANNELS = 1:nchans;


waveforms=[];
spiketimes=[];
sortID=[];
channelID=[];

try
    %h=waitbar(0,'Converting PLX to SPK format');    
    for c = 1:nchans
        fprintf('\n\tChannel %d\n',CHANNELS(c))
        for u = 1:npossunits %unit 1 is 0 though!
            if ~tscounts(u,CHANNELS(c)), continue; end
            [n, ~, t, wave] = plx_waves(filename, c, u-1);
            fprintf('\t\tunit %d\t# spikes:% 8d\n',u-1,n)
            [t idx]=sort(t); % sort the times of a channel and save order
            wave   = wave(idx,:);
            waveforms=[waveforms; wave];
            spiketimes=[spiketimes; t];
            sortID=[sortID; ones(n,1) * (u-1)];
            channelID=[channelID; ones(n,1) * c];
        end
    end
    %close(h);    
catch exception
    %close(h);
    rethrow(exception);
end
SPK.waveforms=single(waveforms);
SPK.sortID   =sortID;
SPK.channelID=channelID;
SPK.spiketimes=spiketimes;

