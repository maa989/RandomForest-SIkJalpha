%% Read Ground Truth
clear;
year = 2019; %ENTER YEAR FOR EVALUATIONS (2017-2019)
path1 = "..\ILI_data_res\"; %% ENTER PATH TO ILI RESULTS HERE
popu = load('us_states_population_data.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(56, 1);
abvs = readcell('us_states_abbr_list.txt');
for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
abvs = readcell('us_states_abbr_list2.txt');
ns = length(abvs);
old_data = readtable("ILINet.csv");
old_data_T = readtable("ILINet_Total.csv");
%% Read ILI Predictions & find erros
path = path1 + int2str(year) +"\";
Files=dir(path);
Evaluations = table;
Evaluations_T = table;
count = 1;

for f = 3:size(Files,1)
    file_name = Files(f).name;
    if strlength(file_name)==27 && year < 2019
        wk = str2num(['uint8(',file_name(3),')']); 
    elseif year <= 2018
        wk = str2num(['uint8(',file_name(3:4),')']);
    elseif strlength(file_name)==28
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
    path3 = path1+ "p" + int2str(year) + "\" + int2str(year)+"-"+int2str(wk)+"-SGroup-SIJ.csv";
    path4 = path1+ "l" + int2str(year) + "\" + int2str(year-2009)+"-"+int2str(wk)+"-SGroup-RandomForest.csv";
    
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
    tempGT = [ILI_GT(1:13,:); ILI_GT(15:54,:)];
    rmse = nan(1,size(ILI_GT,2));
    rmse2 = nan(1,size(ILI_GT,2));
    rmse3 = nan(1,size(ILI_GT,2));

    for j = 1:size(ILI_GT,2)
        rmse(j) = RMSE(tempGT(:,j),temp(:,j));
        if(~isnan(flu_data_m2))
            rmse2(j) = RMSE(tempGT(:,j),temp2(:,j));
        end
        if(~isnan(flu_data_m3))
            rmse3(j) = RMSE(tempGT(:,j),temp3(:,j));
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
    for w=1:size(tempGT,2)
        coverage50(w) = Coverage2(temp(:,:,w),tempGT(:,w),0.5,1)';
        coverage90(w) = Coverage2(temp(:,:,w),tempGT(:,w),0.9,1)';

        coverage50_T(w) = Coverage2(flu_data_q(14,:,w),ILI_GT(14,w),0.5,1)';
        coverage90_T(w) = Coverage2(flu_data_q(14,:,w),ILI_GT(14,w),0.9,1)';
    end

    if(~isnan(flu_data_q2))
        for w=1:size(tempGT,2)
            coverage502(w) = Coverage2(temp2(:,:,w),tempGT(:,w),0.5,1)';
            coverage902(w) = Coverage2(temp2(:,:,w),tempGT(:,w),0.9,1)';
    
            coverage50_2(w) = Coverage2(flu_data_q2(14,:,w),ILI_GT(14,w),0.5,1)';
            coverage90_2(w) = Coverage2(flu_data_q2(14,:,w),ILI_GT(14,w),0.9,1)';
        end
    end

    if(~isnan(flu_data_q3))
        for w=1:size(tempGT,2)
            coverage503(w) = Coverage2(temp3(:,:,w),tempGT(:,w),0.5,1)';
            coverage903(w) = Coverage2(temp3(:,:,w),tempGT(:,w),0.9,1)';
    
            coverage50_3(w) = Coverage2(flu_data_q3(14,:,w),ILI_GT(14,w),0.5,1)';
            coverage90_3(w) = Coverage2(flu_data_q3(14,:,w),ILI_GT(14,w),0.9,1)';
        end
    end

    %WIS 
    wis = nan(1,size(ILI_GT,2));
    wis2 = nan(1,size(ILI_GT,2));
    wis3 = nan(1,size(ILI_GT,2));

    wis_T = nan(1,size(ILI_GT,2));
    wis_2 = nan(1,size(ILI_GT,2));
    wis_3 = nan(1,size(ILI_GT,2));
    for j = 1:size(ILI_GT,2)

        wis(1,j) = WIS(tempGT(:,j), squeeze(temp(:,:,j)), 11);
        wis_T(1,j) = WIS(ILI_GT(14,j), flu_data_q(14,:,j), 11);
        if(~isnan(flu_data_q3))
            wis2(1,j) = WIS(tempGT(:,j), squeeze(temp2(:,:,j)), 11);
            wis_2(1,j) = WIS(ILI_GT(14,j), flu_data_q2(14,:,j), 11);
        end
        if(~isnan(flu_data_q2))
            wis3(1,j) = WIS(tempGT(:,j), squeeze(temp3(:,:,j)), 11);
            wis_3(1,j) = WIS(ILI_GT(14,j), flu_data_q3(14,:,j), 11);
        end
    end

    %%append to table
    tempt = table("randomForest",wk,rmse(1),rmse(2),rmse(3),rmse(4),wis(1),wis(2),wis(3),wis(4),coverage50(1),coverage50(2),coverage50(3),coverage50(4),coverage90(1),coverage90(2),coverage90(3),coverage90(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
    Evaluations = [Evaluations;tempt];
    
    temp_T = table("randomForest",wk,rmse_T(1),rmse_T(2),rmse_T(3),rmse_T(4),wis_T(1),wis_T(2),wis_T(3),wis_T(4),coverage50_T(1),coverage50_T(2),coverage50_T(3),coverage50_T(4),coverage90_T(1),coverage90_T(2),coverage90_T(3),coverage90_T(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
    Evaluations_T = [Evaluations_T;temp_T];

    if(~isnan(flu_data_m2))
        tempt = table("SIkJalpha",wk,rmse2(1),rmse2(2),rmse2(3),rmse2(4),wis2(1),wis2(2),wis2(3),wis2(4),coverage502(1),coverage502(2),coverage502(3),coverage502(4),coverage902(1),coverage902(2),coverage902(3),coverage902(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations = [Evaluations;tempt];
    
        temp_T = table("SIkJalpha",wk,rmse_T2(1),rmse_T2(2),rmse_T2(3),rmse_T2(4),wis_2(1),wis_2(2),wis_2(3),wis_2(4),coverage50_2(1),coverage50_2(2),coverage50_2(3),coverage50_2(4),coverage90_2(1),coverage90_2(2),coverage90_2(3),coverage90_2(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations_T = [Evaluations_T;temp_T];
    end

    if(~isnan(flu_data_m3))
        tempt = table("LSBoost",wk,rmse3(1),rmse3(2),rmse3(3),rmse3(4),wis3(1),wis3(2),wis3(3),wis3(4),coverage503(1),coverage503(2),coverage503(3),coverage503(4),coverage903(1),coverage903(2),coverage903(3),coverage903(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations = [Evaluations;tempt];
    
        temp_T = table("LSBoost",wk,rmse_T3(1),rmse_T3(2),rmse_T3(3),rmse_T3(4),wis_3(1),wis_3(2),wis_3(3),wis_3(4),coverage50_3(1),coverage50_3(2),coverage50_3(3),coverage50_3(4),coverage90_3(1),coverage90_3(2),coverage90_3(3),coverage90_3(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations_T = [Evaluations_T;temp_T];
    end
end

% load(path1 + int2str(year)+"-"+int2str(year-2000+1)+"_2US.mat");
% data_T = [results; Evaluations_T];
load(path1+ int2str(year)+"-"+int2str(year-2000+1)+"_2states.mat");
results_mean = renamevars(results_mean,["RMSE1","RMSE2","RMSE3","RMSE4"], ...
                 ["MAE1","MAE2","MAE3","MAE4"]);
data = [results_mean; Evaluations];
%2018-2019 LOS Alamos (["LANL_Danteplus"]), before ["DELPHI-Epicast"],["Delphi-Epicast-Mturk"],["Delphi-Stat"] 
%% By state Evaluation
metric = "MAE";
teams = unique(data.Team);
figure('DefaultAxesFontSize',16); tiledlayout(2, 2)
AvgEval = table;
for wk = 1:4
    nexttile;
    l = string.empty;
    for t = teams'%["randomForest" "LSBoost" "SIkJalpha" "LANL-Dante" "LANL_Danteplus" "LANL-DBM" "LANL-DBMplus" "DELPHI-Epicast" "Delphi-Epicast" "Delphi-Epicast-Mturk" "Delphi-Stat"]
        indx = (data.Team==t) & (data.Week < 14 | data.Week>43);
        to = data(indx,:);
        
        if isempty(to) || sum(isnan(to.MAE1))>11
            continue;
        end

        if t=="LSBoost" && metric == "WIS"
            continue
        end
   
%         to = to(1:22,:);
        to = sortrows(to,2);
        if wk==1
            avg= nanmean(to{:,3:6},'all');
            avgW= nanmean(to{:,7:10},'all');
            avgC50 = nanmean(to{1:end-3,11:14},'all');
            avgC90= nanmean(to{1:end-3,15:end},'all');
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'MAE','WIS','C50', 'C90'});
            AvgEval = [AvgEval;tempavg];
        end

        
        if(t=="randomForest")
            l(end+1) = "RF-SIkJalpha";
            p = plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-o','LineWidth',1.5); hold on;
            p.Color(4) = 1;
        elseif(t == "LSBoost" )
            l(end+1) = "LS-SIkJalpha";
            p = plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-*','LineWidth',1.5); hold on;
            p.Color(4) = 1;
        elseif(t == "SIkJalpha")
            l(end+1) = t;
            p = plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'-x','LineWidth',1.5); hold on;
            p.Color(4) = 1;
        else
            if(any(strcmp(["LANL-Dante" "LANL_Danteplus" "LANL-DBM" "LANL-DBMplus" "DELPHI-Epicast" "Delphi-Epicast" "Delphi-Epicast-Mturk" "Delphi-Stat"],t)))
                l(end+1) = t;
                p =plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'LineWidth',1.2); hold on; %nan for 2017
                p.Color(4) = 0.95;
            else
                l(end+1) = "";
                p =plot([eval("to."+ metric + wk +"(14:end)");eval("to."+ metric + wk +"(1:13)")],'LineWidth',1.2); hold on; %nan for 2017
                p.Color(4) = 0.55;
            end
%             l(end+1) = t;
            
        end
    end
    hold off
    ylabel(metric);
    xlabel("MMR Week");
    title(wk+ " Week ahead forecast");
    set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    if(wk==1)
        legend(l,'FontSize',12);
    end
% ax.XTickLabel = [44:52 1:13]';
%     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
end
sgtitle(year + " State Mean");

%% Give Weekly Rankings
% clear s;
% for i = 1:size(Evaluations,2)
%     s(i) = mean(Evaluations(i).RMSE); %struct('model', Evaluations(i).model, 'RMSE')
% end
% [x,idx]=sort(s);
% %s=Evaluations(idx);
% Evaluations2 = struct2table(Evaluations);
% 
% Evaluations2.RMSE_mean = s';
% idx = startsWith(Evaluations2.model, date_of_submission);
% s2  =sortrows(Evaluations2(idx, :), 'RMSE_mean');

%% Predictors Performance
old_data = table;
% for i=year:-1:2010%2010
%     load("flu_hospitalization_TOP-New_predictors2" + int2str(i)+".mat")
%     old_data = [predILI; old_data];
% end
load("../flu_hospitalization_TOP-New_predictors2" + int2str(year)+".mat")
days = 239;
% figure(2)
% plot(H{1:days,2});

mae_pred = nan(days,4,(size(predILI,2) - 6)/4);
preds = nan(56,days,4,size(mae_pred,3));
gt = nan(56,days,4);
y = year - 2009;

for cid=1:56
    preds(cid,:,1,:) = predILI{1 + days*(cid-1):days*cid,7:6+size(mae_pred,3)};
    preds(cid,:,2,:) = predILI{1 + days*(cid-1):days*cid,7+size(mae_pred,3):6+size(mae_pred,3)*2};
    preds(cid,:,3,:) = predILI{1 + days*(cid-1):days*cid,7+size(mae_pred,3)*2:6+size(mae_pred,3)*3};
    preds(cid,:,4,:) = predILI{1 + days*(cid-1):days*cid,7+size(mae_pred,3)*3:6+size(mae_pred,3)*4};

    gt(cid,:,1) = predILI{1 + days*(cid-1):days*cid,3};
    gt(cid,:,2) = predILI{1 + days*(cid-1):days*cid,4};
    gt(cid,:,3) = predILI{1 + days*(cid-1):days*cid,5};
    gt(cid,:,4) = predILI{1 + days*(cid-1):days*cid,6};
end

%Change to weekly
preds = preds(:,1:7:floor(end/7)*7,:,:)+preds(:,2:7:floor(end/7)*7,:,:)+preds(:,3:7:floor(end/7)*7,:,:)+preds(:,4:7:floor(end/7)*7,:,:)+preds(:,5:7:floor(end/7)*7,:,:)+preds(:,6:7:floor(end/7)*7,:,:)+preds(:,7:7:floor(end/7)*7,:,:);
gt = gt(:,1:7:floor(end/7)*7,:)+gt(:,2:7:floor(end/7)*7,:)+gt(:,3:7:floor(end/7)*7,:)+gt(:,4:7:floor(end/7)*7,:)+gt(:,5:7:floor(end/7)*7,:)+gt(:,6:7:floor(end/7)*7,:)+gt(:,7:7:floor(end/7)*7,:);

%Find errors
for w=1:size(gt,2)
    for wk=1:4
        pgt = gt(:,w,wk);
        for pred=1:size(mae_pred,3)
            p = preds(:,w,wk,pred);
            mae_pred(w,wk,pred) = RMSE(pgt,p);            
        end
    end
end

teams = unique(Evaluations.Team);
metric = "MAE";
figure('DefaultAxesFontSize',16); tiledlayout(2, 2)


l = string.empty;    
indx = (data.Team=="randomForest"); % RandomForest-SIkJalpha"
to = data(indx,:);
% weeks = datetime(unique(to.Week));

for wk = 1:4
    nexttile;     
    l(end+1) = 'RF-SIkJalpha';%string(temp(:,8:end));
    p = plot(eval("to."+ metric + wk),'-o', 'Color','red','LineWidth',1.5); hold on;
    all_marks = {'o','+','*','.','x','s','d','^','v','>','<','p','h'};
    for pred=1:size(mae_pred,3)
%         l(end+1) = pred;
        p = plot(mae_pred(5:26,wk,pred),'LineWidth',1);%,'Marker',all_marks{mod(pred,13)+1}); hold on;
        p.Color(4) = 0.95;
    end
    mean_errors = squeeze(nanmean(mae_pred(5:26,:,:),[1 2]));
    hold off
    ylabel(metric);
    xlabel("MMR Week");
    title(wk+ " Week ahead forecast", 'FontSize',16);
    set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    if(wk==1)
        legend(l,'FontSize',15);
    end
end
