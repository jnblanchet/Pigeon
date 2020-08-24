
rate = 0;
total = 0;
for video = 5:5:900
    frame = imread(sprintf('..\\data\\video2\\%05d.png',video));
    row_count = int32(size(frame,1));
    col_count = int32(size(frame,2));
    % % frame = imrotate(frame,90);
    z = zeros(size(frame,[1 2]),'uint8');
    r = frame(:,:,1)';
    g = frame(:,:,2)';
    b = frame(:,:,3)';
    frame = [r(:)';g(:)';b(:)';z(:)'];
    frame = reshape(frame,[4, col_count, row_count]);
    
    [exitcode,s18ccode,boundingbox] = detect(frame, row_count, col_count);
    total = total + 1;
    if exitcode == 0 && isequal('J18CPTA154U072314300141N',s18ccode)
        rate = rate + 1;
    end
    fprintf('rate is %.2f%%\n',rate / total * 100); % report detection rate
    
    if exitcode == 0 && ~isequal('J18CPTA154U072314300141N',s18ccode)
        error('wrong code was returned!')
    end
    
end



