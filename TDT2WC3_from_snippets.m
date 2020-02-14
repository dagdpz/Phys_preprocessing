function TDT2WC3_from_snippets(handles,snippets)
w_pre=floor(size(snippets.data,2)/3);
w_post=ceil(size(snippets.data,2)*2/3);
sr=snippets.fs;

par=struct;
thr=NaN;
channels=unique(snippets.chan)';
for ch= channels
    k=snippets.chan==ch;
    dat=snippets.data(k,:);
    index=snippets.ts(k)*1000;% in milliseconds (?!)
    cluster_class=[snippets.sortcode(k) index];
    if handles.realign_snippets % realiigning snippets to minimum
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


