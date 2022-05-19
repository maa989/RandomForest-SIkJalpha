clear
% load flu_hospitalization_T-old_predictors.mat%flu_hospitalization_T.mat
load flu_hospitalization_TOP-New_predictorsFluSurv
% old_data = readtable("ILINet.csv");
% load flu_hospitalization_T-New_predictors.mat%flu_hospitalization_T-New.mat
popu = load('us_states_population_data.txt');
seasons_back = 1; %1 starts at 2019-2020
abvs = readcell('us_states_abbr_list2.txt');
ns = length(abvs);
%% Use diff GT data (ILINET)
year = 2020 - seasons_back;
old_data = table;
for i=year:-1:2016
    load("flu_hospitalization_TOP-New_predictors" + int2str(i)+".mat")
    old_data = [predILI; old_data];
end

%% update table
season = 12 - seasons_back;
% old_data_no2020(1 +(season-1)*13384:(56*239)+(season-1)*13384,3:7) = table_ILI;
% old_data_no2020(1 +(season-1)*13384:(56*239)+(season-1)*13384,8:end) = predILI;
old_data_no2020 = [PedILI_Old; old_data];

%%
% mypool = parpool(32);
% paroptions = statset('UseParallel',true);
% % days = 193;%172;
% %max 34/32-4 weeks back?
% % temp = H.Var3(1:end-7);
% tempo = old_data_no2020.Var2(1:end-7);
% % temp2 = nan(size(temp));
% tempo2 = nan(size(tempo));
% % for i = 1:56
% %     temp2((i-1)*days+8:i*days) = temp((i-1)*days+1:i*days - 7);
% % end
% for j = 1:11
%     for i =1:56
%         tempo2((i-1)*239+8 +(j-1)*239*56:i*239+(j-1)*239*56) = tempo((i-1)*239+1+(j-1)*239*56:i*239 - 7 +(j-1)*239*56);
%     end
% end
% % H.Var32 = temp2;
% old_data_no2020.Var32 = tempo2;

%% Add population data
st = table;
for i = 1:56
    st = [st; array2table(repmat(i,239,1))];
end
st = repmat(st,11-seasons_back+1,1);
% H(:,end+1) = H(:,2);
old_data_no2020(:,end+1) = st;
% for i = 1:length(popu)
%     H.Var33(H.Var33 == i) = popu(i);
% end
for i = 1:length(popu)
    old_data_no2020.Var127(old_data_no2020.Var127 == i) = popu(i);
    old_data_no2020.Var127(isnan(old_data_no2020.Var2)) = nan;
end
%% Normalize data (EXCEPT FOR POPU DATA)
% H2 = H;
old_data_no20202 = old_data_no2020;
for i =1:126
%     H2(:,i) = array2table(eval(['H2.Var' num2str(i)]) * 100000./H2.Var33);
    old_data_no20202(:,i) = array2table(eval(['old_data_no20202.Var' num2str(i)]) * 100000./old_data_no20202.Var127);
end
%% Data split for older data
x = 26;%26; %Find where MMR week 44 starts & where week 20 MMR ends (40->17): 13+17=30 wks of data total
for wks_back = x:-1:5
    data_train = table;
    data_test = table;
    for i=1:(size(old_data_no20202,1)/(239*11)) %Basically looping over states
        data_train = [data_train; old_data_no20202(239*(i-1) + 1 +(season-1)*13384:(239*i)-(7*wks_back)+(season-1)*13384,:)];
        data_test = [data_test; old_data_no20202((239*i)-(7*wks_back) + 1+(season-1)*13384:(239*i)-(7*(wks_back-1))+(season-1)*13384,:)];
    end
    temp = old_data_no20202(1:(season-1)*13384,:);
%     old_data_no20202 = temp;
    %% Replicate this year's data (Training data)
    % rep = 5; %(Doubles each rep => 2^reps)
    % for i = 1:rep
    %     data_train = [data_train; data_train];
    % end
    %%

%     Mdl_1 = TreeBagger(56,[temp(:,[3 8:13 32 33]);data_train(:,[3 8:13 32 33])],[temp.Var4; data_train.Var4],'Method','regression');%,'Options',paroptions);
%     Mdl_2 = TreeBagger(56,[temp(:,[3 14:19 32 33]);data_train(:,[3 14:19 32 33])],[temp.Var5; data_train.Var5],'Method','regression');%,'Options',paroptions);
%     Mdl_3 = TreeBagger(56,[temp(:,[3 20:25 32 33]);data_train(:,[3 20:25 32 33])],[temp.Var6; data_train.Var6],'Method','regression');%,'Options',paroptions);
%     Mdl_4 = TreeBagger(56,[temp(:,[3 26:31 32 33]);data_train(:,[3 26:31 32 33])],[temp.Var7; data_train.Var7],'Method','regression');%,'Options',paroptions);
    Mdl_1 = TreeBagger(122,[temp(:,[1 2 7:36 127]);data_train(:,[1 2 7:36 127])],[temp.Var3; data_train.Var3],'Method','regression');%,'Options',paroptions);
    Mdl_2 = TreeBagger(122,[temp(:,[1 2 37:66 127]);data_train(:,[1 2 37:66 127])],[temp.Var4; data_train.Var4],'Method','regression');%,'Options',paroptions);
    Mdl_3 = TreeBagger(122,[temp(:,[1 2 67:96 127]);data_train(:,[1 2 67:96 127])],[temp.Var5; data_train.Var5],'Method','regression');%,'Options',paroptions);
    Mdl_4 = TreeBagger(122,[temp(:,[1 2 97:126 127]);data_train(:,[1 2 97:126 127])],[temp.Var6; data_train.Var6],'Method','regression');%,'Options',paroptions);

    predX_1 = data_test(:,[1 2 7:36 127]);
    mpgMean_1 = predict(Mdl_1,predX_1);
    mpgQuartiles_1 = quantilePredict(Mdl_1,predX_1,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_2 = data_test(:,[1 2 37:66 127]);
    mpgMean_2 = predict(Mdl_2,predX_2);
    mpgQuartiles_2 = quantilePredict(Mdl_2,predX_2,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_3 = data_test(:,[1 2 67:96 127]);
    mpgMean_3 = predict(Mdl_3,predX_3);
    mpgQuartiles_3 = quantilePredict(Mdl_3,predX_3,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_4 = data_test(:,[1 2 97:126 127]);
    mpgMean_4 = predict(Mdl_4,predX_4);
    mpgQuartiles_4 = quantilePredict(Mdl_4,predX_4,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);

    %% Find across all US
    total_US_GT_1 = [];
    total_US_Mean_1 = [];
    total_US_QT_1 = nan(1,23);
    total_US_GT_2 = [];
    total_US_Mean_2 = [];
    total_US_QT_2 = nan(1,23);
    total_US_GT_3 = [];
    total_US_Mean_3 = [];
    total_US_QT_3 = nan(1,23);
    total_US_GT_4 = [];
    total_US_Mean_4 = [];
    total_US_QT_4 = nan(1,23);

    for i=1:(7*wks_back)
        total_US_GT_1(i) = nansum(data_test.Var3(i:(7*wks_back):end));
        total_US_Mean_1(i) = nansum(mpgMean_1(i:(7*wks_back):end));

        total_US_GT_2(i) = nansum(data_test.Var4(i:(7*wks_back):end));
        total_US_Mean_2(i) = nansum(mpgMean_2(i:(7*wks_back):end));

        total_US_GT_3(i) = nansum(data_test.Var5(i:(7*wks_back):end));
        total_US_Mean_3(i) = nansum(mpgMean_3(i:(7*wks_back):end));

        total_US_GT_4(i) = nansum(data_test.Var6(i:(7*wks_back):end));
        total_US_Mean_4(i) = nansum(mpgMean_4(i:(7*wks_back):end));

        for j = 1:23
            total_US_QT_1(i,j) = nansum(mpgQuartiles_1(i:(7*wks_back):end,j));%[nansum(mpgQuartiles_1(i:(7*wks_back):end,1)) nansum(mpgQuartiles_1(i:(7*wks_back):end,2)) nansum(mpgQuartiles_1(i:(7*wks_back):end,3))];
            total_US_QT_2(i,j) = nansum(mpgQuartiles_2(i:(7*wks_back):end,j));%[%[nansum(mpgQuartiles_2(i:(7*wks_back):end,1)) nansum(mpgQuartiles_2(i:(7*wks_back):end,2)) nansum(mpgQuartiles_2(i:(7*wks_back):end,3))];
            total_US_QT_3(i,j) = nansum(mpgQuartiles_3(i:(7*wks_back):end,j));%[%[nansum(mpgQuartiles_3(i:(7*wks_back):end,1)) nansum(mpgQuartiles_3(i:(7*wks_back):end,2)) nansum(mpgQuartiles_3(i:(7*wks_back):end,3))];    
            total_US_QT_4(i,j) = nansum(mpgQuartiles_4(i:(7*wks_back):end,j));%[%[nansum(mpgQuartiles_4(i:(7*wks_back):end,1)) nansum(mpgQuartiles_4(i:(7*wks_back):end,2)) nansum(mpgQuartiles_4(i:(7*wks_back):end,3))];
        end
    end

    %% Weekly data
    GT_1 = total_US_GT_1(1:7:floor(end/7)*7)+total_US_GT_1(2:7:floor(end/7)*7)+total_US_GT_1(3:7:floor(end/7)*7)+total_US_GT_1(4:7:floor(end/7)*7)+total_US_GT_1(5:7:floor(end/7)*7)+total_US_GT_1(6:7:floor(end/7)*7)+total_US_GT_1(7:7:floor(end/7)*7);
    GT_2 = total_US_GT_2(1:7:floor(end/7)*7)+total_US_GT_2(2:7:floor(end/7)*7)+total_US_GT_2(3:7:floor(end/7)*7)+total_US_GT_2(4:7:floor(end/7)*7)+total_US_GT_2(5:7:floor(end/7)*7)+total_US_GT_2(6:7:floor(end/7)*7)+total_US_GT_2(7:7:floor(end/7)*7);
    GT_3 = total_US_GT_3(1:7:floor(end/7)*7)+total_US_GT_3(2:7:floor(end/7)*7)+total_US_GT_3(3:7:floor(end/7)*7)+total_US_GT_3(4:7:floor(end/7)*7)+total_US_GT_3(5:7:floor(end/7)*7)+total_US_GT_3(6:7:floor(end/7)*7)+total_US_GT_3(7:7:floor(end/7)*7);
    GT_4 = total_US_GT_4(1:7:floor(end/7)*7)+total_US_GT_4(2:7:floor(end/7)*7)+total_US_GT_4(3:7:floor(end/7)*7)+total_US_GT_4(4:7:floor(end/7)*7)+total_US_GT_4(5:7:floor(end/7)*7)+total_US_GT_4(6:7:floor(end/7)*7)+total_US_GT_4(7:7:floor(end/7)*7);

    pred_1 = total_US_QT_1(1:7:floor(end/7)*7,:)+total_US_QT_1(2:7:floor(end/7)*7,:)+total_US_QT_1(3:7:floor(end/7)*7,:)+total_US_QT_1(4:7:floor(end/7)*7,:)+total_US_QT_1(5:7:floor(end/7)*7,:)+total_US_QT_1(6:7:floor(end/7)*7,:)+total_US_QT_1(7:7:floor(end/7)*7,:);
    pred_2 = total_US_QT_2(1:7:floor(end/7)*7,:)+total_US_QT_2(2:7:floor(end/7)*7,:)+total_US_QT_2(3:7:floor(end/7)*7,:)+total_US_QT_2(4:7:floor(end/7)*7,:)+total_US_QT_2(5:7:floor(end/7)*7,:)+total_US_QT_2(6:7:floor(end/7)*7,:)+total_US_QT_2(7:7:floor(end/7)*7,:);
    pred_3 = total_US_QT_3(1:7:floor(end/7)*7,:)+total_US_QT_3(2:7:floor(end/7)*7,:)+total_US_QT_3(3:7:floor(end/7)*7,:)+total_US_QT_3(4:7:floor(end/7)*7,:)+total_US_QT_3(5:7:floor(end/7)*7,:)+total_US_QT_3(6:7:floor(end/7)*7,:)+total_US_QT_3(7:7:floor(end/7)*7,:);
    pred_4 = total_US_QT_4(1:7:floor(end/7)*7,:)+total_US_QT_4(2:7:floor(end/7)*7,:)+total_US_QT_4(3:7:floor(end/7)*7,:)+total_US_QT_4(4:7:floor(end/7)*7,:)+total_US_QT_4(5:7:floor(end/7)*7,:)+total_US_QT_4(6:7:floor(end/7)*7,:)+total_US_QT_4(7:7:floor(end/7)*7,:);

    pred_1_m = total_US_Mean_1(1:7:floor(end/7)*7)+total_US_Mean_1(2:7:floor(end/7)*7)+total_US_Mean_1(3:7:floor(end/7)*7)+total_US_Mean_1(4:7:floor(end/7)*7)+total_US_Mean_1(5:7:floor(end/7)*7)+total_US_Mean_1(6:7:floor(end/7)*7)+total_US_Mean_1(7:7:floor(end/7)*7);
    pred_2_m = total_US_Mean_2(1:7:floor(end/7)*7)+total_US_Mean_2(2:7:floor(end/7)*7)+total_US_Mean_2(3:7:floor(end/7)*7)+total_US_Mean_2(4:7:floor(end/7)*7)+total_US_Mean_2(5:7:floor(end/7)*7)+total_US_Mean_2(6:7:floor(end/7)*7)+total_US_Mean_2(7:7:floor(end/7)*7);
    pred_3_m = total_US_Mean_3(1:7:floor(end/7)*7)+total_US_Mean_3(2:7:floor(end/7)*7)+total_US_Mean_3(3:7:floor(end/7)*7)+total_US_Mean_3(4:7:floor(end/7)*7)+total_US_Mean_3(5:7:floor(end/7)*7)+total_US_Mean_3(6:7:floor(end/7)*7)+total_US_Mean_3(7:7:floor(end/7)*7);
    pred_4_m = total_US_Mean_4(1:7:floor(end/7)*7)+total_US_Mean_4(2:7:floor(end/7)*7)+total_US_Mean_4(3:7:floor(end/7)*7)+total_US_Mean_4(4:7:floor(end/7)*7)+total_US_Mean_4(5:7:floor(end/7)*7)+total_US_Mean_4(6:7:floor(end/7)*7)+total_US_Mean_4(7:7:floor(end/7)*7);

    pred_1s = mpgQuartiles_1(1:7:floor(end/7)*7,:)+mpgQuartiles_1(2:7:floor(end/7)*7,:)+mpgQuartiles_1(3:7:floor(end/7)*7,:)+mpgQuartiles_1(4:7:floor(end/7)*7,:)+mpgQuartiles_1(5:7:floor(end/7)*7,:)+mpgQuartiles_1(6:7:floor(end/7)*7,:)+mpgQuartiles_1(7:7:floor(end/7)*7,:);
    pred_2s = mpgQuartiles_2(1:7:floor(end/7)*7,:)+mpgQuartiles_2(2:7:floor(end/7)*7,:)+mpgQuartiles_2(3:7:floor(end/7)*7,:)+mpgQuartiles_2(4:7:floor(end/7)*7,:)+mpgQuartiles_2(5:7:floor(end/7)*7,:)+mpgQuartiles_2(6:7:floor(end/7)*7,:)+mpgQuartiles_2(7:7:floor(end/7)*7,:);
    pred_3s = mpgQuartiles_3(1:7:floor(end/7)*7,:)+mpgQuartiles_3(2:7:floor(end/7)*7,:)+mpgQuartiles_3(3:7:floor(end/7)*7,:)+mpgQuartiles_3(4:7:floor(end/7)*7,:)+mpgQuartiles_3(5:7:floor(end/7)*7,:)+mpgQuartiles_3(6:7:floor(end/7)*7,:)+mpgQuartiles_3(7:7:floor(end/7)*7,:);
    pred_4s = mpgQuartiles_4(1:7:floor(end/7)*7,:)+mpgQuartiles_4(2:7:floor(end/7)*7,:)+mpgQuartiles_4(3:7:floor(end/7)*7,:)+mpgQuartiles_4(4:7:floor(end/7)*7,:)+mpgQuartiles_4(5:7:floor(end/7)*7,:)+mpgQuartiles_4(6:7:floor(end/7)*7,:)+mpgQuartiles_4(7:7:floor(end/7)*7,:);

    pred_1_ms = mpgMean_1(1:7:floor(end/7)*7)+mpgMean_1(2:7:floor(end/7)*7)+mpgMean_1(3:7:floor(end/7)*7)+mpgMean_1(4:7:floor(end/7)*7)+mpgMean_1(5:7:floor(end/7)*7)+mpgMean_1(6:7:floor(end/7)*7)+mpgMean_1(7:7:floor(end/7)*7);
    pred_2_ms = mpgMean_2(1:7:floor(end/7)*7)+mpgMean_2(2:7:floor(end/7)*7)+mpgMean_2(3:7:floor(end/7)*7)+mpgMean_2(4:7:floor(end/7)*7)+mpgMean_2(5:7:floor(end/7)*7)+mpgMean_2(6:7:floor(end/7)*7)+mpgMean_2(7:7:floor(end/7)*7);
    pred_3_ms = mpgMean_3(1:7:floor(end/7)*7)+mpgMean_3(2:7:floor(end/7)*7)+mpgMean_3(3:7:floor(end/7)*7)+mpgMean_3(4:7:floor(end/7)*7)+mpgMean_3(5:7:floor(end/7)*7)+mpgMean_3(6:7:floor(end/7)*7)+mpgMean_3(7:7:floor(end/7)*7);
    pred_4_ms = mpgMean_4(1:7:floor(end/7)*7)+mpgMean_4(2:7:floor(end/7)*7)+mpgMean_4(3:7:floor(end/7)*7)+mpgMean_4(4:7:floor(end/7)*7)+mpgMean_4(5:7:floor(end/7)*7)+mpgMean_4(6:7:floor(end/7)*7)+mpgMean_4(7:7:floor(end/7)*7);

    GTW_1 = data_test.Var4(1:7:floor(end/7)*7)+data_test.Var4(2:7:floor(end/7)*7)+data_test.Var4(3:7:floor(end/7)*7)+data_test.Var4(4:7:floor(end/7)*7)+data_test.Var4(5:7:floor(end/7)*7)+data_test.Var4(6:7:floor(end/7)*7)+data_test.Var4(7:7:floor(end/7)*7);
    GTW_2 = data_test.Var5(1:7:floor(end/7)*7)+data_test.Var5(2:7:floor(end/7)*7)+data_test.Var5(3:7:floor(end/7)*7)+data_test.Var5(4:7:floor(end/7)*7)+data_test.Var5(5:7:floor(end/7)*7)+data_test.Var5(6:7:floor(end/7)*7)+data_test.Var5(7:7:floor(end/7)*7);
    GTW_3 = data_test.Var6(1:7:floor(end/7)*7)+data_test.Var6(2:7:floor(end/7)*7)+data_test.Var6(3:7:floor(end/7)*7)+data_test.Var6(4:7:floor(end/7)*7)+data_test.Var6(5:7:floor(end/7)*7)+data_test.Var6(6:7:floor(end/7)*7)+data_test.Var6(7:7:floor(end/7)*7);
    GTW_4 = data_test.Var7(1:7:floor(end/7)*7)+data_test.Var7(2:7:floor(end/7)*7)+data_test.Var7(3:7:floor(end/7)*7)+data_test.Var7(4:7:floor(end/7)*7)+data_test.Var7(5:7:floor(end/7)*7)+data_test.Var7(6:7:floor(end/7)*7)+data_test.Var7(7:7:floor(end/7)*7);

%     RMSE_1(:,27-wks_back) = sqrt(nanmean((GT_1 - pred_1_m).^2));  % Root Mean Squared Error
%     RMSE_2(:,27-wks_back) = sqrt(nanmean((GT_2 - pred_2_m).^2)); 
%     RMSE_3(:,27-wks_back) = sqrt(nanmean((GT_3 - pred_3_m).^2)); 
%     RMSE_4(:,27-wks_back) = sqrt(nanmean((GT_4 - pred_4_m).^2)); 
    %% Change to necessary format & Unnormalize
    quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
    quant_preds_deaths = nan(56,4,23);
    mean_preds_deaths = nan(56,4);
    for i = 1:4
        mean_preds_deaths(:,i) = eval(['pred_' int2str(i) '_ms']);
        quant_preds_deaths(:,i,:) = eval(['pred_' int2str(i) 's']);
    end

    for i = 1:56
        mean_preds_deaths(i,:) = mean_preds_deaths(i,:)*popu(i)/100000;
        quant_preds_deaths(i,:,:) = quant_preds_deaths(i,:,:)*popu(i)/100000;
    end


    %% Save in necessary format
    zero_date = datetime(2021, 9, 1);
    thisday = size(data_train,1)/56;
    fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
    abvs = readcell('us_states_abbr_list.txt');
    fips = cell(56, 1);
    for cid = 1:length(abvs)
        fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
    end

    Ti = table;
    thesevals = quant_preds_deaths(:);
    [cid, wh, qq] = ind2sub(size(quant_preds_deaths), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    Ti.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Ti.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
    Ti.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
    Ti.location = fips(cid);
    Ti.type = repmat({'quantile'}, [length(thesevals) 1]);
    Ti.quantile = num2cell(quant_deaths(qq));
    Ti.value = compose('%g', round(thesevals, 1));
    %%

    Tm = table;
    thesevals = mean_preds_deaths(:);
    [cid, wh] = ind2sub(size(mean_preds_deaths), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    Tm.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
    Tm.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = fips(cid);
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));

    T_all = [Ti; Tm];
    %%
    Ti = table;
    us_quants = sum(quant_preds_deaths, 1);
    thesevals = us_quants(:);
    [cid, wh, qq] = ind2sub(size(us_quants), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    Ti.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Ti.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
    Ti.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
    Ti.location = repmat({'US'}, [length(thesevals) 1]);
    Ti.type = repmat({'quantile'}, [length(thesevals) 1]);
    Ti.quantile = num2cell(quant_deaths(qq));
    Ti.value = compose('%g', round(thesevals, 1));
    %%

    Tm = table;
    us_mean = sum(mean_preds_deaths, 1);
    thesevals = us_mean(:);
    [cid, wh] = ind2sub(size(us_mean), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    Tm.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
    Tm.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = repmat({'US'}, [length(thesevals) 1]);
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));

    T_all = [T_all; Ti; Tm];
    %% Write file
    bad_idx = ismember(T_all.location, {'60', '66', '69'});
    T_all(bad_idx, :) = [];
    pathname = 'D:\USC\Research\Flu\old_data_res';
    thisdate = datestr(zero_date+thisday+1, 'yyyy-mm-dd');
    fullpath = [pathname];
    MMR_WEEK = mod(69-wks_back,52)+1
    writetable(T_all, [fullpath '\' int2str(year) '/' int2str(season) '-' int2str(MMR_WEEK) '-SGroup-RandomForest.csv']);
end