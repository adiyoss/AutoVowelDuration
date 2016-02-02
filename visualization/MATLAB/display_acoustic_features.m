
function m = display_features(filename,frame_begin_and_end, frame_begin_and_end_real_class,normal)

if ~exist(filename, 'file')
  error(['file not found: ' filename])
end
  
tmp_filename = tempname;
system(['tail -n +2 ' filename ' > ' tmp_filename]);
m = load(tmp_filename);

if normal == 1
    for i=1:size(m,2)
        m(:,i) = m(:,i)./norm( m(:,i) );
    end
end

feature_names = {'Short Term Energy','Total Energy','Low Energy','High Energy', 'Wiener Entropy', 'Auto Correlation', 'Pitch', 'Voicing','Zero Crossing'};
len = size(feature_names);
for j=1:len(2)
    plot((m(:,j)))
    title(feature_names{j})
    max_m = 0.8; %max(max(m));
    min_m = -0.8; %min(min(m));
    hold on, line([frame_begin_and_end(1) frame_begin_and_end(1)],[min_m max_m],'Color','Black','LineWidth',1.5)
    line([frame_begin_and_end(2) frame_begin_and_end(2)],[min_m max_m],'Color','Black','LineWidth',1.5)
    line([frame_begin_and_end_real_class(1) frame_begin_and_end_real_class(1)],[min_m max_m],'Color','Red','LineWidth',1.5)
    line([frame_begin_and_end_real_class(2) frame_begin_and_end_real_class(2)],[min_m max_m],'Color','Red','LineWidth',1.5)
    hold off, pause
end
