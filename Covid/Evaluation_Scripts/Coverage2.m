function C = Coverage2(Quantiles,GT, thresh,wks_back)
Q = [0.010 0.0250 0.050:0.050:0.950 0.975 0.990];
mid = 0.500;
tol = eps(0.5);
lower = mid - (thresh/2);
upper = mid + (thresh/2);
lower = find(abs(Q-lower)< tol);
upper = find(abs(Q-upper)< tol);
tot = size(Quantiles,1);
% Quantiles = permute(Quantiles, [1 3 2]);
% Quantiles = reshape(Quantiles,tot*4,23);
% if length(Quantiles) == 7*wks_back
%     tot = 1;
% end
% C = nan(56,1);
    total = 0;
    true = 0;
    for cid = 1:size(Quantiles,1)
        bounds = Quantiles((cid-1)*(wks_back) + 1:(cid-1)*(wks_back) + (wks_back),[lower upper]);
        ground_truth = GT((cid-1)*(wks_back) + 1:(cid-1)*(wks_back) + (wks_back));
        for i = 1:length(ground_truth)
            if (ground_truth(i) >= bounds(i,1)) && (ground_truth(i) <= bounds(i,2))
                true = true + 1;
            end
            total = total + 1;
        end
%         C(cid) = true/total;
    end
    C = true/total;
end

