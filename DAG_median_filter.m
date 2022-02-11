function data_filtered = DAG_median_filter(data,n)
n_med=ceil(n/2);
n_end=n_med-1;
data_temp=[repmat(nanmean(data(1:n_end)),1,n_end) data repmat(nanmean(data(end-n_end+1:end)),1,n_end)];
N_new_samples=numel(data_temp)-n+1;

data_filtered=zeros(size(data));
for s=1:N_new_samples
    Itmp=sort(data_temp(s:s+n-1));
    data_filtered(s)=Itmp(n_med);
end

end
