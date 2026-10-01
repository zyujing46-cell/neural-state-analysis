function showRanova(rm, withinModel, description, sphericity)
% Print the repeated-measures ANOVA table (and optionally sphericity checks).
disp(['===== Repeated-measures ANOVA (Within: ' description ', with Strain/Stim interactions) =====']);
disp(ranova(rm, 'WithinModel', withinModel));
if sphericity
    try
        disp('===== Mauchly Test of Sphericity =====');
        disp(mauchly(rm));
    catch
        warning('Mauchly test may fail for large Time factors; rely on GG/HF correction instead.');
    end
    disp('===== Epsilon Corrections (GG/HF) =====');
    disp(epsilon(rm));
end
end
