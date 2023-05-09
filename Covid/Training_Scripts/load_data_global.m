countries = readcell('countries_list.txt', 'Delimiter','');
passengerFlow = load('global_travel_data.txt');
passengerFlow = passengerFlow - diag(diag(passengerFlow));
popu = load('global_population_data.txt');
[tableConfirmed, tableDeaths] = getDataCOVID();
%% Extract reported cases
vals = table2array(tableConfirmed(:, 6:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
data_4 = zeros(length(countries), size(vals, 2));
lats = zeros(length(countries), 1);
longs = zeros(length(countries), 1);
for cidx = 1:length(countries)
    idx = strcmpi(countries{cidx}, tableConfirmed.CountryRegion);
    if(sum(idx)<1)
        %        disp([countries{cidx} ' not found']);
        continue;
    end
    data_4(cidx, :) = sum(vals(idx, :), 1);
    idx = find(idx);
    lats(cidx) = tableConfirmed.Lat(idx(1));
    longs(cidx) = tableConfirmed.Long(idx(1));
end

writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), 'global_data.csv');

%% Extract deaths

vals = table2array(tableDeaths(:, 6:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
deaths = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(tableConfirmed.CountryRegion, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
    end
    deaths(cidx, :) = sum(vals(idx, :), 1);
end

writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), 'global_deaths.csv');

%%
save latest_global_data.mat;
prefix = 'global'; % This ensures that the files to load and saved are named properly
lowidx = data_4(:, 60) < 50; % Note the regions with unreliable data on reference day
path = './';

forecast_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
dirname = datestr(forecast_date, 'yyyy-mm-dd');

fullpath = [path dirname];

if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end
writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath '/' prefix '_data.csv']);
writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath '/' prefix '_deaths.csv']);