function [exitcode,s18ccode,boundingbox] = detectHD(frame, row_count, col_count) %#codegen
% frame is a RGBA packed uint8 buffer of size 4K (maximum resolution)
% any frame containing more pixels will not be accepted

    DEBUG = false;
    % % frame = imresize(imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200817_175602.jpg'),[1920 1080]);
    % % frame = imresize(imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\test3.png'),[1920 1080]);
%     frame = imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200822_100443.jpg');
% frame = imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200822_1004432.jpg');
% frame = imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200817_175637.jpg');
%     frame = imresize(frame,0.25);
%     row_count = int32(size(frame,1));
%     col_count = int32(size(frame,2));
%     % % frame = imrotate(frame,90);
%     z = zeros(size(frame,[1 2]),'uint8');
%     r = frame(:,:,1)';
%     g = frame(:,:,2)';
%     b = frame(:,:,3)';
%     frame = [r(:)';g(:)';b(:)';z(:)'];
%     frame = reshape(frame,[4, col_count, row_count]);
    
    
    % check types and sizes
    assert(isa(row_count, 'int32'));
    assert(numel(row_count) == 1);
    assert(isa(col_count, 'int32'));
    assert(numel(col_count) == 1);
    
    assert(isa(frame, 'uint8'));
    assert(all( size(frame) == [ 4, 3840, 2160])); % frames comes in as RGBA packed row major
    REAL_LEN = row_count * col_count * 4;
    assert((row_count * col_count * 4) <= REAL_LEN);
        
    s18ccode = '000000000000000000000000';
    exitcode = int32(0);

    if DEBUG
        webcoder.console.log(sprintf('Processing image of size %d x %d.',int32(col_count),int32(row_count)));
    end
    %% Preprocessing
    % packed 2 planar, and single conversion (memory efficient implementation)
    f = zeros([row_count,col_count,3],'single');
    id = int32(1);
    for x = 1:row_count
        for y = 1:col_count
            f(x,y,1) = single(frame(id+0));
            f(x,y,2) = single(frame(id+1));
            f(x,y,3) = single(frame(id+2));
            id = id + 4;
        end
    end
    
    %% Feature Extraction
    BLOCK_SIZE = 5;
    SCALE_FACT = 3;

    f_small = imresize(f,1/SCALE_FACT,'nearest');

    gx_buff = zeros(size(f_small),class(f_small));
    gy_buff = zeros(size(f_small),class(f_small));
    for channel=1:3
        gx_buff(:,:,channel) = conv2(f_small(:,:,channel),[-1 -2 -1; 0 0 0; 1 2 1],'same');
        gy_buff(:,:,channel) = conv2(f_small(:,:,channel),[-1 0 1; -2 0 2; -1 0 1],'same');
    end
    
    colorphase = cat(3,...
                    atan2(gx_buff(:,:,2),gx_buff(:,:,1)),...
                    atan(gx_buff(:,:,3)./(sqrt(gx_buff(:,:,1).^2+gx_buff(:,:,2).^2))),...
                    atan2(gy_buff(:,:,2),gy_buff(:,:,1)),...
                    atan(gy_buff(:,:,3)./(sqrt(gy_buff(:,:,1).^2+gy_buff(:,:,2).^2)))...
                 );

    % accumulate featuresogram (in a c friendly way)
    N_BINS_P1 = 6;
    N_BINS_P2 = 6;
    N_BINS = N_BINS_P1 * N_BINS_P2;
    grid_x = floor(size(f_small,1) / BLOCK_SIZE);
    grid_y = floor(size(f_small,2) / BLOCK_SIZE);
    features = zeros(grid_x,grid_y,N_BINS,'single');
    for cell_x = 0:grid_x-1
        for cell_y = 0:grid_y-1
            for px_x = cell_x * BLOCK_SIZE:(cell_x+1) * BLOCK_SIZE - 1
                for px_y = cell_y * BLOCK_SIZE:(cell_y+1) * BLOCK_SIZE - 1
                    % gx
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,1)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,2)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    if b >= 0 && b < N_BINS
                        features(cell_x+1,cell_y+1,b+1) = features(cell_x+1,cell_y+1,b+1) + 1;
                    end
                    % repeat for gy
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,3)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,4)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    if b >= 0 && b < N_BINS
                        features(cell_x+1,cell_y+1,b+1) = features(cell_x+1,cell_y+1,b+1) + 1;
                    end
                end
            end
        end
    end
    
    % normalize
    maxbin = 30;
    features = features(:,:,1:maxbin);
    features = features / (2*BLOCK_SIZE*BLOCK_SIZE);
    features = reshape(features,size(features,1)*size(features,2),size(features,3));
    
    if DEBUG
        webcoder.console.log(sprintf('Computed feature histogram %d x %d.',int32(grid_y),int32(grid_x)));
    end
    %% Classify
    M = [    0.0527    1.5903    0.9982   -0.0369   -0.5392   -0.1954    0.1030    0.7808    2.9037   -0.8245   -1.3336   -1.5216    0.7569   -1.2331    0.1142   -0.4805    0.7901   -1.8255    1.6295   -2.3931   -0.4514   -0.0468   2.2480    0.8620   -1.4884   -1.3545   -0.4550   -0.5069    3.8599   -1.3284]';
    score = features * M; % eval
    score = reshape(score,grid_x,grid_y);
    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
    valid = score > prctile(score(:),98);

    if DEBUG
        webcoder.console.log(sprintf('Found %d bar-like cells out of %d across the image.',int32(sum(valid(:))),int32(numel(valid))));    
    end
    
    %% ROI candidate post-processing
    % quick dilation to connect barcode cell fragments
    valid_ = reshape(valid,grid_x,grid_y);
    % left
    for x = 1:grid_x
        for y = 2:grid_y
            if valid_(x,y)
                valid_(x,y-1) = true;
            end
        end
    end
    % right
    for x = 1:grid_x
        for y = grid_y-1:-1:1
            if valid_(x,y)
                valid_(x,y+1) = true;
            end
        end
    end
    % top
    for x = 2:grid_x
        for y = 1:grid_y
            if valid_(x,y)
                valid_(x-1,y) = true;
            end
        end
    end
    % bottom
    for x = grid_x-1:-1:1
        for y = 1:grid_y
            if valid_(x,y)
                valid_(x+1,y) = true;
            end
        end
    end
    
    %% Find Barcode Candidates Regions       
    [CC,n] = bwlabel(valid_);
    
    if DEBUG
        webcoder.console.log(sprintf('Found %d good connected regions.',int32(n)));
    end
 
    best_bar_code = false(size(CC));
    if n == 0
        % no valid regions were identified return error
    elseif n > 1
        % keep only the largest region<
        barcode_candidate_area = zeros(n,1,'uint32');
        for lbl = 1:numel(CC)
            if CC(lbl) > 0
                barcode_candidate_area(CC(lbl)) = barcode_candidate_area(CC(lbl)) + 1;
            end
        end
        [maxarea,id] = max(barcode_candidate_area);
        
    if DEBUG
        webcoder.console.log(sprintf('Largest candidate has %d blocks.',int32(maxarea)));
    end
    
        best_bar_code = CC == id;
    else
        best_bar_code = logical(CC);
    end

    %% Find bounding box, centroid, eccentricity and orientation
    scale = size(f,1) / size(valid_,1);
    [idx,idy] = ind2sub(size(best_bar_code),find(best_bar_code));
        
    centroid = [mean(idx) mean(idy)];
    x0 = (min(idx)-1);
    x1 = (max(idx));
    y0 = (min(idy)-1);
    y1 = (max(idy));
    boundingbox = (single([y0 x0 y1 x1] * scale));

    if DEBUG
        webcoder.console.log(sprintf('Best boudingbox is (x0,y0,x0,y1) = %.1f,%.1f,%.1f,%.1f.',single(boundingbox(1)),single(boundingbox(2)),single(boundingbox(3)),single(boundingbox(4))));
    end
    
    % idx has something inside!
    pts = double([idx(:), idy(:)]) - repmat(double(centroid),numel(idx),1); % matrix operation broadcast doesn't compile well
    
    [~,S,V] = svd(pts);
    D = diag(S);

    eccentricity = 1 - (D(2) / D(1)); % how line-like is this shape?
    orientation = 90+rad2deg(atan2(V(2),V(1)));
  
    if DEBUG
        webcoder.console.log(sprintf('Eccentricity of %.1f and orientation of %.1f deg.',single(eccentricity), single(orientation)));
    end
    
    if eccentricity < 0.80
        % it does not look like a bar! the length-width ratio is off
        exitcode = int32(-1);
    else
%     figure(1)
%     scatter(x,y)
%     axis equal
%     hold on
%     quiver(centroid(1),centroid(2),V(1)*10,V(2)*10)
%     quiver(centroid(1),centroid(2),V(3)*10,V(4)*10)
%     hold off
%     figure(2)
%     imshow(imrotate(best_bar_code,-orientation))

    rot = @(angle) [cosd(angle), -sind(angle); sind(angle), cosd(angle)];
    rotated_bb = (rot(-orientation) * (pts)' + repmat(centroid',1,size(pts,1)));
    W = ceil(max(rotated_bb(2,:)) - min(rotated_bb(2,:))) + 10; % extra padding to capture all the edges
    H = ceil(max(rotated_bb(1,:)) - min(rotated_bb(1,:))); 
%     figure(1)
%     imshow(best_bar_code)
%     hold on
%     scatter(rotated_bb(2,:),rotated_bb(1,:))
%     hold off
% 
    
    
    %% Extract barcode ROI
    scale = size(f,1) / size(best_bar_code,1);

    [yy,xx] = meshgrid(-W/2:W/2-1, -H/2:H/2-1);
    pts = scale * (rot(orientation) * [xx(:),yy(:)]' + repmat((centroid-1)',1,numel(xx)));
    
    if DEBUG
        webcoder.console.log(sprintf('extracted barcode candidate of size %d by %d.',int32(size(yy,2)), int32(size(yy,1))));
    end
%     figure(1), imshow(f)
%     hold on
%     scatter(pts(2,:),pts(1,:))
%     hold off
    
%     resamp = makeresampler('linear','fill');
    TARGET_WIDTH = 800;
    xx = imresize(reshape(pts(1,:),[H,W]),TARGET_WIDTH / W);
    yy = imresize(reshape(pts(2,:),[H,W]),TARGET_WIDTH / W);

%     tmap_B = cat(3,yy,xx);
%     imbar = tformarray(f,[],resamp,[2 1],[1 2],[],tmap_B+1,0);
    imbar = applyLookUpTable(f,xx,yy);
    
    red_ratio = @(im) (2*im(:,:,1)) - (im(:,:,2) + im(:,:,3));
    imbar_score = red_ratio(imbar);
    minscore = min(imbar_score(:));
    maxscore = max(imbar_score(:));
    imbar_score = (imbar_score - minscore) / (maxscore - minscore);

    
    % some cameras do very poor color balance:
    %     balance = mean(imbar,[1 2]);
    %     balance = balance ./ mean(balance);
    %     imbar = imbar ./ balance;
    
    %% refine rotation
    
%     theta = [89.5:0.05:91.5];
%     R = radon(imbar_score,theta);
%     col = (1:size(R,1))';
%     variance_per_angle = zeros(size(theta));
%     for i=1:size(R,2)
%         variance_per_angle(i) = std(col,R(:,i));
%     end
%     
%     [~,bestangle] = min(variance_per_angle);
%     bestangle = 90-theta(bestangle);
%     
%     imbar_score = imrotate(imbar_score,-bestangle,'crop');
%     imshow(imbar_score)
%     
    %% Refine ROI
    [H,W] = size(imbar_score);
    % find the top and the bottom
    vertical_profile = sum(imbar_score,2);
    T = mean(vertical_profile)*1; % The vertical profile has more white than black. this heuristic gives us a good threshold.
    span = [1 1];
    for i=round(H/2):-1:1 % find upper bound
        if vertical_profile(i) < T
            span(1) = i;
            break;
        end
    end
    for i=round(H/2):1:H % find lower bound
        if vertical_profile(i) < T
            span(2) = i;
            break;
        end
    end
    imbar_score = imbar_score(span(1):span(2),:);

    
    horizontal_profile = sum(imbar_score,1);
    T = mean(horizontal_profile);
    peaks = find(horizontal_profile > T);
    span = [max(1,peaks(1)-2) min(W,peaks(end)+2)];
    imbar_score = imbar_score(:,span(1):span(2));
    
    % imshow(imbar_score,[])

    [H,W] = size(imbar_score);
    t0 = round(H/3);
    t1 = round(2*H/3);
    
    % dilate (top and bottom have more weight
    imbar_score_dilate = zeros(size(imbar_score));
    for i = 1:size(imbar_score_dilate,1)
        w = 1;
        if i <= t0 || i >= t1
            w = 2;
        end
        for j = 1:size(imbar_score_dilate,2)
            imbar_score_dilate(i,j) = max(imbar_score(i,max(1,j-w):min(j+w,W)));
        end
    end   
    
    row0_profile = mean(imbar_score_dilate(1:t0,:));
    row1_profile_unfiltered = mean(imbar_score_dilate(t0+1:t1,:));
    row2_profile = mean(imbar_score_dilate(t1:end,:));
    
    % apply a laplacian filter to enhance peaks. kernel size is based on 800 px divided by 75 bars
    h = 2*[0.4490    0.3747    0.1853   -0.1663   -0.5111   -0.6667   -0.5111   -0.1663    0.1853    0.3747    0.4490 ];
    lap = conv([ones(1,5) * row1_profile_unfiltered(1), row1_profile_unfiltered, ones(1,5) * row1_profile_unfiltered(end)],h,'valid');
    row1_profile = row1_profile_unfiltered - lap;
    
%     lap = conv([ones(1,5) * row0_profile(1), row0_profile, ones(1,5) * row0_profile(end)],h,'valid');
%     row0_profile = row0_profile - lap;
%     lap = conv([ones(1,5) * row2_profile(1), row2_profile, ones(1,5) * row2_profile(end)],h,'valid');
%     row2_profile = row2_profile - lap;    
%     
    % plot([row0_profile;row1_profile_unfiltered;row2_profile]'), legend({'top','center','bottom'})
    
    %% Extract Binary String
    H = hist(row1_profile,0:0.01:1);
    threshC = otsuthresh(H);
%     threshT = mean(row0_profile);
%     threshB = mean(row2_profile);
    
    % because of the Laplacian enhancement, threshold for row0 and row2 can be much higher
%     T = row0_profile > threshT; % top
    C = row1_profile > threshC; % center
%     B = row2_profile > threshB; % bottom

    [cc,n] = bwlabel(C);
    if n ~= 75
        exitcode = int32(-2);
    else

    sampling_centroid = zeros(1,75);
    sampling_count = zeros(1,75);
    for i=1:numel(cc)
        lbl = cc(i);
        if lbl > 0
            sampling_centroid(lbl) = sampling_centroid(lbl) + i;
            sampling_count(lbl) = sampling_count(lbl) + 1;
        end
    end
    sampling_centroid = round(sampling_centroid ./ sampling_count);

    % the center bar should be only ones
    if sum(C(sampling_centroid)) ~= 75
        exitcode = int32(-3);
    else

        
    T = false(1,75);
    B = false(1,75);
    for c=1:numel(sampling_centroid)
        peak = sampling_centroid(c);
        if c==1
            bottom = round((sampling_centroid(c) + sampling_centroid(c+1))/2);
        elseif c==numel(sampling_centroid)
            bottom = round((sampling_centroid(c-1) + sampling_centroid(c))/2);
        else
            bottom = [round((sampling_centroid(c-1) + sampling_centroid(c))/2), ...
                      round((sampling_centroid(c+1) + sampling_centroid(c))/2)];
        end
        
        expected_white = row1_profile_unfiltered(peak);
        expected_black = min([row1_profile_unfiltered(bottom),...
                            row0_profile(bottom),...
                            row2_profile(bottom)]);
        
        % make it true if it's closer to the peak
        T(c) = abs(row0_profile(peak) - expected_white) < abs(row0_profile(peak) - expected_black);
        B(c) = abs(row2_profile(peak) - expected_white) < abs(row2_profile(peak) - expected_black);
    end

    %% Parse binary string
    % top,bottom bits values: 00, 01, 10, 11 where 1 is white
    codes = ['T','D','A','F'];
    code_ = codes(1+T * 2 + B);
%     code_ = 'FDFTTTAADDFDAFAAAFTTADTDAATTFFAAATFATDAAFAFDDFFDAFATAATFTDATFFDADFDADTFFDDT';
%     code_ = 'DFDFFAADATFADFTDADFATFDDTDDTDDFTFTAFDFFATATTFADTFAATATAFATTDDTAFFDADFDFDFF';
    % % % J18CUSA8E6N062315014880T
    % check orientation
    left_sync = code_(7:9);
    right_sync = code_(numel(code_)-8:numel(code_)-6);
    isvalid = true;
    if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
        % if the sync codes are wrong, the code may be flipped
        codes = ['T','A','D','F'];
        code_ = codes(1+T(end:-1:1) * 2 + B(end:-1:1));
        left_sync = code_(7:9);
        right_sync = code_(numel(code_)-8:numel(code_)-6);
        if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
            % error: code was misread because the sync codes are wrong
            isvalid = false;
        end
    end
    
    if ~isvalid
        exitcode = int32(-4);
    else
    % crop out sync codes, copy the rest to a new buffer
    valid = true(1,numel(code_));
    valid([7:9 numel(code_)-8:numel(code_)-6]) = false;
    code = code_(valid);

    % crop out ECC TODO: solomon reed correction
    % ecc = code(59:70);
    % code(59:70) = [];

    assert(all( size(code) == [1 69]));
    
    % convert to binary
    binary = true(2,69);
    for i=1:numel(code)
        if code(i) == 'F'
            binary(:,i) = [false; false];
        elseif code(i) == 'A'
            binary(:,i) = [false; true];
        elseif code(i) == 'D'
            binary(:,i) = [true; false];
        end
    end
    binary = binary(:)';

    assert(all( size(binary) == [1 138]));
    
    % +1 for MATLAB 1 based indexing
    parsebin2dec = @(bin) bin2dec(char(uint8(bin)+48));

    %% field 1: UPU identifier
    UPU_identifier = 'J'; % always J

    s18ccode(1) = UPU_identifier;
    if DEBUG
        webcoder.console.log(sprintf('UPU_identifier is always J: %c',char(UPU_identifier)));
    end
    
    %% field 2: format
    % TODO: error detection, only [1 4] possible
    format_identifier_bits = (0:3)+1;
    format_identifier_id = parsebin2dec(binary(format_identifier_bits));
    if format_identifier_id ~= 2
        exitcode = int32(-4);
        return;
    end
    
    %format_identifiers = {'18A','18B','18C','18D'};
    format_identifier = '   ';
    if format_identifier_id == 0
        format_identifier = '18A';
    elseif format_identifier_id == 1
        format_identifier = '18B';
    elseif format_identifier_id == 2
        format_identifier = '18C';
    elseif format_identifier_id == 3
        format_identifier = '18D';
    end
    
    s18ccode(2:4) = format_identifier;
    if DEBUG
        webcoder.console.log(sprintf('format_identifier is: %s',char(format_identifier)));
    end
    
    %% field 3: issuer_code
    issuer_code_bits = (4:19)+1;
    %3 characters
    %1: S18 table 1, INT(I/1600)
    %2: INT(MOD(I,1600)/40_ S18a, table 1
    %3: MOD(I,40)

    alphabet_table1 = 'ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210';
    issuer_code_id = parsebin2dec(binary(issuer_code_bits));
    % issuer_code_id = 16003;
    % issuer_code_id = parsebin2dec([0 0 1 0 0 0 0 0 0 1 1 1 0 0 0 1]);
    % pzw
    issuer_code_id_1 = floor((issuer_code_id) / 1600);
    issuer_code_1 = alphabet_table1(issuer_code_id_1+1);

    issuer_code_id_2 = floor(mod((issuer_code_id),1600)/40);
    issuer_code_2 = alphabet_table1(issuer_code_id_2+1);

    issuer_code_id_3 = floor(mod((issuer_code_id),40));
    issuer_code_3 = alphabet_table1(issuer_code_id_3+1);

    issuer_code = [issuer_code_1, issuer_code_2, issuer_code_3];

    s18ccode(5:7) = issuer_code;
    if DEBUG
        webcoder.console.log(sprintf('issuer_code is: %s',char(issuer_code)));
    end

    %% field 4: equipement_id
    hex_table1 = '0123456789ABCDEF';
    equipement_id_bits_1 = (20:23)+1; % hex 0-9;A-F
    equipement_id_bits_2 = (24:27)+1;
    equipement_id_bits_3 = (28:31)+1;

    equipement_id_1 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_1)));
    equipement_id_2 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_2)));
    equipement_id_3 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_3)));

    equipement_id = [equipement_id_1, equipement_id_2, equipement_id_3];

    s18ccode(8:10) = equipement_id;
    if DEBUG
        webcoder.console.log(sprintf('equipement_id is: %s',char(equipement_id)));
    end

    %% field 5: item_priority
    item_priority_bits = (32:33)+1; % hex 0-9;A-F

    priorities = ['N','L','H','U']; % from 0 to 3
    item_priority = priorities(1+parsebin2dec(binary(item_priority_bits)));

    s18ccode(11) = item_priority;
    if DEBUG
        webcoder.console.log(sprintf('item_priority is: %s',char(item_priority)));
    end
    
    %% field 6: serial_number
    serial_number_bits = (34:49)+1;
    %3 characters
    %1: floor(D/5120) + 1
    %2: floor(mod(D,5120)/160)
    %3: floor(mod(D,160)/6)
    %4: mod(mod(D,160),6)
    serial_number = (parsebin2dec(binary(serial_number_bits)));
    serial_number_month = int32(floor(serial_number/5120) + 1);
    serial_number_day = int32(floor(mod(serial_number,5120)/160));
    serial_number_hour = int32(floor(mod(serial_number,160)/6));
    serial_number_10min = int32(mod(mod(serial_number,160),6));
    
    serial_number_formatted = sprintf('%02d%02d%02d%d',serial_number_month,serial_number_day,serial_number_hour,serial_number_10min);
    assert(all( size(serial_number_formatted) == [ 1, 7 ]))
    
    s18ccode(12:18) = serial_number_formatted;
    if DEBUG
        webcoder.console.log(sprintf('serial_number is: %02d%02d%02d%d',serial_number_month,serial_number_day,serial_number_hour,serial_number_10min));
    end

    %% field 7 (note: 18D not implemented)

    n = numel(binary)-1;
    serial_number_item_bits = ([(n-9):n])+1;
    serial_number_item = int32(parsebin2dec([binary(serial_number_item_bits)]));
    % TODO: remove err correction code before this point
% 142 = 1000 1110
% 143 = 1000 1111
    serial_number_item_formatted = sprintf('%05d',serial_number_item);
    assert(all( size(serial_number_item_formatted) == [ 1, 5 ]))
    
    s18ccode(19:23) = serial_number_item_formatted;
    if DEBUG
        webcoder.console.log(sprintf('serial_number_item is: %s',serial_number_item_formatted));
    end
    
    %% field 8
    tracking_indicator_bits = ([(n-11):(n-10)])+1; % hex 0-9;A-F

    tracking = ['T','F','D','N']; % from 0 to 3
    tracking_indicator = tracking(1+parsebin2dec(binary(tracking_indicator_bits)));
    
    s18ccode(24) = tracking_indicator;
    if DEBUG
        webcoder.console.log(sprintf('tracking is: %c',tracking_indicator));
    end
    
%     s18ccode = sprintf('%c%s%s%s%c%02d%02d%02d%d%05d%c',UPU_identifier,format_identifier,issuer_code,...
%         equipement_id,item_priority,serial_number_month,serial_number_day,serial_number_hour,...
%         serial_number_10min,serial_number_item,tracking_indicator);


    % Error correction
%     error_correction_bits = 50:124;
%     error_correction = binary(error_correction_bits);

     if DEBUG
        webcoder.console.log(sprintf('final code is: %s',s18ccode));
    end
    
    end % if error, skip the rest
    end
    end
    end
    %% return
    
    assert(isa(s18ccode, 'char'));
    assert(all( size(s18ccode) == [ 1, 24 ]))
    assert(isa(boundingbox, 'single'));
    assert(all( size(boundingbox) == [ 1, 4 ]))
    assert(isa(exitcode, 'int32'));
    assert(all( size(exitcode) == [ 1, 1 ]))
end
