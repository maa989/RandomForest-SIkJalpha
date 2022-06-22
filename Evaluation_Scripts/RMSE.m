function RMSE_val = RMSE(GT_1,pred_1_m)
%     RMSE_val = sqrt(nanmean((GT_1 - pred_1_m).^2,1));
    RMSE_val = nanmean(abs(GT_1 - pred_1_m));
end

