%% Read data in correct format. 
%% Read GT. So far, up till 02/19 GT,
clear;
path1 = '.\truth-Incident Hospitalizations.csv';
% First submission was on 02/07, need another week of data(Weekly: Quantiles
%%
path = "..\22_data-forecasts_covid\";
Files=dir(path);
% Evaluations= struct('RMSE', [], 'C50', [], 'C90',[], 'WIS',[], 'RMSE_T', [], 'C50_T', [], 'C90_T',[], 'WIS_T',[]);
Evaluations = table;
Evaluations_T = table;

for f = 3:size(Files,1)
%     try
        file_name = Files(f).name;
        date_GT = file_name(1:10);
        flu_data_GT = read_covidDataGT(path1,date_GT);
        path2 = path+file_name;
        try
            [flu_data_m, flu_data_q] = read_covidData(path2);
        catch
            continue
        end
        % Find RMSE (Mean based, if mean not available then use median)
        rmse_T = nan(1,size(flu_data_GT,2));
        for j = 1:size(flu_data_GT,2)
            rmse_T(j) = RMSE(flu_data_GT(14,j),flu_data_m(14,j));
        end
        temp = [flu_data_m(1:13,:); flu_data_m(15:end,:)];
        tempGT = [flu_data_GT(1:13,:); flu_data_GT(15:end,:)];
        rmse = nan(1,size(flu_data_GT,2));
        for j = 1:size(flu_data_GT,2)
            rmse(j) = RMSE(tempGT(:,j),temp(:,j));
        end
        % Find Coverage
        temp = [flu_data_q(1:13,:,:); flu_data_q(15:end,:,:)];
        %Not mean so use coverage 1. Also do it per week ahead. So state-wsie
        %coverage rather than time
        for w=1:size(tempGT,2)
            if(sum(isnan(tempGT(:,w)))==53)
                coverage50(w) = nan;
                coverage90(w) = nan;
        
                coverage50_T(w) = nan;
                coverage90_T(w) = nan;
                continue;
            end
            coverage50(w) = Coverage2(temp(:,:,w),tempGT(:,w),0.5,1)';
            coverage90(w) = Coverage2(temp(:,:,w),tempGT(:,w),0.9,1)';
    
            coverage50_T(w) = Coverage2(flu_data_q(14,:,w),flu_data_GT(14,w),0.5,1)';
            coverage90_T(w) = Coverage2(flu_data_q(14,:,w),flu_data_GT(14,w),0.9,1)';
        end
    
        
        % Find WIS
    
        wis = nan(1,size(flu_data_GT,2));
        wis_T = nan(1,size(flu_data_GT,2));
        % for i = 1:size(flu_data_GT,1)
        for j = 1:size(flu_data_GT,2)
    %         GT = nanmean(tempGT,1);
    %         qs = nanmean(temp,1);
    %         wis(1,j) = WIS(GT(1,j), qs(1,:,j), 11);
            if(sum(isnan(tempGT(:,j)))==53)
                wis(1,j) = nan;
                wis_T(1,j) = nan;
                continue;
            end
            wis(1,j) = WIS(tempGT(:,j), squeeze(temp(:,:,j)), 11);
            wis_T(1,j) = WIS(flu_data_GT(14,j), flu_data_q(14,:,j), 11);
        end
    %     end
        % append to table
        rmse = reshape(rmse, 4, 7);
        rmse = mean(rmse,2);
    
        wis = reshape(wis, 4, 7);
        wis = mean(wis,2);
    
        coverage50 = reshape(coverage50, 4, 7);
        coverage50 = mean(coverage50,2);
        coverage90 = reshape(coverage90, 4, 7);
        coverage90 = mean(coverage90,2);
    
        tempt = table(convertCharsToStrings(file_name(12:end-4)),convertCharsToStrings(file_name(1:10)),rmse(1),rmse(2),rmse(3),rmse(4),wis(1),wis(2),wis(3),wis(4),coverage50(1),coverage50(2),coverage50(3),coverage50(4),coverage90(1),coverage90(2),coverage90(3),coverage90(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations = [Evaluations;tempt];
        
        rmse_T = reshape(rmse_T, 4, 7);
        rmse_T = mean(rmse_T,2);
    
        wis_T = reshape(wis_T, 4, 7);
        wis_T = mean(wis_T,2);
    
        coverage50_T = reshape(coverage50_T, 4, 7);
        coverage50_T = mean(coverage50_T,2);
        coverage90_T = reshape(coverage90_T, 4, 7);
        coverage90_T = mean(coverage90_T,2);
    
        temp_T = table(convertCharsToStrings(file_name(12:end-4)),convertCharsToStrings(file_name(1:10)),rmse_T(1),rmse_T(2),rmse_T(3),rmse_T(4),wis_T(1),wis_T(2),wis_T(3),wis_T(4),coverage50_T(1),coverage50_T(2),coverage50_T(3),coverage50_T(4),coverage90_T(1),coverage90_T(2),coverage90_T(3),coverage90_T(4),'VariableNames',{'Team', 'Week', 'MAE1','MAE2','MAE3', 'MAE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50_1','C50_2','C50_3','C50_4','C90_1','C90_2','C90_3','C90_4'});
        Evaluations_T = [Evaluations_T;temp_T];
%     catch
%         continue
%     end
%     Evaluations(f-2) = struct('model', file_name,'RMSE', rmse, 'C50', [coverage50], 'C90',[coverage90], 'WIS',wis, 'RMSE_T', rmse_T, 'C50_T', [coverage50_T], 'C90_T',[coverage90_T], 'WIS_T',wis_T);
end

%% TOTAL US EVAL
% % percentile = 100;
% teams = unique(Evaluations_T.Team);
% metric = "MAE";
% figure('DefaultAxesFontSize',18); tiledlayout(2, 2)
% AvgEvalT = table;
% for wk = 1:4
%     nexttile;
%     l = string.empty;
%     for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
%         indx = (Evaluations_T.Team==t);
%         to = Evaluations_T(indx,:);
%         weeks = datetime(unique(to.Week));
% 
%         if isempty(to)
%             continue;
%         end
%         if wk==1
%             avg= nanmedian(to{:,3:6},'all');
%             avgW= nanmedian(to{:,7:10},'all');
%             avgC50 = nanmean(to{1:end-3,11});
%             avgC90= nanmean(to{1:end-3,12});
%             tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'RMSE','WIS','C50', 'C90'});
%             AvgEvalT = [AvgEvalT;tempavg];
%         end
% %         to = to(1:22,:); % omment for 2019
% %         to = sortrows(to,2);
%         if(t=="SGroup-RandomForest")
%             temp = char(t);
%             l(end+1) = string(temp(:,8:end));
%             p= plot(weeks,eval("to."+ metric + wk),'-o', 'Color','red','LineWidth',1.2); hold on;
%         elseif(t=="RandomForest-SIkJalpha")
%             temp = char(t);
%             l(end+1) = 'RF-SIkJalpha'; string(temp(:,8:end));
%             p= plot(weeks,eval("to."+ metric + wk),'-+','Color','black','LineWidth',1.2); hold on;
%         elseif(t=="SGroup-SIkJalpha")
%             temp = char(t);
%             l(end+1) = string(temp(:,8:end));
%             p= plot(weeks,eval("to."+ metric + wk),'-x','Color','green','LineWidth',1.2); hold on;
%             1;
%         elseif(t=="LSboost-SIkJalpha")
%             if(metric=="WIS")
%                 continue
%             end
%             temp = char(t);
%             l(end+1) = 'LS-SIkJalpha';string(temp(:,8:end));
%             p= plot(weeks,eval("to."+ metric + wk),'-*','Color','blue','LineWidth',1.2); hold on;
%         else
%             l(end+1) = "";
%             p= plot(weeks,eval("to."+ metric + wk)); hold on;
%             p.Color(4) = 0.55;
%         end
%         
% %         plot([eval("to.RMSE" + wk +"(14:end)");eval("to.RMSE" + wk +"(1:13)")]); hold on;
%     end
%     hold off
%     ylabel(metric);
%     xlabel("Forecast Date");
%     title(wk+ " Week ahead forecast");
% %     set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
%     if wk==1
%         legend(l);
%     end
% % ax.XTickLabel = [44:52 1:13]';
% %     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
% end
% sgtitle("2022 Total US " + metric);
% % ax = axes('XLimMode', 'manual', 'XTickMode', 'manual'); 
%% By state Evaluation
teams = unique(Evaluations.Team);
metric = "MAE";
figure('DefaultAxesFontSize',16); tiledlayout(2, 2)
AvgEval = table;

for wk = 1:4
    nexttile;
    l = string.empty;
    for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
        indx = (Evaluations.Team==t);
        to = Evaluations(indx,:);
        weeks = datetime(unique(to.Week));

        if isempty(to)
            continue;
        end
 
        if wk==1
            avg= nanmean(to{:,3:6},'all');
            avgW= nanmean(to{:,7:10},'all');
            avgC50 = nanmean(to{1:end-3,11:14},'all');
            avgC90= nanmean(to{1:end-3,15:end},'all');
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'MAE','WIS','C50', 'C90'});
            AvgEval = [AvgEval;tempavg];
        end

        if(t=="SGroup-RandomForest-Covid")%-FLUSURV")
            temp = char(t);
            l(end+1) = "SGroup-RandomForest-Covid";%'RF-SIkJalpha';%string(temp(:,8:end));
            p = plot(weeks,eval("to."+ metric + wk),'-o', 'Color','red','LineWidth',1.5); hold on;
        elseif(t=="USC-SI_kJalpha")
            temp = char(t);
            l(end+1) = string(temp(:,1:end));
            p= plot(weeks,eval("to."+ metric + wk),'-+','Color','black','LineWidth',1.2); hold on;
        elseif(t=="SGroup-RandomForest-DTW1")%SIkJalpha")
            temp = char(t);
            l(end+1) = string(temp(:,1:end));
            p = plot(weeks,eval("to."+ metric + wk),'-x','Color','green','LineWidth',1.5); hold on;
        elseif(t=="SGroup-RandomForest-DTWSingle")%LSBoosted")
            if(metric=="WIS")
                continue
            end
            temp = char(t);
            l(end+1) = string(temp(:,8:end)); %'LS-SIkJalpha';string(temp(:,8:end));
            p = plot(weeks,eval("to."+ metric + wk),'-*','Color','blue','LineWidth',1.5); hold on;
        else
            l(end+1) = "";
            p = plot(weeks,eval("to."+ metric + wk),'LineWidth',1.2); hold on;
            p.Color(4) = 0.55;
        end
        
%         plot([eval("to.RMSE" + wk +"(14:end)");eval("to.RMSE" + wk +"(1:13)")]); hold on;
    end
    hold off
    ylabel(metric);
    xlabel("Forecast Date");
    title(wk+ " Week ahead forecast", 'FontSize',16);
    if(wk==1)
        legend(l,'FontSize',14);
    end
end
sgtitle("2022 State Mean " + metric);
%% Coverage Plots
teams = unique(Evaluations_T.Team); %Evaluations
metric = "C90";
% figure; tiledlayout(2, 2)
AvgEval = table;
clear p;
l = string.empty;
for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
    indx = (Evaluations_T.Team==t);
    to = Evaluations_T(indx,:);
    weeks = datetime(unique(to.Week));
    weeks = weeks(1:end-4);
    if isempty(to)
        continue;
    end        
    if(t=="SGroup-RandomForest")
        l(end+1) = t;
        e = eval("to."+ metric);
        p =  plot(weeks,e(1:end-4),'-o', 'Color','red','LineWidth',1.5); hold on;
    elseif(t=="SGroup-SIkJalpha")
        l(end+1) = t;
        e = eval("to."+ metric);
        p =  plot(weeks,e(1:end-4),'-*','Color','green','LineWidth',1.5); hold on;
    else
        l(end+1) = "";
        e = eval("to."+ metric);
        p = plot(weeks,e(1:end-4),'LineWidth',1.2); hold on;
        try
            p.Color(4) = 0.35;
        catch
        end
    end
end
    hold off
    ylabel(metric);
    xlabel("Forecast Date");
    title("2022 Total US " + metric);
    legend(l);
    
% sgtitle("2022 State Mean " + metric);
%% Ranking
metric = "MAE";
weeks = unique(Evaluations.Week);
ranking = table;
l = string.empty;
for wk = 1:4
    for w=weeks'
        if datetime("2022-06-06") - datetime(w) < 7*wk
            continue
        end
        indx = (Evaluations.Week==w & Evaluations.Team ~= "SGroup-RandomForest-FLUSURVJP" & Evaluations.Team ~= "SGroup-RandomForest-FLUSURVP" & Evaluations.Team ~= "SGroup-RandomForest-FLUSURV_PredAbl" & Evaluations.Team ~= "SGroup-LSBoosted" & Evaluations.Team ~= "SGroup-RandomForest-FLUSURV2" & Evaluations.Team ~= "SGroup-RandomForest-FLUSURV3" & Evaluations.Team ~= "SGroup-RandomForest-FLUSURV4" & Evaluations.Team ~= "SGroup-RandomForest2" & Evaluations.Team ~= "SGroup-RandomForest3" & Evaluations.Team ~= "SGroup-RandomForest4" & Evaluations.Team ~= "RandomForestJP" & Evaluations.Team ~= "RandomForestP" & Evaluations.Team ~="LSboost-SIkJalpha" & Evaluations.Team ~= "RandomForest-SIkJalpha");
        to = Evaluations(indx,:);
        if isempty(to)
            continue;
        end    
        to = sortrows(to,metric+wk); %(default) Sorts in ascending order
        teams = unique(to.Team);
        for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
%             indx = (Evaluations.Team==t);
%             if t == "SGroup-RandomForest-FLUSURVJP" || t== "SGroup-RandomForest-FLUSURVP" || t== "SGroup-RandomForest-FLUSURV_PredAbl" || t== "SGroup-LSBoosted" || t== "SGroup-RandomForest-FLUSURV2" || t== "SGroup-RandomForest-FLUSURV3" || t== "SGroup-RandomForest-FLUSURV4" || t== "SGroup-RandomForest2" || t== "SGroup-RandomForest3" || t== "SGroup-RandomForest4" || t== "RandomForestJP" || t== "RandomForestP" || t=="LSboost-SIkJalpha" || t== "RandomForest-SIkJalpha"
%                 continue
%             end
            temp = table(wk,t,w,find(ismember(to.Team,t,'rows')),'VariableNames',{'Wk_Ahead_Forecast', 'Team', 'Week', convertStringsToChars(metric)});
            ranking = [ranking;temp];
        end
    end

    color_options = ["red","green", "blue", "black"];
    temp = ranking(ranking.Team == "SGroup-RandomForest-FLUSURV" & ranking.Wk_Ahead_Forecast == wk,:);
    l(end+1) = "RF-SIkJalpha_"+wk;%string(temp(:,8:end));
    p = plot(datetime(temp.Week),temp.MAE,'-', 'Color',color_options(wk),'LineWidth',1.5); hold on;
    temp = ranking(ranking.Team == "SGroup-RandomForest" & ranking.Wk_Ahead_Forecast == wk,:);
    l(end+1) = "SGroup-RandomForest_"+wk;%string(temp(:,8:end));
    p = plot(datetime(temp.Week),temp.MAE,'--', 'Color',color_options(wk),'LineWidth',1.5); hold on;
end

hold off
ylabel("Ranking");
xlabel("Forecast Date");
title("Rankings per Week", 'FontSize',16);
legend(l,'FontSize',14);

% sgtitle("2022 State Mean " + metric);

top_indx = eval("ranking."+metric) <= 3;
top=ranking(top_indx,:);
%% Ranking total
metric = "WIS";
weeks = unique(Evaluations_T.Week);
ranking = table;
for wk = 1:4
    for w=weeks'
        indx = (Evaluations_T.Week==w);
        to = Evaluations_T(indx,:);
        if isempty(to)
            continue;
        end    
        to = sortrows(to,metric+wk); %(default) Sorts in ascending order
        teams = unique(to.Team);
        for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
%             indx = (Evaluations.Team==t);
            temp = table(wk,t,w,find(ismember(to.Team,t,'rows')),'VariableNames',{'Wk_Ahead_Forecast', 'Team', 'Week', convertStringsToChars(metric)});
            ranking = [ranking;temp];
        end
    end
end

top_indx = eval("ranking."+metric) <= 4;
top=ranking(top_indx,:);
%% Predictors
load("../flu_hospitalization_T-New_predictors.mat")
days = size(H,1)/56; 
% figure(2)
% plot(H{1:days,2});

%124 starts at 1/8/22
preds = nan(56,days-123,4,30);
gt = nan(56,days-123,4);
for cid=1:56
    preds(cid,:,1,:) = H{124 + days*(cid-1):days*cid,7:36};
    preds(cid,:,2,:) = H{124 + days*(cid-1):days*cid,37:66};
    preds(cid,:,3,:) = H{124 + days*(cid-1):days*cid,67:96};
    preds(cid,:,4,:) = H{124 + days*(cid-1):days*cid,97:126};

    gt(cid,:,1) = H{124 + days*(cid-1):days*cid,3};
    gt(cid,:,2) = H{124 + days*(cid-1):days*cid,4};
    gt(cid,:,3) = H{124 + days*(cid-1):days*cid,5};
    gt(cid,:,4) = H{124 + days*(cid-1):days*cid,6};
end

%Change to weekly
preds = preds(:,1:7:floor(end/7)*7,:,:)+preds(:,2:7:floor(end/7)*7,:,:)+preds(:,3:7:floor(end/7)*7,:,:)+preds(:,4:7:floor(end/7)*7,:,:)+preds(:,5:7:floor(end/7)*7,:,:)+preds(:,6:7:floor(end/7)*7,:,:)+preds(:,7:7:floor(end/7)*7,:,:);
gt = gt(:,1:7:floor(end/7)*7,:)+gt(:,2:7:floor(end/7)*7,:)+gt(:,3:7:floor(end/7)*7,:)+gt(:,4:7:floor(end/7)*7,:)+gt(:,5:7:floor(end/7)*7,:)+gt(:,6:7:floor(end/7)*7,:)+gt(:,7:7:floor(end/7)*7,:);

%Find errors
mae_pred = nan(size(gt,2),4,30);
for w=1:size(gt,2)
    for wk=1:4
        pgt = gt(:,w,wk);
        for pred=1:30
            p = preds(:,w,wk,pred);
            mae_pred(w,wk,pred) = RMSE(pgt,p);            
        end
    end
end

teams = unique(Evaluations.Team);
metric = "MAE";
figure('DefaultAxesFontSize',32); %tiledlayout(2, 2)


l = string.empty;    
indx = (Evaluations.Team=="SGroup-RandomForest-FLUSURV");
to = Evaluations(indx,:);
weeks = datetime(unique(to.Week));

for wk = 4:4
    all_marks = {'o','+','*','.','x','s','d','^','v','>','<','p','h'};
    count = 1;
    for pred=1:30
%         l(end+1) = pred;
        if(count<=6)%mod(pred,3)==1) %)%
            l(end+1) = 0.90;
            p = plot(weeks,mae_pred(1:size(weeks,1),wk,pred),'LineWidth',2,'Color','red');hold on;%,'Marker',all_marks{mod(pred,13)+1}); hold on;         
        elseif(count<=12)
            l(end+1) = 0.92;
            p = plot(weeks,mae_pred(1:size(weeks,1),wk,pred),'LineWidth',2,'Color','green');hold on;%,'Marker',all_marks{mod(pred,13)+1}); hold on;                 
        elseif(count<=18)
            l(end+1) = 0.94;
            p = plot(weeks,mae_pred(1:size(weeks,1),wk,pred),'LineWidth',2,'Color','blue');hold on;%,'Marker',all_marks{mod(pred,13)+1}); hold on;                 
        elseif(count<=24)
            l(end+1) = 0.96;
            p = plot(weeks,mae_pred(1:size(weeks,1),wk,pred),'LineWidth',2,'Color','yellow');hold on;%,'Marker',all_marks{mod(pred,13)+1}); hold on;                         
        else
            l(end+1) = 0.98;
            p = plot(weeks,mae_pred(1:size(weeks,1),wk,pred),'LineWidth',2,'Color','magenta');hold on;%,'Marker',all_marks{mod(pred,13)+1}); hold on;         
        end
        count = count + 1;

    end
    l = '\alpha = '+ l([1 7 13 19 25]);
    hold off
    ylabel(metric);
    xlabel("Forecast Date");
    title(wk+ " Week ahead forecast", 'FontSize',32);
    if(wk==4)
        legend(l,'FontSize',32);
    end
end
