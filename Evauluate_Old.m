%% Read data in correct format. 
%% Read GT. So far, up till 02/19 GT,
clear;
popu = load('us_states_population_data.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(56, 1);
abvs = readcell('us_states_abbr_list.txt');
for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
abvs = readcell('us_states_abbr_list2.txt');
ns = length(abvs);
old_data = readtable("ILINet.csv");% First submission was on 02/07, need another week of data(Weekly: Quantiles
old_data_T = readtable("ILINet_Total.csv");
%% Read old data & find erros
year = 2019;
path1 = "D:\USC\Research\Flu\old_data_res\";
path = path1 + int2str(year) +"\";
Files=dir(path);
Evaluations = table;
Evaluations_T = table;
count = 1;

for f = 3:size(Files,1)
    file_name = Files(f).name;
    if strlength(file_name)==27 && year < 2018
        wk = str2num(['uint8(',file_name(3),')']); 
    elseif year < 2018
        wk = str2num(['uint8(',file_name(3:4),')']);
    elseif strlength(file_name)==28 && year >= 2018
        wk = str2num(['uint8(',file_name(4),')']); 
    else
        wk = str2num(['uint8(',file_name(4:5),')']);
    end
    
    %%Find GT
    ILI_GT = nan(56,4);
    ILI_TOTAL = zeros(1,4);
    for i = 1:ns
        state = abvs{i};
        
        fip = str2num(['uint8(',fips{i},')']);
        if(fip == 78) %Change to 52
            fip = 52;
        elseif(fip == 72) %Change to 3
            fip = 3;
        elseif(fip == 56) %Change to 7
            fip = 7;
        elseif(fip == 55) %Change to 43
            fip = 43;
%         elseif(isnan(data.location(i)))%Change to 14
%             fip = 14;         
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
            ILI_GT(fip,s) = row.ILITOTAL(s);
%             ILI_TOTAL(s) = ILI_TOTAL(s) + row.ILITOTAL(s);
%             total_P(fip,s) = total_P(s) + row.TOTALPATIENTS(s); 
        end     
    end

    if wk < 44
        indx = (old_data_T.YEAR == year + 1) & (wk < old_data_T.WEEK) & (old_data_T.WEEK <= wk+4) & ~isnan(old_data_T.ILITOTAL);
    elseif wk <= 48
        indx = (old_data_T.YEAR == year) & (wk < old_data_T.WEEK) & (old_data_T.WEEK <= wk+4) & ~isnan(old_data_T.ILITOTAL);
    else
        w = mod(wk+4,52);
        indx = ((wk < old_data_T.WEEK & old_data_T.YEAR == year) | (old_data_T.WEEK <= w & old_data_T.YEAR == year+1)) & ~isnan(old_data_T.ILITOTAL);
    end
    row = old_data_T(indx,:);
    if size(row,1)~=4
        continue;
    end
    for s=1:4
        ILI_TOTAL(s) = row.ILITOTAL(s);
    end 

    ILI_GT(14,:) = ILI_TOTAL;
  
    path2 = path+file_name;
    path3 = "D:\USC\Research\Flu\old_data_res\p" + int2str(year) + "\" + int2str(year)+"-"+int2str(wk)+"-SGroup-SIJ.csv";
    path4 = "D:\USC\Research\Flu\old_data_res\l" + int2str(year) + "\" + int2str(year-2008)+"-"+int2str(wk)+"-SGroup-LSBoost.csv";
    
    [flu_data_m, flu_data_q] = read_fluData(path2);
%     flu_data_m(14,:) = flu_data_m(14,:) - flu_data_m(12,:);
    flu_data_m2 = nan;
    flu_data_m3 = nan;
    try
        [flu_data_m3, flu_data_q3] = read_fluData(path4);
%         flu_data_m3(14,:) = flu_data_m3(14,:) - flu_data_m3(12,:);
        [flu_data_m2, flu_data_q2] = read_fluData(path3);
%         flu_data_m2(14,:) = flu_data_m2(14,:) - flu_data_m2(12,:);
    catch
    end
    %%Find RMSE (Mean based, if mean not available then use median)
    rmse_T = nan(1,size(ILI_GT,2));
    rmse_2 = nan(1,size(ILI_GT,2));
    rmse_3 = nan(1,size(ILI_GT,2));
    
    for j = 1:size(ILI_GT,2)
        rmse_T(j) = RMSE(ILI_GT(14,j),flu_data_m(14,j));
%         wis_T(1,j) = WIS(GT(1,j), qs(1,:,j), 11);
        if(~isnan(flu_data_m2))
            rmse_T2(j) = RMSE(ILI_GT(14,j),flu_data_m2(14,j));
        end
        if(~isnan(flu_data_m3))
            rmse_T3(j) = RMSE(ILI_GT(14,j),flu_data_m3(14,j));
        end
    end
    temp = [flu_data_m(1:13,:); flu_data_m(15:end,:)];
    if(~isnan(flu_data_m2))
        temp2 = [flu_data_m2(1:13,:); flu_data_m2(15:end,:)];
    end
    if(~isnan(flu_data_m3))
        temp3 = [flu_data_m3(1:13,:); flu_data_m3(15:end,:)];
    end
    tempGT = [ILI_GT(1:13,:); ILI_GT(15:end,:)];
    rmse = nan(1,size(ILI_GT,2));
    rmse2 = nan(1,size(ILI_GT,2));
    rmse3 = nan(1,size(ILI_GT,2));

    for j = 1:size(ILI_GT,2)
        rmse(j) = RMSE(nanmean(tempGT(:,j),1),nanmean(temp(:,j),1));
        if(~isnan(flu_data_m2))
            rmse2(j) = RMSE(nanmean(tempGT(:,j),1),nanmean(temp2(:,j),1));
        end
        if(~isnan(flu_data_m3))
            rmse3(j) = RMSE(nanmean(tempGT(:,j),1),nanmean(temp3(:,j),1));
        end
    end
    

    %Change temp to quantiles
    temp = [flu_data_q(1:13,:,:); flu_data_q(15:end,:,:)];
    if(~isnan(flu_data_q2))
        temp2 = [flu_data_q2(1:13,:,:); flu_data_q2(15:end,:,:)];
    end
    if(~isnan(flu_data_q3))
        temp3 = [flu_data_q3(1:13,:,:); flu_data_q3(15:end,:,:)];
    end

    %Coverage
    coverage50 = Coverage2(nanmean(temp,1),nanmean(tempGT,1),0.5,1)';
    coverage90 = Coverage2(nanmean(temp,1),nanmean(tempGT,1),0.9,1)';

    coverage50_T = Coverage2(flu_data_q(14,:,:),ILI_GT(14,:,:),0.5,1)';
    coverage90_T = Coverage2(flu_data_q(14,:,:),ILI_GT(14,:,:),0.9,1)';
    
    if(~isnan(flu_data_q2))
        coverage502 = Coverage2(nanmean(temp2,1),nanmean(tempGT,1),0.5,1)';
        coverage902 = Coverage2(nanmean(temp2,1),nanmean(tempGT,1),0.9,1)';
    
        coverage50_2 = Coverage2(flu_data_q2(14,:,:),ILI_GT(14,:,:),0.5,1)';
        coverage90_2 = Coverage2(flu_data_q2(14,:,:),ILI_GT(14,:,:),0.9,1)';
    end

    if(~isnan(flu_data_q3))
        coverage503 = Coverage2(nanmean(temp3,1),nanmean(tempGT,1),0.5,1)';
        coverage903 = Coverage2(nanmean(temp3,1),nanmean(tempGT,1),0.9,1)';
    
        coverage50_3 = Coverage2(flu_data_q3(14,:,:),ILI_GT(14,:,:),0.5,1)';
        coverage90_3 = Coverage2(flu_data_q3(14,:,:),ILI_GT(14,:,:),0.9,1)';
    end

    %Implement WIS here
    wis = nan(1,size(ILI_GT,2));
    wis2 = nan(1,size(ILI_GT,2));
    wis3 = nan(1,size(ILI_GT,2));

    wis_T = nan(1,size(ILI_GT,2));
    wis_2 = nan(1,size(ILI_GT,2));
    wis_3 = nan(1,size(ILI_GT,2));
    for j = 1:size(ILI_GT,2)
        GT = nanmean(tempGT,1);
        qs = nanmean(temp,1);
        wis(1,j) = WIS(GT(1,j), qs(1,:,j), 11);
        wis_T(1,j) = WIS(ILI_GT(14,j), flu_data_q(14,:,j), 11);
        if(~isnan(flu_data_q3))
            qs2 = nanmean(temp2,1);
            wis2(1,j) = WIS(GT(1,j), qs2(1,:,j), 11);
            wis_2(1,j) = WIS(ILI_GT(14,j), flu_data_q2(14,:,j), 11);
        end
        if(~isnan(flu_data_q2))
            qs3 = nanmean(temp3,1);
            wis3(1,j) = WIS(GT(1,j), qs3(1,:,j), 11);
            wis_3(1,j) = WIS(ILI_GT(14,j), flu_data_q3(14,:,j), 11);
        end
    end

    %%append to table
    tempt = table("randomForest",wk,rmse(1),rmse(2),rmse(3),rmse(4),wis(1),wis(2),wis(3),wis(4),coverage50,coverage90,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
    Evaluations = [Evaluations;tempt];
    
    temp_T = table("randomForest",wk,rmse_T(1),rmse_T(2),rmse_T(3),rmse_T(4),wis_T(1),wis_T(2),wis_T(3),wis_T(4),coverage50_T,coverage90_T,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
    Evaluations_T = [Evaluations_T;temp_T];

    if(~isnan(flu_data_m2))
        tempt = table("SIkJalpha",wk,rmse2(1),rmse2(2),rmse2(3),rmse2(4),wis2(1),wis2(2),wis2(3),wis2(4),coverage502,coverage902,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
        Evaluations = [Evaluations;tempt];
    
        temp_T = table("SIkJalpha",wk,rmse_T2(1),rmse_T2(2),rmse_T2(3),rmse_T2(4),wis_2(1),wis_2(2),wis_2(3),wis_2(4),coverage50_2,coverage90_2,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
        Evaluations_T = [Evaluations_T;temp_T];
    end

    if(~isnan(flu_data_m3))
        tempt = table("LSBoost",wk,rmse3(1),rmse3(2),rmse3(3),rmse3(4),wis3(1),wis3(2),wis3(3),wis3(4),coverage503,coverage903,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
        Evaluations = [Evaluations;tempt];
    
        temp_T = table("LSBoost",wk,rmse_T3(1),rmse_T3(2),rmse_T3(3),rmse_T3(4),wis_3(1),wis_3(2),wis_3(3),wis_3(4),coverage50_3,coverage90_3,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
        Evaluations_T = [Evaluations_T;temp_T];
    end
end

load(path1 + int2str(year)+"-"+int2str(year-2000+1)+"_2US.mat");
data_T = [results; Evaluations_T];
load(path1+ int2str(year)+"-"+int2str(year-2000+1)+"_2states.mat");
data = [results_mean; Evaluations];
%2018-2019 LOS Alamos (["LANL_Danteplus"]), before ["DELPHI-Epicast"],["Delphi-Epicast-Mturk"],["Delphi-Stat"] 
%%
metric = "RMSE";
teams = unique(data_T.Team);
figure; %tiledlayout(2, 2)
AvgEvalT = table;
for wk = 1:4
    nexttile;
    l = string.empty;
    for t = ["randomForest" "LSBoost" "SIkJalpha" "LANL_Danteplus" "LANL-DBM" "LANL-DBMplus" "DELPHI-Epicast" "Delphi-Epicast" "Delphi-Epicast-Mturk" "Delphi-Stat"]
        indx = (data_T.Team==t) & (data_T.Week < 14 | data_T.Week>43); %12 for 2019
        to = data_T(indx,:);
        
        if isempty(to) || sum(isnan(to.RMSE1))>11
            continue;
        end
        
        if(size(to,1)>19)
            to = to(1:19,:); % omment for 2019
        end
        
        to = sortrows(to,2);
        if wk==4
%             avg= nanmean(to{:,3:6},'all');
%             avgW= nanmedian(to{:,7:10},'all');
            avg= nanmean(to{:,6},'all');
            avgW= nanmean(to{:,10},'all');
            avgC50 = nanmean(to{1:end-3,11});
            avgC90= nanmean(to{1:end-3,12});
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'RMSE','WIS','C50', 'C90'});
            AvgEvalT = [AvgEvalT;tempavg];
        end

        if(t=="randomForest")
            l(end+1) = t;
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-o','LineWidth',2); hold on;
        elseif(t == "LSBoost")
            if(metric=="WIS")
                continue
            end
            l(end+1) = t;
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-*','LineWidth',2); hold on;
        elseif(t == "SIkJalpha")
            l(end+1) = t;
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-x','LineWidth',2); hold on;
        else
            try
                plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'LineWidth',0.5); hold on; %nan for 2017
                l(end+1) = t;
            catch
            end
        end
    end
    hold off
    ylabel(metric);
    xlabel("MMR Week");
    title(wk+ " Week ahead forecast");
    set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    legend(l);
% ax.XTickLabel = [44:52 1:13]';
%     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
end
sgtitle(year + " Total US");
% ax = axes('XLimMode', 'manual', 'XTickMode', 'manual'); 
%% By state
metric = "RMSE";
teams = unique(data.Team);
figure; tiledlayout(2, 2)
AvgEval = table;
for wk = 1:4
    nexttile;
    l = string.empty;
    for t = ["randomForest" "LSBoost" "SIkJalpha" "LANL_Danteplus" "LANL-DBM" "LANL-DBMplus" "DELPHI-Epicast" "Delphi-Epicast" "Delphi-Epicast-Mturk" "Delphi-Stat"]
        indx = (data.Team==t) & (data.Week < 14 | data.Week>43);
        to = data(indx,:);

        if isempty(to) || sum(isnan(to.RMSE1))>11
            continue;
        end
        l(end+1) = t;
%         to = to(1:22,:);
        to = sortrows(to,2);
        if wk==1
            avg= nanmedian(to{:,3:6},'all');
            avgW= nanmedian(to{:,7:10},'all');
            avgC50 = nanmedian(to{1:end-3,11});
            avgC90= nanmedian(to{1:end-3,12});
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'RMSE','WIS','C50', 'C90'});
            AvgEval = [AvgEval;tempavg];
        end

        
        if(t=="randomForest")
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-o'); hold on;
        elseif(t == "LSBoost" )
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-*'); hold on;
        elseif(t == "SIkJalpha")
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-x'); hold on;
        else
            plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")]); hold on; %nan for 2017
        end
    end
    hold off
    ylabel(metric);
    xlabel("MMR Week");
    title(wk+ " Week ahead forecast");
    set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    legend(l);
% ax.XTickLabel = [44:52 1:13]';
%     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
end
sgtitle(year + " State Mean");

%% Ranking
clear s;
for i = 1:size(Evaluations,2)
    s(i) = mean(Evaluations(i).RMSE); %struct('model', Evaluations(i).model, 'RMSE')
end
[x,idx]=sort(s);
%s=Evaluations(idx);
Evaluations2 = struct2table(Evaluations);

Evaluations2.RMSE_mean = s';
idx = startsWith(Evaluations2.model, date_of_submission);
s2  =sortrows(Evaluations2(idx, :), 'RMSE_mean');
%%
s = data;
s = sortrows(s,3);
%%
s = data_T;
s = sortrows(s,3);