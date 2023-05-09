clear
load flu_history2%flu_history
popu = load('us_states_population_data.txt');
% load Coverage.mat;
seasons_back = 1; %1 starts at 2015-2016
year = 2020-seasons_back; %2016-seasons_back;
yr = 12-seasons_back;%8-seasons_back;
%% Process data 
%%
old_data = table([],[]);
old_data_P = nan(239,7); %daysxseasons
for i = 1:yr
    data_last = all_dat(i);
    data_last = timetable(data_last.date,data_last.hosp_weekly);
    data_last = retime(data_last,'daily', 'fillwithmissing');
    data_last.Var1 = data_last.Var1/7;
    data_last = fillmissing(data_last, "next");
    data_last= table(days(data_last.Time - data_last.Time(1) + 1), data_last.Var1);
    if i == 1
        old_data = [data_last; old_data];
    else
        old_data = [old_data;data_last];
    end
    old_data_P(1:size(data_last,1),i) = data_last.Var2;
end
% old_data_20 = [old_data;data_2020];
% old_data_P_20 = old_data_P;
% old_data_P_20(1:size(data_2020.Var2),12) = data_2020.Var2;
%OPTION1 for filling missing data (Can just add 2020-2022 data & do same)
%This includes 2019-2020 bad data
%old_data = retime(old_data,'daily', 'makima'); %spline
%%
% plot(old_data.Var1, old_data.Var2); hold on;
% % Load population data
popu = load('us_states_population_data.txt');
abvs = readcell('us_states_abbr_list.txt');
ns = length(abvs);
%%
%Change per 100k to state (States x days) RECOVER format
old_hosp_data =  (popu/100000)*old_data.Var2';
old_hosp_data_P =  nan(1, size(old_data_P,1),size(old_data_P,2));
old_hosp_data_P(1,:,:) = old_data_P;
old_hosp_data_P = (popu/100000).*old_hosp_data_P;
%% change data to 56x239xseasonsx(wkbhnd, incwk, 1wk,2wk,3k,w4k)
old_hosp_data_P(:,:,:,1:6) = repmat(old_hosp_data_P,1,1,1,6);
old_hosp_data_P(:,:,:,1) = [nan(56,7,yr,1) old_hosp_data_P(:,1:end-7,:,1)];
old_hosp_data_P(:,:,:,3)= [old_hosp_data_P(:,8:end,:,2) nan(56,7,yr,1)];
old_hosp_data_P(:,:,:,4)= [old_hosp_data_P(:,15:end,:,2) nan(56,14,yr,1)];
old_hosp_data_P(:,:,:,5)= [old_hosp_data_P(:,22:end,:,2) nan(56,21,yr,1)];
old_hosp_data_P(:,:,:,6)= [old_hosp_data_P(:,29:end,:,2) nan(56,28,yr,1)];
%% Predictors
PedILI_Old = table;
for y=1:yr
    hosp_dat = old_hosp_data_P(:,:,y,2);
%     hosp_dat = ILI_GT_daily(:,:,1)';
    
    predT = nan(120,56,1);
    num_dh_rates_sample = 3;
    wks = 26;%26;%23; %should remain <= than X:19 (i.e total days - wks*7 = 40). for 239: 28wks
    for x = wks:-1:1 %The x value should be 
        T_full = max(find(any(~isnan(hosp_dat), 1)));
        days = T_full;%172;%maxt;
        % Cumulative hospitalizations
        hosp_cumu = cumsum(nan2zero(hosp_dat), 2);
        hosp_data_limit = T_full;
        
        smooth_factor = 14;
        hosp_cumu_s = smooth_epidata(cumsum(hosp_dat(:, 1:T_full), 2, 'omitnan'), smooth_factor, 0, 1);
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
    GT = squeeze(old_hosp_data_P(:,:,y,:)); 
    % tempGT = GT;
    padding = 239 - size(GT,2);
    GT(:,end+1:end+padding,:) = nan(56,padding,6);
    GT = permute(GT,[3 1 2]);
    
    padding = 239-size(predT,3) - 20;
    %prepare predictors
    predT= predT(:,:,2:end);
    first = squeeze(old_hosp_data_P(:,1:21,y,3:6)); %%Get first few weeks
    tempf = first;
    tempf(:,:,1:30) = repmat(first(:,:,1),1,1,30);
    tempf(:,:,31:60) = repmat(first(:,:,2),1,1,30);
    tempf(:,:,61:90) = repmat(first(:,:,3),1,1,30);
    tempf(:,:,91:120) = repmat(first(:,:,4),1,1,30);
    tempf = permute(tempf,[3 1 2]);
    predT = cat(3,tempf, predT);
    predT(:,:,end+1:end+padding) = nan(120,56,padding);
    predili = cat(1,GT,predT);
    predILI_y = table;
    for i=1:56
        predILI_y = [predILI_y; array2table(squeeze(predili(:,i,:))')];
    end

    PedILI_Old = [PedILI_Old; predILI_y];
end


%%
save("flu_hospitalization_TOP-New_predictorsFluSurv2.mat", 'PedILI_Old');