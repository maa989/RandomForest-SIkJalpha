clear;
popu = load('us_states_population_data.txt');
abvs = readcell('us_states_abbr_list2.txt');
ns = length(abvs);
old_data = readtable("ILINet.csv");
%% URL for certain year
download_path = ".\";
year = 2017;
sel_url ="https://predict.cdc.gov/api/v1/reports/projects/595d3c4545e6b6190e8f183c/forecasts/2017/regions/";
% year = 2018;
% sel_url = "https://predict.cdc.gov/api/v1/reports/projects/5ba5389fa983f303b832726b/forecasts/2018/regions/"; %Alabama/weeks/50
% year = 2019;
% sel_url ="https://predict.cdc.gov/api/v1/reports/projects/5d827e75fba2091084d47b96/forecasts/2019/regions/";
%%
% wks = [40:52 1:20];
%table (model wk RMSEsx4)
tic;
results = table;%cell2table(cell(0,6), 'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4'});
for wk = [44:52 1:20]
    res_mat = nan(56,4,3);
    for i = 1:ns
        total_P = zeros(1,4);
        ILI_GT = zeros(1,4);
        state = abvs{i};
        url = sel_url+state+"/weeks/"+int2str(wk);
        urlwrite(url,download_path+'dummy.json');
        fname = 'dummy.json'; 
        fid = fopen(fname); 
        raw = fread(fid,inf); 
        str = char(raw'); 
        fclose(fid); 
        val = jsondecode(str);
        if (size(val,1)==0)
            if(wk>40)
                disp(i)
            end
            continue;
        end
        if contains(state,"%20")
            state = strrep(state,"%20"," ");
        end
        %Evaluate each week for each team (RMSE, WIS)
        if wk < 44
            indx = ismember(old_data.REGION,state) & (old_data.YEAR == year + 1) & (wk < old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        elseif wk <= 48
            indx = ismember(old_data.REGION,state) & (old_data.YEAR == year) & (wk < old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        else
            w = mod(wk+4,52);
            indx = ismember(old_data.REGION,state) & ((wk < old_data.WEEK & old_data.YEAR == year) | (old_data.WEEK <= w & old_data.YEAR == year+1)) & ~isnan(old_data.ILITOTAL);
        end
        row = old_data(indx,:);
        if size(row,1)~=4
            continue;
        end
        for s=1:4
            ILI_GT(s) = row.x_UNWEIGHTEDILI(s);
            total_P(s) = row.TOTALPATIENTS(s); 
        end
%         ILI_GT = row.x_UNWEIGHTEDILI;
%         total_P = row.TOTALPATIENTS;
        models = unique({val.team});
        for j = 1:size(models,2)
            team_indx = ismember({val.team}, models{j});
            team = val(team_indx);
%             results(end,:).Team = team.team;
%             results(count,:).Week = wk;
            if size(team,1)~=6
                continue;
            end
            rmse_vals = nan(4,1);
            wis = nan(1,4,4);
            gt_vals = nan(4,1);
            total50 = nan(4,1);
            true50 = nan(4,1);
            total90 = nan(4,1);
            true90 = nan(4,1);

            for wk_ahead = 1:4
                forecast = team(2+wk_ahead).pointPrediction;
                bound90 = cell2mat(struct2cell(team(2+wk_ahead).x90_));
                bound50 = cell2mat(struct2cell(team(2+wk_ahead).x50_));
%                 res_mat(ns,wk_ahead,1) = team(2+wk_ahead).pointPrediction;
%                 res_mat(ns,wk_ahead,2) = cell2mat(struct2cell(team(2+wk_ahead).x90_));
%                 res_mat(ns,wk_ahead,3) = cell2mat(struct2cell(team(2+wk_ahead).x50_));

                if wk_ahead ==1
                    cov50 = bound50;
                    cov90 = bound90;
                else
                    cov50 = [cov50 bound50];
                    cov90 = [cov90 bound90];
                end
                
                qs = sort([bound50; bound90]);
                wis(1,:,wk_ahead) = qs'*total_P(wk_ahead)/100;
                rmse_vals(wk_ahead) = forecast*total_P(wk_ahead)/100;
                gt_vals(wk_ahead) = ILI_GT(wk_ahead)*total_P(wk_ahead)/100;
%                 wis(1,wk_ahead) = WIS(ILI_GT(wk_ahead)*total_P(wk_ahead)/100, qs'*total_P(wk_ahead)/100, 1.5);
%                 rmse_vals(wk_ahead) = RMSE(ILI_GT(wk_ahead)*total_P(wk_ahead)/100, forecast*total_P(wk_ahead)/100);
            end
            for w=1:size(ILI_GT,2)
                [true50(w),total50(w)] = Coverage(cov50(:,w),ILI_GT(w));
                [true90(w),total90(w)] = Coverage(cov90(:,w),ILI_GT(w));
            end

            tempt = table(convertCharsToStrings(team(1).team),convertCharsToStrings(state),wk,rmse_vals(1),rmse_vals(2),rmse_vals(3),rmse_vals(4),mat2cell(squeeze(wis(:,:,1)),1,4),mat2cell(squeeze(wis(:,:,2)),1,4),mat2cell(squeeze(wis(:,:,3)),1,4),mat2cell(squeeze(wis(:,:,4)),1,4),mat2cell(true50',1,4),mat2cell(total50',1,4),mat2cell(true90',1,4),mat2cell(total90',1,4),mat2cell(gt_vals',1,4), 'VariableNames',{'Team', 'State', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50True','C50Total','C90True', 'C90Total', 'GT'});
            results = [results;tempt];
        end
        
    end
end
toc;
%% Get state-mean per week
results_mean = table;
models = unique(results.Team);
for m = models'
    for wk = [44:52 1:20]
        indx = (results.Team == m) & (results.Week == wk);
        temp = results(indx,:);
        
        rmse_vals = nan(4,1);
        wis = nan(4,1);
        coverage50 = nan(4,1);
        coverage90 = nan(4,1);
        if(sum(indx)==0)
            tempt = table(m,wk,rmse_vals(1),rmse_vals(2),rmse_vals(3),rmse_vals(4),wis(1),wis(2),wis(3),wis(4),coverage50(1),coverage50(2),coverage50(3),coverage50(4),coverage90(1),coverage90(2),coverage90(3),coverage90(4), 'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
            results_mean = [results_mean;tempt];
            continue
        end
        
        GT = squeeze(cell2array(temp{:,end}))';
        for w=1:4
            rmse_vals(w) = RMSE(GT(:,w),temp{:,3+w});
            wis(w) =  WIS(GT(:,w), cell2mat(temp{:,7+w}), 1.5);
        end
%         rmse_vals = nanmean(temp{:,4:7},1);
%         wis = nanmean(temp{:,8:11},1);
        coverage50 = nansum(cell2mat(temp{:,12}),1)./nansum(cell2mat(temp{:,13}),1);
        coverage90 = nansum(cell2mat(temp{:,14}),1)./nansum(cell2mat(temp{:,15}),1);
        tempt = table(m,wk,rmse_vals(1),rmse_vals(2),rmse_vals(3),rmse_vals(4),wis(1),wis(2),wis(3),wis(4),coverage50(1),coverage50(2),coverage50(3),coverage50(4),coverage90(1),coverage90(2),coverage90(3),coverage90(4), 'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        results_mean = [results_mean;tempt];
    end
end
save("./ILI_data_res/"+ int2str(year)+"-"+int2str(year-2000+1)+"_2states", 'results_mean');