clear
load COVID_hospitalization_T-New_predictors_EU.mat%flu_hospitalization_T.mat
% load flu_hospitalization_TOP-New_predictorsFluSurv2 %flu_hospitalization_TOP-New_predictorsFluSurv
eu_names_table =  readtable('locations_eu.csv');
popu = eu_names_table.population;
% old_data = table;
% for i=2019:-1:2016
%     load("flu_hospitalization_TOP-New_predictors" + int2str(i)+".mat")
%     old_data = [predILI; old_data];
% end
% old_data_no2020 = [PedILI_Old; old_data];
% old_data_no2020 = PedILI_Old;
days = size(H,1)/size(popu,1); 

%% Rename places
eu_names_table =  readtable('locations_eu.csv');
eu_names = cell(size(eu_names_table,1), 1);
eu_present = zeros(size(eu_names_table,1), 1);
for jj = 1:length(eu_names_table.location)
%     if strcmpi(eu_names_table.location_name(jj), 'Czechia')==1
%         idx = find(strcmpi(countries, 'Czech Republic'));
%     else
        idx = find(strcmpi(eu_names, eu_names_table.location_name(jj)));
%     end
    if ~isempty(idx)
        eu_present(idx(1)) = 1;
        eu_names(idx(1)) = eu_names_table.location(jj);
    else
        disp([eu_names_table.location_name(jj) ' Not Found']);
    end
end

%% Add population data
% st = table;
% for i = 1:56
%     st = [st; array2table(repmat(i,239,1))];
% end
% st = repmat(st,11,1);
% % H(:,end+1) = H(:,2);
% old_data_no2020(:,end+1) = st;
st = table;
for i = 1:size(popu,1)
    st = [st; array2table(repmat(i,days,1))];
end
H(:,end+1) = st;
D(:,end+1) = st;
for i = 1:length(popu)
%     old_data_no2020.Var127(old_data_no2020.Var127 == i) = popu(i);
%     old_data_no2020.Var127(isnan(old_data_no2020.Var2)) = nan;
    H.Var223(H.Var223 == i) = popu(i);
    D.Var17(D.Var17 == i) = popu(i);
end
%% Normalize data
H2 = H;
D2 = D;
% old_data_no20202 = old_data_no2020;
for i =1:222
    H2(:,i) = array2table(eval(['H2.Var' num2str(i)]) * 100000./H2.Var223);
%     old_data_no20202(:,i) = array2table(eval(['old_data_no20202.Var' num2str(i)]) * 100000./old_data_no20202.Var127);
end

for i =1:16
    D2(:,i) = array2table(eval(['D2.Var' num2str(i)]) * 100000./D2.Var17);
%     old_data_no20202(:,i) = array2table(eval(['old_data_no20202.Var' num2str(i)]) * 100000./old_data_no20202.Var127);
end
%% Rename predictors
rlags_options = ["r0" "r7"];
un_list = ["un1" "un2" "un3"];
halpha_list = [];
for alph =  [0.93 0.96 0.99]
    alpha = "alpha" + alph;
    halpha_list = [halpha_list alpha];
end
w = ["4m" "6m" "8m"];
[X1, X2, X3, X4] = ndgrid(un_list, rlags_options, halpha_list, w);
scen_list = [X1(:), X2(:), X3(:), X4(:)];

H2 = renamevars(H2,["Var1", "Var2", "Var223"],["wkbhnd", "incwk","pop"]);
D2 = renamevars(D2,["Var1", "Var2","Var3","Var4","Var5","Var6","Var7","Var8","Var9","Var10","Var11","Var12", "Var17"],["5wkbhnd_hosp","4wkbhnd_hosp","3wkbhnd_hosp","2wkbhnd_hosp","1wkbhnd_hosp", "incwk_hosp","5wkbhnd_death","4wkbhnd_death","3wkbhnd_death","2wkbhnd_death","1wkbhnd_death", "incwk_death","pop"]);
% old_data_no20202 = renamevars(old_data_no20202,["Var1", "Var2", "Var127"],["wkbhnd", "incwk","pop"]);
for wk=1:4
    for i=1:size(scen_list,1)
        nb = (wk-1)*size(scen_list,1)+ (6+i);
        old_var = "Var"+nb;
        var_name_new = wk+join(scen_list(i,:),"");
        H2 = renamevars(H2,old_var,var_name_new);
%         old_data_no20202 = renamevars(old_data_no20202,old_var,var_name_new);
    end
end
%%
% data_train = table;
% wks_back = 0;
% for i=1:(size(H2,1)/(days*11)) %Basically looping over states
%     data_train = [data_train; H2(days*(i-1) + 1 :(days*i)-(7*wks_back),:)];
% end
% figure(2)
% plot(data_train{1:days,2});
%% Data split for newer data
for wks_back = 1:1
    data_train = table;
    data_test = table;

    data_train_D = table;
    data_test_D = table;

    for i=1:(size(H2,1)/days) %Basically looping over states
        data_train = [data_train; H2(days*(i-1) + 1:(days*i)-(7*wks_back),:)];
        data_test = [data_test; H2((days*i)-(7*wks_back) + 1:days*i -(7*(wks_back-1)),:)];

        data_train_D = [data_train_D; D2(days*(i-1) + 1:(days*i)-(7*wks_back),:)];
        data_test_D = [data_test_D; D2((days*i)-(7*wks_back) + 1:days*i -(7*(wks_back-1)),:)];
    end
    %%% Replicate this year's data (Training data)
%     train_temp = data_train;
%     rep = 2; %(increase it by rep+1 times)
%     for i = 1:rep
%         train_temp = [train_temp; data_train];
%     end
%     data_train = train_temp;
    %%%
    tic;
    Mdl_1 = TreeBagger(56,[data_train(:,[1 2 7:60 223])],[data_train.Var3],'Method','regression');
    Mdl_2 = TreeBagger(56,[data_train(:,[1 2 61:114 223])],[data_train.Var4],'Method','regression');
    Mdl_3 = TreeBagger(56,[data_train(:,[1 2 115:168 223])],[data_train.Var5],'Method','regression');
    Mdl_4 = TreeBagger(56,[data_train(:,[1 2 169:222 223])],[data_train.Var6],'Method','regression');

%     Mdl_1 = TreeBagger(56,[old_data_no20202(:,[7:36]);data_train(:,[7:36])],[old_data_no20202.Var3; data_train.Var3],'Method','regression');%,'Options',paroptions);
%     Mdl_2 = TreeBagger(56,[old_data_no20202(:,[37:66]);data_train(:,[37:66])],[old_data_no20202.Var4; data_train.Var4],'Method','regression');%,'Options',paroptions);
%     Mdl_3 = TreeBagger(56,[old_data_no20202(:,[67:96]);data_train(:,[67:96])],[old_data_no20202.Var5; data_train.Var5],'Method','regression');%,'Options',paroptions);
%     Mdl_4 = TreeBagger(56,[old_data_no20202(:,[97:126]);data_train(:,[97:126])],[old_data_no20202.Var6; data_train.Var6],'Method','regression');%,'Options',paroptions);
toc;
%     %view(Mdl_1.Trees{1}, 'Mode', 'graph')
    tic;
    predX_1 = data_test(:,[1 2 7:60 223]);%data_test(:,[1 2 13 15 16 18 19 21 22 24 127]);
    mpgMean_1 = predict(Mdl_1,predX_1);
    mpgQuartiles_1 = quantilePredict(Mdl_1,predX_1,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_2 = data_test(:,[1 2 61:114 223]);
    mpgMean_2 = predict(Mdl_2,predX_2);
    mpgQuartiles_2 = quantilePredict(Mdl_2,predX_2,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_3 = data_test(:,[1 2 115:168 223]);
    mpgMean_3 = predict(Mdl_3,predX_3);
    mpgQuartiles_3 = quantilePredict(Mdl_3,predX_3,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_4 = data_test(:,[1 2 169:222 223]);
    mpgMean_4 = predict(Mdl_4,predX_4);
    mpgQuartiles_4 = quantilePredict(Mdl_4,predX_4,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    toc;
    %%% Now deaths
    tic;
    Mdl_1 = TreeBagger(56,[data_train_D(:,[1:12 17])],[data_train_D.Var13],'Method','regression');
    Mdl_2 = TreeBagger(56,[data_train_D(:,[1:12 17])],[data_train_D.Var14],'Method','regression');
    Mdl_3 = TreeBagger(56,[data_train_D(:,[1:12 17])],[data_train_D.Var15],'Method','regression');
    Mdl_4 = TreeBagger(56,[data_train_D(:,[1:12 17])],[data_train_D.Var16],'Method','regression');

    predX_1 = data_test_D(:,[1:12 17]);%data_test(:,[1 2 13 15 16 18 19 21 22 24 127]);
    mpgMean_1_D = predict(Mdl_1,predX_1);
    mpgQuartiles_1_D = quantilePredict(Mdl_1,predX_1,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_2 = data_test_D(:,[1:12 17]);
    mpgMean_2_D = predict(Mdl_2,predX_2);
    mpgQuartiles_2_D = quantilePredict(Mdl_2,predX_2,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_3 = data_test_D(:,[1:12 17]);
    mpgMean_3_D = predict(Mdl_3,predX_3);
    mpgQuartiles_3_D = quantilePredict(Mdl_3,predX_3,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    predX_4 = data_test_D(:,[1:12 17]);
    mpgMean_4_D = predict(Mdl_4,predX_4);
    mpgQuartiles_4_D = quantilePredict(Mdl_4,predX_4,'Quantile',[0.010, 0.025, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 0.975, 0.990]);
    toc;

    %%% Find across all US
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
    
    %%% Weekly data
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
    

    pred_1s_D = mpgQuartiles_1_D(1:7:floor(end/7)*7,:)+mpgQuartiles_1_D(2:7:floor(end/7)*7,:)+mpgQuartiles_1_D(3:7:floor(end/7)*7,:)+mpgQuartiles_1_D(4:7:floor(end/7)*7,:)+mpgQuartiles_1_D(5:7:floor(end/7)*7,:)+mpgQuartiles_1_D(6:7:floor(end/7)*7,:)+mpgQuartiles_1_D(7:7:floor(end/7)*7,:);
    pred_2s_D = mpgQuartiles_2_D(1:7:floor(end/7)*7,:)+mpgQuartiles_2_D(2:7:floor(end/7)*7,:)+mpgQuartiles_2_D(3:7:floor(end/7)*7,:)+mpgQuartiles_2_D(4:7:floor(end/7)*7,:)+mpgQuartiles_2_D(5:7:floor(end/7)*7,:)+mpgQuartiles_2_D(6:7:floor(end/7)*7,:)+mpgQuartiles_2_D(7:7:floor(end/7)*7,:);
    pred_3s_D = mpgQuartiles_3_D(1:7:floor(end/7)*7,:)+mpgQuartiles_3_D(2:7:floor(end/7)*7,:)+mpgQuartiles_3_D(3:7:floor(end/7)*7,:)+mpgQuartiles_3_D(4:7:floor(end/7)*7,:)+mpgQuartiles_3_D(5:7:floor(end/7)*7,:)+mpgQuartiles_3_D(6:7:floor(end/7)*7,:)+mpgQuartiles_3_D(7:7:floor(end/7)*7,:);
    pred_4s_D = mpgQuartiles_4_D(1:7:floor(end/7)*7,:)+mpgQuartiles_4_D(2:7:floor(end/7)*7,:)+mpgQuartiles_4_D(3:7:floor(end/7)*7,:)+mpgQuartiles_4_D(4:7:floor(end/7)*7,:)+mpgQuartiles_4_D(5:7:floor(end/7)*7,:)+mpgQuartiles_4_D(6:7:floor(end/7)*7,:)+mpgQuartiles_4_D(7:7:floor(end/7)*7,:);
    
    pred_1_ms_D = mpgMean_1_D(1:7:floor(end/7)*7)+mpgMean_1_D(2:7:floor(end/7)*7)+mpgMean_1_D(3:7:floor(end/7)*7)+mpgMean_1_D(4:7:floor(end/7)*7)+mpgMean_1_D(5:7:floor(end/7)*7)+mpgMean_1_D(6:7:floor(end/7)*7)+mpgMean_1_D(7:7:floor(end/7)*7);
    pred_2_ms_D = mpgMean_2_D(1:7:floor(end/7)*7)+mpgMean_2_D(2:7:floor(end/7)*7)+mpgMean_2_D(3:7:floor(end/7)*7)+mpgMean_2_D(4:7:floor(end/7)*7)+mpgMean_2_D(5:7:floor(end/7)*7)+mpgMean_2_D(6:7:floor(end/7)*7)+mpgMean_2_D(7:7:floor(end/7)*7);
    pred_3_ms_D = mpgMean_3_D(1:7:floor(end/7)*7)+mpgMean_3_D(2:7:floor(end/7)*7)+mpgMean_3_D(3:7:floor(end/7)*7)+mpgMean_3_D(4:7:floor(end/7)*7)+mpgMean_3_D(5:7:floor(end/7)*7)+mpgMean_3_D(6:7:floor(end/7)*7)+mpgMean_3_D(7:7:floor(end/7)*7);
    pred_4_ms_D = mpgMean_4_D(1:7:floor(end/7)*7)+mpgMean_4_D(2:7:floor(end/7)*7)+mpgMean_4_D(3:7:floor(end/7)*7)+mpgMean_4_D(4:7:floor(end/7)*7)+mpgMean_4_D(5:7:floor(end/7)*7)+mpgMean_4_D(6:7:floor(end/7)*7)+mpgMean_4_D(7:7:floor(end/7)*7);
   
%     GTW_1 = data_test.Var3(1:7:floor(end/7)*7)+data_test.Var3(2:7:floor(end/7)*7)+data_test.Var3(3:7:floor(end/7)*7)+data_test.Var3(4:7:floor(end/7)*7)+data_test.Var3(5:7:floor(end/7)*7)+data_test.Var3(6:7:floor(end/7)*7)+data_test.Var3(7:7:floor(end/7)*7);
%     GTW_2 = data_test.Var4(1:7:floor(end/7)*7)+data_test.Var4(2:7:floor(end/7)*7)+data_test.Var4(3:7:floor(end/7)*7)+data_test.Var4(4:7:floor(end/7)*7)+data_test.Var4(5:7:floor(end/7)*7)+data_test.Var4(6:7:floor(end/7)*7)+data_test.Var4(7:7:floor(end/7)*7);
%     GTW_3 = data_test.Var5(1:7:floor(end/7)*7)+data_test.Var5(2:7:floor(end/7)*7)+data_test.Var5(3:7:floor(end/7)*7)+data_test.Var5(4:7:floor(end/7)*7)+data_test.Var5(5:7:floor(end/7)*7)+data_test.Var5(6:7:floor(end/7)*7)+data_test.Var5(7:7:floor(end/7)*7);
%     GTW_4 = data_test.Var6(1:7:floor(end/7)*7)+data_test.Var6(2:7:floor(end/7)*7)+data_test.Var6(3:7:floor(end/7)*7)+data_test.Var6(4:7:floor(end/7)*7)+data_test.Var6(5:7:floor(end/7)*7)+data_test.Var6(6:7:floor(end/7)*7)+data_test.Var6(7:7:floor(end/7)*7);
%     
    
    %%% Change to necessary format & Unnormalize
    quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
    quant_cases = quant_deaths;

    quant_preds_cases = nan(size(popu,1),4,23);
    mean_preds_cases = nan(size(popu,1),4);
    quant_preds_deaths = nan(size(popu,1),4,23);
    mean_preds_deaths = nan(size(popu,1),4);

    for i = 1:4
        mean_preds_cases(:,i) = eval(['pred_' int2str(i) '_ms']);
        quant_preds_cases(:,i,:) = eval(['pred_' int2str(i) 's']);
    end
    
    for i = 1:size(popu,1)
        mean_preds_cases(i,:) = mean_preds_cases(i,:)*popu(i)/100000;
        quant_preds_cases(i,:,:) = quant_preds_cases(i,:,:)*popu(i)/100000;
    end


    for i = 1:4
        mean_preds_deaths(:,i) = eval(['pred_' int2str(i) '_ms_D']);
        quant_preds_deaths(:,i,:) = eval(['pred_' int2str(i) 's_D']);
    end
    
    for i = 1:size(popu,1)
        mean_preds_deaths(i,:) = mean_preds_deaths(i,:)*popu(i)/100000;
        quant_preds_deaths(i,:,:) = quant_preds_deaths(i,:,:)*popu(i)/100000;
    end
    

    %%% Save in necessary format
    zero_date = datetime(2020, 1, 3);
    %%% Date correction
    thisday = days-7*(wks_back-1) +7;
    eu_names_short = eu_names_table.location;%eu_names(eu_present>0);
    
    %eu_names_short = eu_names(eu_present>0);
    T = table;
    quant_matrix = quant_preds_cases;%(eu_present>0, 1:max_weeks, :);
    thesevals = quant_matrix(:);
    [cc, wh, qq] = ind2sub(size(quant_matrix), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.forecast_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);%repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.target = strcat(wh_string(wh), ' wk ahead inc case');
    T.target_end_date = datestr(thisday+zero_date + 7*(wh), 'YYYY-mm-DD');
    T.location = eu_names_short(cc);
    T.type = repmat({'quantile'}, [length(thesevals) 1]);
    T.quantile = compose('%.3f', (quant_cases(qq)'));
    T.value = compose('%g', round(thesevals, 0));
    
    T1 = table;
    quant_matrix = quant_preds_deaths;%(eu_present>0, 1:max_weeks, :);
    thesevals = quant_matrix(:);
    [cc, wh, qq] = ind2sub(size(quant_matrix), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T1.forecast_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);%repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T1.target = strcat(wh_string(wh), ' wk ahead inc death');
    T1.target_end_date = datestr(thisday+zero_date + 7*(wh), 'YYYY-mm-DD');
    T1.location = eu_names_short(cc);
    T1.type = repmat({'quantile'}, [length(thesevals) 1]);
    T1.quantile = compose('%.3f', (quant_deaths(qq)'));
    T1.value = compose('%g', round(thesevals, 0));
    
    T2 = table;
    mean_matrix = mean_preds_cases;%(eu_present>0, 1:max_weeks);
    thesevals = mean_matrix(:);
    [cc, wh] = ind2sub(size(mean_matrix), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T2.forecast_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);%repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T2.target = strcat(wh_string(wh), ' wk ahead inc case');
    T2.target_end_date = datestr(thisday+zero_date + 7*(wh), 'YYYY-mm-DD');
    T2.location = eu_names_short(cc);
    T2.type = repmat({'point'}, [length(thesevals) 1]);
    T2.quantile = repmat({'NA'}, [length(thesevals) 1]);
    T2.value = compose('%g', round(thesevals, 0));
    
    T3 = table;
    mean_matrix = mean_preds_deaths;%(eu_present>0, 1:max_weeks);
    thesevals = mean_matrix(:);
    [cc, wh] = ind2sub(size(mean_matrix), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T3.forecast_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);%repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T3.target = strcat(wh_string(wh), ' wk ahead inc death');
    T3.target_end_date = datestr(thisday+zero_date + 7*(wh), 'YYYY-mm-DD');
    T3.location = eu_names_short(cc);
    T3.type = repmat({'point'}, [length(thesevals) 1]);
    T3.quantile = repmat({'NA'}, [length(thesevals) 1]);
    T3.value = compose('%g', round(thesevals, 0));
    
    T_all = [T; T1; T2; T3];
    %%% Write file
    bad_idx = ismember(T_all.location, {'60', '66', '69'});
    T_all(bad_idx, :) = [];
    pathname = '../22_data-forecasts_covid_EU/';
    thisdate = datestr(zero_date+thisday, 'yyyy-mm-dd');
    fullpath = [pathname];
    writetable(T_all, [fullpath '/' thisdate '-SGroup-RandomForest.csv']);
end
%%
cidx = 1;
% sel_idx = 4; %sel_idx = contains(countries, 'Florida');
% dt = hosp_cumu(cidx, :);
% dts = hosp_cumu_s(cidx, :);
figure(1);
thisquant = squeeze(nansum(quant_preds_deaths(cidx, :, [1 7 12 17 23]), 1));
thismean = (nansum(mean_preds_deaths(cidx, :), 1));
% gt_len = 20-wks;
% gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
% gt_idx= (1:7:days);
% gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
% gts = diff(nansum(dts(sel_idx, gt_idx), 1))';

% plot(data_train{1:days,2}, 'r'); hold on;
% plot([gt gts]); hold on; 
plot([thisquant]); hold on;
plot([thismean], 'o'); hold off;
title(['Deaths ' eu_names_short{cidx}]);

figure(2);
thisquant = squeeze(nansum(quant_preds_cases(cidx, :, [1 7 12 17 23]), 1));
thismean = (nansum(mean_preds_cases(cidx, :), 1));
% gt_len = 20-wks;
% gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
% gt_idx= (1:7:days);
% gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
% gts = diff(nansum(dts(sel_idx, gt_idx), 1))';

% plot(data_train{1:days,2}, 'r'); hold on;
% plot([gt gts]); hold on; 
plot([thisquant]); hold on;
plot([thismean], 'o'); hold off;
title(['Cases ' eu_names_short{cidx}]);
