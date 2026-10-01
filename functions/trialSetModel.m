function S = trialSetModel(firingRate, drinkbehav, trialTimesBehav, drinkTime, binSize)
% Trial-set model of one session: keep CS+ trials, group them into trial
% sets, compute the trial-set recurrence matrix (rmTrialSet) and affinity matrix,
% and the seeking intensity of each set.
keep = drinkbehav==1 | drinkbehav==2;
S.drinkbehav = drinkbehav(keep);
S.drinkTime = drinkTime(keep);
[S.drinkLabel, S.trialSetRange, blockStart] = groupTrialSets(S.drinkbehav, 3);
[S.rmTrialSet, S.dfcVec] = trialSetRecurrence(firingRate, blockStart, trialTimesBehav(keep), binSize);
% Affinity: cosine similarity of RM columns above their 50th percentile
S.amTrialSet = computeAffinityMatrix(S.rmTrialSet, 50);
% Seeking intensity: peak of the HRF-convolved drinking time in each set
S.siCurve = seekingIntensityCurve(S.drinkTime);
S.seekIntensity = cellfun(@(iv) max(S.siCurve(iv(1):iv(2))), S.trialSetRange);
end
