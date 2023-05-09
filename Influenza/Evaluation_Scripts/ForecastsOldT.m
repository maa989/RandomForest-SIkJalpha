clear;
popu = load('us_states_population_data.txt');
abvs = readcell('us_states_abbr_list2.txt');
ns = length(abvs);
old_data = readtable("ILINet_Total.csv");
%% URL for certain year
download_path = "D:\USC\Research\Flu\";
year = 2016;
sel_url ="https://predict.cdc.gov/api/v1/reports/projects/57f3f440123b0f563ece2576/forecasts/2016/regions/US%20National/weeks/";
% year = 2017;
% sel_url ="https://predict.cdc.gov/api/v1/reports/projects/59973fe26f7559750d84a843/forecasts/2017/regions/US%20National/weeks/";
% year = 2018;
% sel_url = "https://predict.cdc.gov/api/v1/reports/projects/5ba1504e5619f003acb7e18f/forecasts/2018/regions/US%20National/weeks/"; %Alabama/weeks/50
% year = 2019;
% sel_url ="https://predict.cdc.gov/api/v1/reports/projects/5d8257befba2091084d47b4c/forecasts/2019/regions/US%20National/weeks/";
    %%
% wks = [40:52 1:20];
%table (model wk RMSEsx4)
tic;
results = table;%cell2table(cell(0,6), 'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4'});
for wk = [44:52 1:20]
    total_P = zeros(1,4);
    ILI_GT = zeros(1,4);
    url = sel_url+int2str(wk);
    urlwrite(url,download_path+'dummy.json');
    fname = 'dummy.json'; 
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);
    if (size(val,1)==0)
        continue;
    end
    for i = 1:ns
        state = abvs{i};
        if contains(state,"%20")
            state = strrep(state,"%20"," ");
        end
        %Evaluate each week for each team (RMSE, WIS)
        if wk < 44
            indx = (old_data.YEAR == year + 1) & (wk < old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        elseif wk <= 48
            indx = (old_data.YEAR == year) & (wk < old_data.WEEK) & (old_data.WEEK <= wk+4) & ~isnan(old_data.ILITOTAL);
        else
            w = mod(wk+4,52);
            indx = ((wk < old_data.WEEK & old_data.YEAR == year) | (old_data.WEEK <= w & old_data.YEAR == year+1)) & ~isnan(old_data.ILITOTAL);
        end
        row = old_data(indx,:);
        if size(row,1)~=4
            continue;
        end
        for s=1:4
            ILI_GT(s) = row.ILITOTAL(s);
            total_P(s) = row.TOTALPATIENTS(s); 
        end     
    end
    models = unique({val.team});
    for j = 1:size(models,2)
        team_indx = ismember({val.team}, models{j});
        team_indx2 = ismember({val.target},"1 wk ahead") |  ismember({val.target},"2 wk ahead") | ismember({val.target},"3 wk ahead") | ismember({val.target},"4 wk ahead");
        team = val(team_indx&team_indx2);
        if size(team,1)~=4
            continue;
        end
        rmse_vals = nan(4,1);
        for wk_ahead = 1:4
            forecast = team(wk_ahead).pointPrediction;
            bound90 = cell2mat(struct2cell(team(wk_ahead).x90_));
            bound50 = cell2mat(struct2cell(team(wk_ahead).x50_));
            
            if wk_ahead ==1
                cov50 = bound50*total_P(wk_ahead)/100;
                cov90 = bound90*total_P(wk_ahead)/100;
            else
                cov50 = [cov50 bound50*total_P(wk_ahead)/100];
                cov90 = [cov90 bound90*total_P(wk_ahead)/100];
            end

            qs = sort([bound50; bound90]);
            wis(1,wk_ahead) = WIS(ILI_GT(wk_ahead), qs'*total_P(wk_ahead)/100, 1.5);    
            rmse_vals(wk_ahead) = RMSE(ILI_GT(wk_ahead), forecast*total_P(wk_ahead)/100);
        end
        [true50,total50] = Coverage(cov50,ILI_GT);
        [true90,total90] = Coverage(cov90,ILI_GT);
        coverage50 = true50/total50;
        coverage90 = true90/total90;

        tempt = table(convertCharsToStrings(team(1).team),wk,rmse_vals(1),rmse_vals(2),rmse_vals(3),rmse_vals(4),wis(1),wis(2),wis(3),wis(4),coverage50, coverage90, 'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
        results = [results;tempt];
    end
end
toc;
save("./ILI_data_res/"+ int2str(year)+"-"+int2str(year-2000+1)+"_2US", 'results');