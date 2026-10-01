function [rm, T] = fitGroupRm(Y, Strain, Stim, withinDesign, nResp)
% Repeated-measures model of the first nResp columns of Y (Var1..VarN)
% with Strain*Stim as between-subject effects.
T = array2table(Y, 'VariableNames', cellstr("Var" + (1:size(Y,2))));
T.Strain = Strain;
T.Stim = Stim;
rm = fitrm(T, sprintf('Var1-Var%d ~ Strain*Stim', nResp), 'WithinDesign', withinDesign);
end
