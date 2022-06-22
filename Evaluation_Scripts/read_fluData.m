function [flu_data_m, flu_data_q] = read_fluData(path)
%PR72->52. VI78->3. US->14. WYOMING56->7. WISCONSIN55->43
    Q = [0.010 0.0250 0.050:0.050:0.950 0.975 0.990];
    flu_data_m= nan(54,4);
    flu_data_q = nan(54,23,4);
    data = readtable(path);
    indx_q = find(ismember(data.type,'quantile'));
    indx_mean = find(ismember(data.type,'point'));
    if(isempty(indx_mean))
        indx_mean = find(ismember(data.quantile,0.5));
    end
    data_mean = data(indx_mean,:);
    data_quantiles = data(indx_q,:);
    for i = 1:size(data_mean,1)
        wk = char(data_mean.target(i));
        wk = str2num(wk(1));
        if(data_mean.location(i) == 78) %Change to 52
            flu_data_m(52,wk) = data_mean.value(i);
        elseif(data_mean.location(i) == 72) %Change to 3
            flu_data_m(3,wk) =data_mean.value(i);
        elseif(data_mean.location(i) == 56) %Change to 7
            flu_data_m(7,wk) =data_mean.value(i);
        elseif(data_mean.location(i) == 55) %Change to 43
            flu_data_m(43,wk) =data_mean.value(i);
        elseif(isnan(data_mean.location(i)))%Change to 14
            flu_data_m(14,wk) =data_mean.value(i); 
        else
            flu_data_m(data_mean.location(i),wk) =data_mean.value(i);
        end
    end
    tol = eps(1);
    for i = 1:size(data_quantiles,1)
        wk = char(data_quantiles.target(i));
        wk = str2num(wk(1));
        q  = data_quantiles.quantile(i);
        q = find(abs(Q-q)<tol);
        if(data_quantiles.location(i) == 78) %Change to 52
            flu_data_q(52,q,wk) = data_quantiles.value(i);
        elseif(data_quantiles.location(i) == 72) %Change to 3
            flu_data_q(3,q,wk) =data_quantiles.value(i);
        elseif(data_quantiles.location(i) == 56) %Change to 7
            flu_data_q(7,q,wk) =data_quantiles.value(i);
        elseif(data_quantiles.location(i) == 55) %Change to 43
            flu_data_q(43,q,wk) =data_quantiles.value(i);            
        elseif(isnan(data_quantiles.location(i))) %Change to 14
            flu_data_q(14,q,wk) =data_quantiles.value(i);
        else
            flu_data_q(data_quantiles.location(i),q,wk) =data_quantiles.value(i);
        end
    end      
end

