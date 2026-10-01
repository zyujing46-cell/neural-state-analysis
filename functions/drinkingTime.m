function [perTrial, perFrame] = drinkingTime(trialTimes, trialTypes, approach, bodyCoords, boxCoords)
% Drinking time from video tracking. For every approached trial, a video
% frame counts as drinking when the body is within 9 px of the sipper on
% the trial's side between sipper-in (+5.5 s) and sipper-out (+13.5 s).
%   perTrial : drinking time of each trial (chronological order)
%   perFrame : drinking time of each video frame
[trialTimesBehav, sortOrder] = sort(trialTimes);
trialTypesBehav = trialTypes(sortOrder);
approachBehav = approach(sortOrder,1,1);
tStart = floor(trialTimesBehav);

frameTime = bodyCoords{1};
position = bodyCoords{2}(:,1:2);
atLeft  = find(pdist2(position, boxCoords(1,:)) <= 9);  % frames at the left sipper
atRight = find(pdist2(position, boxCoords(2,:)) <= 9);  % frames at the right sipper
dt = [0; diff(frameTime)];                               % frame durations

perTrial = zeros(1,length(tStart));
perFrame = zeros(size(dt));
for j = 1:length(tStart)
    if approachBehav(j) ~= 1
        continue
    end
    [~, first] = min(pdist2(tStart(j)+5.5,  frameTime));
    [~, last]  = min(pdist2(tStart(j)+13.5, frameTime));
    if trialTypesBehav(j) == 2
        frames = atLeft;
    elseif trialTypesBehav(j) == 1
        frames = atRight;
    else
        continue
    end
    frames = frames(frames >= first & frames <= last);
    perTrial(j) = sum(dt(frames));
    perFrame(frames) = dt(frames);
end
end
