clear;
addpath('../utils/');
addpath('..');
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
% sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%% Load population data
popu = load('us_states_population_data.txt');
abvs = readcell('us_states_abbr_list.txt');
ns = length(abvs);

%% Convert hospital data to ReCOVER format
%172 last forecast
days_back =0; %4+(7*6);
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
zero_date = datetime(2021, 9, 1);
all_days = days(datetime(hosp_tab.date, 'InputFormat', 'yyyy/MM/dd') - zero_date);
bad_idx = all_days <= 0;
hosp_tab(bad_idx, :) = [];
all_days = all_days(~bad_idx);

maxt = max(all_days) - days_back;
fips = cell(ns, 1);
hosp_dat = nan(ns, maxt);

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
%%
for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end

    date_idx = all_days(idx);
    if date_idx <= maxt
        hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed(idx);
    end
end
%%
%Prepare matrix to collect coverage information if needed
%-------------------------
hosp_cov = nan(ns, maxt);
for idx = 1:size(hosp_tab, 1)
   
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end

    date_idx = all_days(idx);
    if date_idx <= maxt
        hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed(idx);
        hosp_cov(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed_coverage(idx);
    end
end
% ------------------------------
%%
H = table;
row = 1;
for i=1:size(hosp_dat,1) %State
   for j=1:size(hosp_dat,2) %Day
       if(j<=7)
           H(row,:)= {nan hosp_dat(i,j)};
%        elseif (j>=size(hosp_dat,2))
%            H(row,:) = {nan nan};
       else
            H(row,:)= {hosp_dat(i,j-7) hosp_dat(i,j)};
       end
%        H(row,:) = i;
%        H(row,:) = hosp_dat(i,j);
       row = row + 1;
   end
end

%%
% wks_ahead = 1;
for wks_ahead=1:4
    temp = H.Var2((7*wks_ahead+1):end);
    last_data_pnt = maxt + 1 - (7*wks_ahead); %173
    for i = last_data_pnt:maxt  %172
        temp(i:maxt:size(H,1)) = nan;
    end
    H(:,end+1) = array2table(temp);
end

%% Cumulative hospitalizations
days = maxt;%172;%maxt;
load flu_hospitalization_T-Old_predictors_S.mat
wks = ceil((days-11)/7 - 1); %total weeks that have passed excluding initial GT data
if (wks+1)*7 + 1 == size(predT,3)
    return;
end
wks = 0;
% predT = nan(120,56,1);

for x = wks:-1:0 %The x value should be 
    tic;
    T_full = max(find(any(~isnan(hosp_dat), 1)));
    hosp_cumu = cumsum(nan2zero(hosp_dat), 2);
    hosp_data_limit = T_full;

    smooth_factor = 14;
    hosp_cumu_s = smooth_epidata(cumsum(hosp_dat(:, 1:T_full).*hosp_cov(:, T_full)./(hosp_cov(:,1:T_full)+ 1e-10), 2, 'omitnan'), smooth_factor, 0, 1);
%     hosp_cumu_s = smooth_epidata(hosp_cumu(:, 1:T_full), smooth_factor, 1, 0);
    % % hosp_cumu_s = smooth_epidata(hosp_cumu(:, :), smooth_factor, 1, 0);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% COMMENT OUT BELOW THIS IF NOT FORECASTING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hosp_cumu_s = hosp_cumu_s(:,1:days);
    hosp_cumu = hosp_cumu(:,1:days);
    wks_back = x;%Each predictor has 4 wks of GT data
    num_dh_rates_sample = 3;
    T_full = days - wks_back*7;%added
    thisday = T_full;
    %For old-data gaps. Set horizon to be = last day - first day
    horizon = 35;%days; %wks_back*7;%+ 100; %days(all_dat(season+1).date(1) - all_dat(season).date(end)); %100; 
    ns = size(hosp_cumu_s, 1);
    hosp_cumu_s = hosp_cumu_s(:,1:end - wks_back*7);
    hosp_cumu = hosp_cumu(:,1:end - wks_back*7);

    %%
    num_dh_rates_sample = 5;
    rlags = [0 7];% 7];
    rlag_list = 1:length(rlags);

    un_array = popu*0 + [50 100 150];
    un_list = [1 2 3];
    halpha_list = 0.9:0.02:0.98;

    [X1, X2, X3] = ndgrid(un_list, rlag_list, halpha_list);
    scen_list = [X1(:), X2(:), X3(:)];
    %%
    tic;
    net_hosp_A = zeros(size(scen_list,1)*num_dh_rates_sample, ns, horizon);
    net_h_cell = cell(size(scen_list,1), 1);

    base_hosp = hosp_cumu(:, T_full);
    % if ~isempty(gcp('nocreate'))
    %     pctRunOnAll warning('off', 'all')
    % else
    %     parpool;
    %     pctRunOnAll warning('off', 'all')
    % end

    for simnum = 1:size(scen_list, 1)
        rr = rlags(scen_list(simnum, 2));
        un = un_array(:, scen_list(simnum, 1));
        hk = 2; hjp = 7; halpha = scen_list(simnum, 3);
        [hosp_rate, fC, ci_h] = var_ind_beta_un(hosp_cumu_s(:, 1:end-rr), 0, halpha, hk, un, popu, hjp, 0.95);
        temp_res = zeros(num_dh_rates_sample, ns, horizon);
        for rr = 1:num_dh_rates_sample
            this_rate = hosp_rate;

            if rr ~= (num_dh_rates_sample + 1)/2
                for cid=1:ns

                    this_rate{cid} = ci_h{cid}(:, 1) + (ci_h{cid}(:, 2) - ci_h{cid}(:, 1))*(rr-1)/(num_dh_rates_sample-1);

                end
            end

            [pred_hosps] = var_simulate_pred_un(hosp_cumu_s, 0, this_rate, popu, hk, horizon, hjp, un, base_hosp);

            h_start = 1;%maxt-T_full+1;
            temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        end
        net_h_cell{simnum} = temp_res;
        fprintf('.');
    end

    for simnum = 1:size(scen_list, 1)
%         idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
        net_hosp_A(simnum, :, :) = nanmean(net_h_cell{simnum},1);
    end
    clear net_*_cell
    fprintf('\n');
    fprintf('\n');
    toc
    %%
%     p = squeeze(net_hosp_A(13:18,:,:));
    p = squeeze(net_hosp_A(1:30,:,:));
    predictors = diff(p, 1, 3);
    lo = predictors(:,:,1:28);
    predT(:,:,end+1:end+7) = vertcat(lo(:,:,1:7),lo(:,:,8:14),lo(:,:,15:21),lo(:,:,22:end));
    %%
%     row = 1;
%     %6 predictors, 4 wks ahead = 24 fields total.
%     %Change varnames for each weak ahead
%     pred_table = table;%cell2table(cell(0,size(predictors,1)*4), 'VariableNames', {'Var8', 'Var9', 'Var10', 'Var11', 'Var12', 'Var13', 'Var14', 'Var15', 'Var16', 'Var17', 'Var18', 'Var19', 'Var20', 'Var21', 'Var22', 'Var23', 'Var24', 'Var25', 'Var26', 'Var27', 'Var28', 'Var29', 'Var30', 'Var31'});
%     first_pred = days- wks_back*7;
%     %Fix the repmat H to take from temp not H
%     if x == wks
%         temp = H;%old_data_no2020(1 + (season-1)*ns*days:ns*days*season,:); %H;for new data, for old go for old_data. %For 1st time
%     end
%     for i=1:size(predictors,2) %State
%        for j=1:size(predictors,3)+1% - weeks_ahead*7 %Day
%            if j < first_pred 
%                if x == wks
%                    iter1 = table(nan);
%                    for k=1:4
%                        pr = repmat(temp(row,3+k),1,size(pred_table,2)/4);
%                        iter1 = [iter1 pr];
%                    end
%                    pred_table(row,:) = iter1(:,2:end);
%                else
%                %uncomment for other iterations
%                 pred_table(row,:) = temp(row,:); %repmat(temp(row,4:7),1,size(pred_table,2));
%                end
%            else
%                pred_table(row,:) = {predictors(1,i,j+1*7 - first_pred) predictors(2,i,j+1*7 - first_pred) predictors(3,i,j+1*7 - first_pred) predictors(4,i,j+1*7 - first_pred) predictors(5,i,j+1*7 - first_pred) predictors(6,i,j+1*7 - first_pred) predictors(1,i,j+2*7 - first_pred) predictors(2,i,j+2*7 - first_pred) predictors(3,i,j+2*7 - first_pred) predictors(4,i,j+2*7 - first_pred) predictors(5,i,j+2*7 - first_pred) predictors(6,i,j+2*7 - first_pred) predictors(1,i,j+3*7 - first_pred) predictors(2,i,j+3*7 - first_pred) predictors(3,i,j+3*7 - first_pred) predictors(4,i,j+3*7 - first_pred) predictors(5,i,j+3*7 - first_pred) predictors(6,i,j+3*7 - first_pred) predictors(1,i,j+4*7 - first_pred) predictors(2,i,j+4*7 - first_pred) predictors(3,i,j+4*7 - first_pred) predictors(4,i,j+4*7 - first_pred) predictors(5,i,j+4*7 - first_pred) predictors(6,i,j+4*7 - first_pred)};
%            end
%            row = row + 1;
%        end
%     end
% 
%     temp = pred_table; %3-7 (thiswk->4wks ahead, then each pred at a time)
toc;
1;
end
%% Save data
%prepare GT incident, prev week, and targets

%prepare predictors
predT= predT(:,:,2:end);
save flu_hospitalization_T-Old_predictors_S.mat predT;
first = nan(56,11,4);
first(:,:,1) = hosp_dat(:,1:11); %%Get first few data points
first(:,:,2) = hosp_dat(:,12:22);
first(:,:,3) = hosp_dat(:,23:33);
first(:,:,4) = hosp_dat(:,34:44);
tempf = first;
tempf(:,:,1:30) = repmat(first(:,:,1),1,1,30);
tempf(:,:,31:60) = repmat(first(:,:,2),1,1,30);
tempf(:,:,61:90) = repmat(first(:,:,3),1,1,30);
tempf(:,:,91:120) = repmat(first(:,:,4),1,1,30);
tempf = permute(tempf,[3 1 2]);
predT = cat(3,tempf, predT);
% predT(:,:,end+1:end+padding) = nan(120,56,padding);
% predili = cat(1,GT,predT);
predILI = table;
for i=1:56
    predILI = [predILI; array2table(squeeze(predT(:,i,1:min(maxt,end)))')];
end

%% for old data After done with all seasons:
% old_data_no2020 = [old_data_no2020 seasonal_data];
%% 
% save flu_hospitalization_T-old_predictors.mat old_data_no2020;
%% When done with each week ahead
H = array2table([table2array(H) table2array(predILI)]);
%%
save flu_hospitalization_T-New_predictors_NEWS1.mat H;

%% Generate quantiles
num_ahead = horizon;%35;

quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_preds_deaths = zeros(length(popu), floor((num_ahead-1)/7), length(quant_deaths));
mean_preds_deaths = squeeze(nanmean(diff(net_hosp_A(:, :, 1:7:num_ahead), 1, 3), 1));

med_idx_d  = find(abs(quant_deaths-0.5)<0.001);
% hosp_cumu = hosp_cumu(:,1:days);

for cid = 1:length(popu)
    
    thisdata = squeeze(net_hosp_A(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
     dt = hosp_cumu; gt_lidx = size(dt, 2); 
    %extern_dat = diff(dt(cid, gt_lidx-35:7:gt_lidx))';
    extern_dat = diff(hosp_cumu(cid, 1:7:gt_lidx)') - diff(hosp_cumu_s(cid, 1:7:gt_lidx)'); %gt_lidx-35 to 1
    % [~, midx] = max(extern_dat); extern_dat(midx) = [];
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_deaths(cid, :);
    thisdata = [thisdata; repmat(extern_dat, [3 1])];    
    quant_preds_deaths(cid, :, :) = movmean(quantile(thisdata, quant_deaths)', 1, 1);
end
quant_preds_deaths = 0.5*(quant_preds_deaths+abs(quant_preds_deaths));

%% Plot
cidx = 1:56;
sel_idx = 4; %sel_idx = contains(countries, 'Florida');
dt = hosp_cumu(cidx, :);
dts = hosp_cumu_s(cidx, :);
thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, [1 7 12 17 23]), 1));
thismean = (nansum(mean_preds_deaths(sel_idx, :), 1));
gt_len = 20-wks;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
% gt_idx= (1:7:days);
gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
gts = diff(nansum(dts(sel_idx, gt_idx), 1))';

plot([gt gts]); hold on; 
plot((gt_len+1:gt_len+size(thisquant, 1)), [thisquant]); hold on;
plot((gt_len+1:gt_len+size(thisquant, 1)), [thismean], 'o'); hold off;
title(['Hospitalizations ' abvs{sel_idx}]);

