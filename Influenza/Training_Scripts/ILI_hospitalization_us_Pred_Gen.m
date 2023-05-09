clear
% load flu_hospitalization_T-old_predictors.mat%flu_hospitalization_T.mat
%2010-2019
old_data = readtable("ILINet.csv");
old_data_T = readtable("ILINet_Total.csv");
% load flu_hospitalization_T-New_predictors.mat%flu_hospitalization_T-New.mat
% load RMSE.mat
popu = load('us_states_population_data.txt');
% load Coverage.mat;
seasons_back = 8; %1 starts at 2019-2020
abvs = readcell('us_states_abbr_list.txt');
ns = length(abvs);
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(ns, 1);
for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
abvs = readcell('us_states_abbr_list2.txt');
%% Use diff GT data (ILINET)
year = 2020 - seasons_back;
%%Find GT
ILI_GT = nan(29,57,5);
ILI_cov = nan(29,57,5);
ILI_TOTAL = zeros(1,4);
for i = 1:ns
    count = 1;
    for wk = [40:52 1:20]
        state = abvs{i};
        
        fip = i;  
        if contains(state,"%20")
            state = strrep(state,"%20"," ");
        end
        %Evaluate each week for each team (RMSE, WIS)
        if wk < 40
            indx = ismember(old_data.REGION,state) & (old_data.YEAR == year + 1) & (wk <= old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        elseif wk <= 48
            indx = ismember(old_data.REGION,state) & (old_data.YEAR == year) & (wk <= old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        else
            w = mod(wk+4,52);
            indx = ismember(old_data.REGION,state) & ((wk <= old_data.WEEK & old_data.YEAR == year) | (old_data.WEEK <= w & old_data.YEAR == year+1)) & ~isnan(old_data.ILITOTAL);
        end
        row = old_data(indx,:);
        if size(row,1)~=5
            continue;
        end
        for s=1:5
            ILI_GT(count,fip,s) = row.ILITOTAL(s);
            ILI_cov(count,fip,s) = row.NUM_OFPROVIDERS(s);
        end 
        count = count + 1;
    end
end
%% total
count = 1;
for wk = [40:52 1:20]
    %Evaluate each week for each team (RMSE, WIS)
    if wk < 40
        indx = (old_data_T.YEAR == year + 1) & (wk <= old_data_T.WEEK) & (old_data_T.WEEK <= wk+4) & ~isnan(old_data_T.ILITOTAL);
    elseif wk <= 48
        indx = (old_data_T.YEAR == year) & (wk <= old_data_T.WEEK) & (old_data_T.WEEK <= wk+4) & ~isnan(old_data_T.ILITOTAL);
    else
        w = mod(wk+4,52);
        indx = ((wk <= old_data_T.WEEK & old_data_T.YEAR == year) | (old_data_T.WEEK <= w & old_data_T.YEAR == year+1)) & ~isnan(old_data_T.ILITOTAL);
    end
    row = old_data_T(indx,:);
    if size(row,1)~=5
        continue;
    end
    for s=1:5
        ILI_GT(count,57,s) = row.ILITOTAL(s);
        ILI_cov(count,57,s) = row.NUM_OFPROVIDERS(s);
    end 
    count = count + 1;
end
%% change data to daily
ILI_GT_daily = nan(29*7,57,5);
ILI_cov_daily = nan(29*7,57,5);
for i=1:5
    for w=1:29
        ILI_GT_daily((w-1)*7+1:(w-1)*7+7,:,:) = repmat(ILI_GT(w,:,:)/7,7,1);
        ILI_cov_daily((w-1)*7+1:(w-1)*7+7,:,:) = repmat(ILI_cov(w,:,:),7,1);
    end
end
% ------------------------------
%%
hosp_dat = ILI_GT_daily(:,:,1)';
hosp_cov = ILI_cov_daily(:,:,1)';

% Add prev week data
ILI_GT_daily(:,:,2:6) = ILI_GT_daily;
ILI_GT_daily(:,:,1) = [nan(57,7) hosp_dat(:,1:end-7)]';
ILI_cov_daily(:,:,2:6) = ILI_cov_daily;
ILI_cov_daily(:,:,1) = [nan(57,7) hosp_cov(:,1:end-7)]';

%%
num_dh_rates_sample = 5;
rlags = [0 7];% 7];
rlag_list = 1:length(rlags);
popu(57) = sum(popu(1:56));
un_array = popu*0 + [16 32 64];%[50 100 150];
un_list = [1 2 3];
halpha_list = 0.9:0.02:0.98;

[X1, X2, X3] = ndgrid(un_list, rlag_list, halpha_list);
scen_list = [X1(:), X2(:), X3(:)];

predT = nan(120,57,1);
num_dh_rates_sample = 3;
wks = 26;%23; %should remain <= than X:19 (i.e total days - wks*7 = 40). for 239: 28wks
for x = wks:-1:1 %The x value should be 
    T_full = max(find(any(~isnan(hosp_dat), 1)));
    days = T_full;%172;%maxt;
    % Cumulative hospitalizations
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
    T_full = days - wks_back*7;%added
    thisday = T_full;
    %For old-data gaps. Set horizon to be = last day - first day
    horizon = 35;%days; %wks_back*7;%+ 100; %days(all_dat(season+1).date(1) - all_dat(season).date(end)); %100; 
    ns = size(hosp_cumu_s, 1);
    hosp_cumu_s = hosp_cumu_s(:,1:end - wks_back*7);
    hosp_cumu = hosp_cumu(:,1:end - wks_back*7);

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
        halpha = scen_list(simnum, 3);
        hk = 2; hjp = 7; 
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
%         net_hosp_A(idx, :, :) = net_h_cell{simnum};
        net_hosp_A(simnum, :, :) = nanmean(net_h_cell{simnum},1);
    end
%     clear net_*_cell
    fprintf('\n');
    fprintf('\n');
    p = squeeze(net_hosp_A(1:30,:,:)); %30 predictors
    predictors = diff(p, 1, 3);
    %30 predictors, 4 wks ahead = 120 fields total.
    lo = predictors(:,:,1:28);
    predT(:,:,end+1:end+7) = vertcat(lo(:,:,1:7),lo(:,:,8:14),lo(:,:,15:21),lo(:,:,22:end));
%     disp("TEST");

%     temp = pred_table;
    toc
end
%% Save data
%prepare GT incident, prev week, and targets
GT = ILI_GT_daily; 
% tempGT = GT;
padding = 239 - days;
GT(end+1:end+padding,:,:) = nan(padding,57,6);
GT = permute(GT,[3 2 1]);

%prepare predictors
predT= predT(:,:,2:end);
first = ILI_GT_daily(1:21,:,3:6); %%Get first few weeks
tempf = first;
tempf(:,:,1:30) = repmat(first(:,:,1),1,1,30);
tempf(:,:,31:60) = repmat(first(:,:,2),1,1,30);
tempf(:,:,61:90) = repmat(first(:,:,3),1,1,30);
tempf(:,:,91:120) = repmat(first(:,:,4),1,1,30);
tempf = permute(tempf,[3 2 1]);
predT(:,:,end+1:end+padding) = nan(120,57,padding);
predT = cat(3,tempf, predT);
predili = cat(1,GT,predT);
predILI = table;
for i=1:57
    predILI = [predILI; array2table(squeeze(predili(:,i,:))')];
end


%%
save("flu_hospitalization_TOP-New_predictors2" + int2str(year)+".mat", 'predILI');

%% Visualization
% cidx = 1:56;
% sel_idx = 1:56; %sel_idx = contains(countries, 'Florida');
% dt = hosp_cumu(cidx, :);
% dts = hosp_cumu_s(cidx, :);
% thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, [1 7 12 17 23]), 1))*100000/sum(popu(sel_idx));
% thismean = (nansum(mean_preds_deaths(sel_idx, :), 1))*100000/sum(popu(sel_idx));
% gt_len = 15;
% gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
% gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
% gts = diff(nansum(dts(sel_idx, gt_idx), 1))';
% 
% plot([gt gts]*100000/sum(popu(sel_idx))); hold on; 
% plot((gt_len+1:gt_len+size(thisquant, 1)), [thisquant]); hold on;
% plot((gt_len+1:gt_len+size(thisquant, 1)), [thismean], 'o'); hold off;
% title(['Hospitalizations ' abvs{sel_idx}]);