function flu_data_m= read_fluDataGT(path,data_initial)
%PR72->52. VI78->3. US->14. WYOMING56->7. WISCONSIN55->43
    flu_data_m= nan(54,4);
    data = readtable(path);
    date_GT = datetime(data_initial) -days(2);%data(end,:).date;
    data_GT_m = date_GT + calweeks(4);
    indx = find((data.date>=datestr(datetime(date_GT) + days(7))) & data.date <= data_GT_m);
    data = data(indx,:);
    for i = 1:size(data,1)
        wk = (datenum(data.date(i))-datenum(date_GT))/7;
        if(data.location(i) == 78) %Change to 52
            flu_data_m(52,wk) = data.value(i);
        elseif(data.location(i) == 72) %Change to 3
            flu_data_m(3,wk) =data.value(i);
        elseif(data.location(i) == 56) %Change to 7
            flu_data_m(7,wk) =data.value(i);
        elseif(data.location(i) == 55) %Change to 43
            flu_data_m(43,wk) =data.value(i);
        elseif(isnan(data.location(i)))%Change to 14
            flu_data_m(14,wk) =data.value(i); 
        else
            flu_data_m(data.location(i),wk) =data.value(i);
        end
    end
    
end

