function WIS_value = WIS(GT, Quantile, K) %Assuming Quantiles for ONE certain week
% a_int = 0.99/(K+1);
% as = [a_int:a_int:0.99];
% ws = as/2;
if K ==1.5
    Q = [0.0250 0.25 0.75 0.975];
else
    Q = [0.010 0.0250 0.050:0.050:0.950 0.975 0.990];
end
% tol = eps(0.5); 
% med = find(abs(Q-0.50)< tol);
% m = Quantile(med);
sum = 0;
for k = 1:((2*K)+1)
    %Loop over states also
    for j=1:size(Quantile,1)
        if(isnan(GT(j)) || isnan(Quantile(j,k)))
            continue
        end
        if(GT(j)<=Quantile(j,k))
            sum = sum + (2*(1-Q(k))*(Quantile(j,k)-GT(j)));
        else
            sum = sum + (2*-Q(k)*(Quantile(j,k)-GT(j)));
        end
    end
end
WIS_value = sum/(size(Quantile,1)*((2*K)+1));
end

