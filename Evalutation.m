%% Read data in correct format. 
%% Read GT. So far, up till 02/19 GT,
clear;
path1 = 'D:\USC\Research\Flu\repo\Flusight-forecast-data\data-truth\truth-Incident Hospitalizations.csv';
% First submission was on 02/07, need another week of data(Weekly: Quantiles
%%
path = "D:\USC\Research\Flu\Data\data-forecasts\";
Files=dir(path);
% Evaluations= struct('RMSE', [], 'C50', [], 'C90',[], 'WIS',[], 'RMSE_T', [], 'C50_T', [], 'C90_T',[], 'WIS_T',[]);
Evaluations = table;
Evaluations_T = table;
for f = 3:size(Files,1)
    file_name = Files(f).name;
    date_GT = file_name(1:10);
    flu_data_GT = read_fluDataGT(path1,date_GT);
    path2 = path+file_name;
    [flu_data_m, flu_data_q] = read_fluData(path2);
    %% Find RMSE (Mean based, if mean not available then use median)
    rmse_T = nan(1,size(flu_data_GT,2));
    for j = 1:size(flu_data_GT,2)
        rmse_T(j) = RMSE(flu_data_GT(14,j),flu_data_m(14,j));
    end
    temp = [flu_data_m(1:13,:); flu_data_m(15:end,:)];
    tempGT = [flu_data_GT(1:13,:); flu_data_GT(15:end,:)];
    rmse = nan(1,size(flu_data_GT,2));
    for j = 1:size(flu_data_GT,2)
        rmse(j) = RMSE(nanmean(tempGT(:,j),1),nanmean(temp(:,j),1));
    end
    %% Find Coverage
    temp = [flu_data_q(1:13,:,:); flu_data_q(15:end,:,:)];
    coverage50 = Coverage2(nanmean(temp,1),nanmean(tempGT,1),0.5,1)';
    coverage90 = Coverage2(nanmean(temp,1),nanmean(tempGT,1),0.9,1)';

    coverage50_T = Coverage2(flu_data_q(14,:,:),flu_data_GT(14,:,:),0.5,1)';
    coverage90_T = Coverage2(flu_data_q(14,:,:),flu_data_GT(14,:,:),0.9,1)';
    %% Find WIS

    wis = nan(1,size(flu_data_GT,2));
    wis_T = nan(1,size(flu_data_GT,2));
    % for i = 1:size(flu_data_GT,1)
    for j = 1:size(flu_data_GT,2)
        GT = nanmean(tempGT,1);
        qs = nanmean(temp,1);
        wis(1,j) = WIS(GT(1,j), qs(1,:,j), 11);
        wis_T(1,j) = WIS(flu_data_GT(14,j), flu_data_q(14,:,j), 11);
    end
%     end
    %% append to table
    tempt = table(convertCharsToStrings(file_name(12:end-4)),convertCharsToStrings(file_name(1:10)),rmse(1),rmse(2),rmse(3),rmse(4),wis(1),wis(2),wis(3),wis(4),coverage50,coverage90,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
    Evaluations = [Evaluations;tempt];
    
    temp_T = table(convertCharsToStrings(file_name(12:end-4)),convertCharsToStrings(file_name(1:10)),rmse_T(1),rmse_T(2),rmse_T(3),rmse_T(4),wis_T(1),wis_T(2),wis_T(3),wis_T(4),coverage50_T,coverage90_T,'VariableNames',{'Team', 'Week', 'RMSE1','RMSE2','RMSE3', 'RMSE4', 'WIS1','WIS2','WIS3', 'WIS4', 'C50','C90'});
    Evaluations_T = [Evaluations_T;temp_T];
%     Evaluations(f-2) = struct('model', file_name,'RMSE', rmse, 'C50', [coverage50], 'C90',[coverage90], 'WIS',wis, 'RMSE_T', rmse_T, 'C50_T', [coverage50_T], 'C90_T',[coverage90_T], 'WIS_T',wis_T);
end

%%
% percentile = 100;
teams = unique(Evaluations_T.Team);
metric = "RMSE";
figure('DefaultAxesFontSize',18); tiledlayout(2, 2)
AvgEvalT = table;
for wk = 1:4
    nexttile;
    l = string.empty;
    for t = teams' %["SGroup-RandomForest" "SGroup-SIkJalpha"]
        indx = (Evaluations_T.Team==t);
        to = Evaluations_T(indx,:);
        weeks = datetime(unique(to.Week));

        if isempty(to)
            continue;
        end
        if wk==1
            avg= nanmedian(to{:,3:6},'all');
            avgW= nanmedian(to{:,7:10},'all');
            avgC50 = nanmean(to{1:end-3,11});
            avgC90= nanmean(to{1:end-3,12});
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'RMSE','WIS','C50', 'C90'});
            AvgEvalT = [AvgEvalT;tempavg];
        end
%         to = to(1:22,:); % omment for 2019
%         to = sortrows(to,2);
        if(t=="SGroup-RandomForest")
            temp = char(t);
            l(end+1) = string(temp(:,8:end));
            p= plot(weeks,eval("to."+ metric + wk),'-o', 'Color','red','LineWidth',1.2); hold on;
        elseif(t=="RandomForest-SIkJalpha")
            temp = char(t);
            l(end+1) = 'RF-SIkJalpha'; string(temp(:,8:end));
            p= plot(weeks,eval("to."+ metric + wk),'-+','Color','black','LineWidth',1.2); hold on;
        elseif(t=="SGroup-SIkJalpha")
            temp = char(t);
            l(end+1) = string(temp(:,8:end));
            p= plot(weeks,eval("to."+ metric + wk),'-x','Color','green','LineWidth',1.2); hold on;
            1;
        elseif(t=="LSboost-SIkJalpha")
            if(metric=="WIS")
                continue
            end
            temp = char(t);
            l(end+1) = 'LS-SIkJalpha';string(temp(:,8:end));
            p= plot(weeks,eval("to."+ metric + wk),'-*','Color','blue','LineWidth',1.2); hold on;
        else
            l(end+1) = "";
            p= plot(weeks,eval("to."+ metric + wk)); hold on;
            p.Color(4) = 0.55;
        end
        
%         plot([eval("to.RMSE" + wk +"(14:end)");eval("to.RMSE" + wk +"(1:13)")]); hold on;
    end
    hold off
    ylabel(metric);
    xlabel("Forecast Date");
    title(wk+ " Week ahead forecast");
%     set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    if wk==1
        legend(l);
    end
% ax.XTickLabel = [44:52 1:13]';
%     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
end
sgtitle("2022 Total US " + metric);
% ax = axes('XLimMode', 'manual', 'XTickMode', 'manual'); 
%% By state
teams = unique(Evaluations.Team);
metric = "RMSE";
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
            avg= nanmedian(to{:,3:6},'all');
            avgW= nanmedian(to{:,7:10},'all');
            avgC50 = nanmean(to{1:end-3,11});
            avgC90= nanmean(to{1:end-3,12});
            tempavg = table(t,avg,avgW,avgC50,avgC90, 'VariableNames',{'Team', 'RMSE','WIS','C50', 'C90'});
            AvgEval = [AvgEval;tempavg];
        end

        if(t=="SGroup-RandomForest")
            temp = char(t);
            l(end+1) = string(temp(:,8:end));
            p = plot(weeks,eval("to."+ metric + wk),'-o', 'Color','red','LineWidth',1.5); hold on;
        elseif(t=="RandomForest-SIkJalpha")
            temp = char(t);
            l(end+1) = 'RF-SIkJalpha';string(temp(:,8:end));
            p= plot(weeks,eval("to."+ metric + wk),'-+','Color','black','LineWidth',1.2); hold on;
        elseif(t=="SGroup-SIkJalpha")
            temp = char(t);
            l(end+1) = string(temp(:,8:end));
            p = plot(weeks,eval("to."+ metric + wk),'-x','Color','green','LineWidth',1.5); hold on;
        elseif(t=="LSboost-SIkJalpha")
            if(metric=="WIS")
                continue
            end
            temp = char(t);
            l(end+1) = 'LS-SIkJalpha';string(temp(:,8:end));
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
%     set(gca,'XTick',[1:22], 'XTickLabel', [44:52 1:13])
    legend(l);
% ax.XTickLabel = [44:52 1:13]';
%     legend("randomForest","LANL_Danteplus","DELPHI-Epicast","Delphi-Epicast-Mturk","Delphi-Stat");
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
metric = "RMSE";
weeks = unique(Evaluations.Week);
ranking = table;
for wk = 1:4
    for w=weeks'
        indx = (Evaluations.Week==w);
        to = Evaluations(indx,:);
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