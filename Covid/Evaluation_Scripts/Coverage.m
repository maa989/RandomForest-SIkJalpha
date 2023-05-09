function [true,total] = Coverage(Bounds,GT)

lower = Bounds(1,:);
upper = Bounds(2,:);
total = 0;
true = 0;

for i = 1:length(GT)
    if (GT(i) >= lower(i)) && (GT(i) <= upper(i))
        true = true + 1;
    end
    total = total + 1;
end

end

