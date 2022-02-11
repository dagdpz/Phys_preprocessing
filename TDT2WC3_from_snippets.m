function TDT2WC3_from_snippets(handles,snippets)
% This function is used to convert TDT snippets to WC, allowing to use WC
% sorting also when there was no broadband recorded. In particular, this
% function was used to compare plexon sorting and waveclus sorting
% performed on the same snippets

w_pre   =floor(size(snippets.data,2)/3);
w_post  =ceil(size(snippets.data,2)*2/3);
sr      =snippets.fs;
par     =struct;
par.sr  =snippets.fs;
thr     =NaN;
channels=unique(snippets.chan)';
for ch= channels
    k=snippets.chan==ch;
    dat=snippets.data(k,:);
    index=snippets.ts(k)*1000;% in milliseconds (!)
    cluster_class=[snippets.sortcode(k) index];
    if handles.realign_snippets % realigning snippets to minimum
        nspk=sum(k);
        filldata=median(dat(:));
        for i=1:nspk,
            [~,ind] = min(dat(i,:));
            m=abs(w_pre-ind);
            if ind<w_pre
                dat(i,:)=[filldata*ones(1,m) dat(i,1:end-m)];
            elseif ind>w_pre
                dat(i,:)=[dat(i,m+1:end) filldata*ones(1,m) ];
            end
        end
    end
    spikes=dat;
    clear dat
    chstr=sprintf('%03d',ch);
    switch handles.threshold
        case 'pos'
            save([handles.foldername 'dataspikes_ch' chstr '_SU_pos'],'spikes','index','thr','par','cluster_class')
        case 'neg'
            save([handles.foldername 'dataspikes_ch' chstr '_SU_neg'],'spikes','index','thr','par','cluster_class')
        case 'both'
            save([handles.foldername 'dataspikes_ch' chstr '_SU_neg'],'spikes','index','thr','par','cluster_class')
    end
end


