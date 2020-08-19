function [exitcode,s18ccode,boundingbox] = detectHD(frame) %#codegen
% frame = imresize(imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200817_175602.jpg'),[1920 1080]);
% frame = imresize(imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\test3.png'),[1920 1080]);
% frame = imrotate(frame,90);
% z = zeros(size(frame,[1 2]),'uint8');
% r = frame(:,:,1)';
% g = frame(:,:,2)';
% b = frame(:,:,3)';
% frame = [r(:)';g(:)';b(:)';z(:)'];
% frame = reshape(frame,[ 4, 1920, 1080 ]);
% 

    % check types and sizes
    assert(isa(frame, 'uint8'));
    assert(all( size(frame) == [ 4, 1080, 1920])); % frames comes in as RGBA packed row major
    r = reshape(frame(1:4:end),1920,1080)';
    g = reshape(frame(2:4:end),1920,1080)';
    b = reshape(frame(3:4:end),1920,1080)';
    frame_reshaped = cat(3,r,g,b);

    s18ccode = '000000000000000000000000';
    s18ccode = char(frame_reshaped(1:100:2400));
    exitcode = int32(0);

    %% Preprocessing
    f = im2single(frame_reshaped);
        
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
    
    %% Classify
    M = [    0.0527    1.5903    0.9982   -0.0369   -0.5392   -0.1954    0.1030    0.7808    2.9037   -0.8245   -1.3336   -1.5216    0.7569   -1.2331    0.1142   -0.4805    0.7901   -1.8255    1.6295   -2.3931   -0.4514   -0.0468   2.2480    0.8620   -1.4884   -1.3545   -0.4550   -0.5069    3.8599   -1.3284]';
    score = features * M; % eval
    score = reshape(score,grid_x,grid_y);
    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
    valid = score > prctile(score(:),96);

%     webcoder.console.log(sprintf('found %d good bar-like cells out of %d \n',int32(sum(valid(:))),int32(numel(valid))));    

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
%     webcoder.console.log(sprintf('found %d good connected regions\n',int32(n)));    
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
%         webcoder.console.log(sprintf('largest candidate has %d blocks.\n',int32(maxarea)));
        best_bar_code = CC == id;
    else
        best_bar_code = logical(CC);
    end

    %% Find bounding box, centroid, eccentricity and orientation
    scale = size(frame_reshaped,1) / size(valid_,1);
    [x,y] = ind2sub(size(best_bar_code),find(best_bar_code));
    centroid = [mean(x) mean(y)];
    x0 = (min(x)-1);
    x1 = (max(x));
    y0 = (min(y)-1);
    y1 = (max(y));
%     webcoder.console.log(sprintf('best boudingbox is %.1f,%.1f,%.1f,%.1f .\n',single(y0),single(x0),single(y1),single(x1)));
    boundingbox = (single([y0 x0 y1 x1] * scale));
    
%     [V,D] = eig(cov([x y] - centroid));
    [~,S,V] = svd([x y] - centroid);
    D = diag(S);

    eccentricity = 1 - (D(2) / D(1)); % how linear is this shape?
    orientation = 90+rad2deg(atan2(V(2),V(1)));
  
    if eccentricity < 0.80
        % it does not look like a bar! the length-width ratio is off
        exitcode = int32(-1);
        return;
    end

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
    rotated_bb = (rot(-orientation) * ([x y] - centroid)' + centroid');
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
    pts = scale * ((rot(orientation) * ([xx(:),yy(:)]')) + (centroid-1)');
    
%     figure(1), imshow(f)
%     hold on
%     scatter(pts(2,:),pts(1,:))
%     hold off
    
%     resamp = makeresampler('linear','fill');
    xx = imresize(reshape(pts(1,:),[H,W]),scale/2);
    yy = imresize(reshape(pts(2,:),[H,W]),scale/2);

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
    %% Refine ROI
    % find the top and the bottom
    vertical_profile = sum(imbar_score,2);
    T = mean(vertical_profile);
    peaks = find(vertical_profile > T);
    span = [peaks(1) peaks(end)];
    imbar_score = imbar_score(span(1):span(2),:);

    
    horizontal_profile = sum(imbar_score,1);
    T = mean(horizontal_profile);
    peaks = find(horizontal_profile > T);
    span = [peaks(1)-2 peaks(end)+2];
    imbar_score = imbar_score(:,span(1):span(2));
    
%     imbar_score = imdilate(imbar_score,true(1,3));
    imbar_score_dilate = zeros(size(imbar_score));
    imbar_score_dilate(:,[1 end]) = imbar_score(:,[1 end]);
    for i = 1:size(imbar_score_dilate,1)
        for j = 2:size(imbar_score_dilate,2)-1
            imbar_score_dilate(i,j) = max(imbar_score(i,j-1:j+1));
        end
    end

% imshow(imbar_score_dilate,[])

    [H,~] = size(imbar_score_dilate);
    t0 = round(H/3);
    t1 = round(2*H/3);
    
    row0_profile = mean(imbar_score_dilate(1:t0,:));
    row1_profile = mean(imbar_score_dilate(t0+1:t1,:));
    row2_profile = mean(imbar_score_dilate(t1:end,:));

%     plot([row0_profile;row1_profile;row2_profile]')

    %% Extract Binary String
    H = hist(row1_profile,0:0.01:1);
    thresh = otsuthresh(H);

    T = row0_profile > thresh; % top
    C = row1_profile > thresh; % center
    B = row2_profile > thresh; % bottom

    [cc,n] = bwlabel(C);
    if n ~= 75
        exitcode = int32(-2);
        return;
    end

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
        return;
    end

    T = T(sampling_centroid);
    B = B(sampling_centroid);

    %% Parse binary string
    % top,bottom bits values: 00, 01, 10, 11 where 1 is white
    codes = ['T','D','A','F'];
    code_ = codes(1+T * 2 + B);
    % check orientation
    left_sync = code_(7:9);
    right_sync = code_(numel(code_)-8:numel(code_)-6);
    flipped = false;
    if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
        % if the sync codes are wrong, the code may be flipped
        codes = ['T','A','D','F'];
        code_ = codes(1+T(end:-1:1) * 2 + B(end:-1:1));
        left_sync = code_(7:9);
        right_sync = code_(numel(code_)-8:numel(code_)-6);
        if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
            % error: code was misread because the sync codes are wrong
        end
    end
    % crop out sync codes, copy the rest to a new buffer
    valid = true(1,numel(code_));
    valid([7:9 numel(code_)-8:numel(code_)-6]) = false;
    code = code_(valid);

    % crop out ECC TODO: solomon reed correction
    % ecc = code(59:70);
    % code(59:70) = [];

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

    % +1 for MATLAB 1 based indexing
    parsebin2dec = @(bin) bin2dec(char(uint8(bin)+48));

    %% field 1: UPU identifier
    UPU_identifier = 'J'; % always J

    %% field 2: format
    % TODO: error detection, only [1 4] possible
    format_identifier_bits = (0:3)+1;
    format_identifier_id = parsebin2dec(binary(format_identifier_bits));
    if format_identifier_id ~= 2
        exitcode = int32(-4);
        return;
    end
    
    format_identifiers = {'18A','18B','18C','18D'};
    format_identifier = format_identifiers{format_identifier_id+1};

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


    %% field 4: equipement_id
    hex_table1 = '0123456789ABCDEF';
    equipement_id_bits_1 = (20:23)+1; % hex 0-9;A-F
    equipement_id_bits_2 = (24:27)+1;
    equipement_id_bits_3 = (28:31)+1;

    equipement_id_1 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_1)));
    equipement_id_2 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_2)));
    equipement_id_3 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_3)));

    equipement_id = [equipement_id_1, equipement_id_2, equipement_id_3];

    %% field 5: item_priority
    item_priority_bits = (32:33)+1; % hex 0-9;A-F

    priorities = ['N','L','H','U']; % from 0 to 3
    item_priority = priorities(1+parsebin2dec(binary(item_priority_bits)));

    %% field 6: serial_number
    serial_number_bits = (34:49)+1;
    %3 characters
    %1: floor(D/5120) + 1
    %2: floor(mod(D,5120)/160)
    %3: floor(mod(D,160)/6)
    %4: mod(mod(D,160),6)
    serial_number = int32(parsebin2dec(binary(serial_number_bits)));
    serial_number_month = floor(serial_number/5120) + 1;
    serial_number_day = floor(mod(serial_number,5120)/160);
    serial_number_hour = floor(mod(serial_number,160)/6);
    serial_number_10min = mod(mod(serial_number,160),6);
    %serial_number = [serial_number_month serial_number_day serial_number_hour serial_number_10min];


    %% field 7 (TODO: 18D not implemented)
    % i'm supposed to crop out ECC i think, serial is at the end
    n = numel(binary)-1;
    serial_number_item_bits = ([50:54 (n-8):n])+1;
    serial_number_item = int32(parsebin2dec(binary(serial_number_item_bits)));
    % TODOHACK: this code is sketchy as best.

    %% field 8
    tracking_indicator_bits = (135:136)+1; % hex 0-9;A-F

    tracking = ['T','F','D','N']; % from 0 to 3
    tracking_indicator = tracking(1+parsebin2dec(binary(tracking_indicator_bits)));

    s18ccode = sprintf('%c%s%s%s%c%02d%02d%02d%d%05d%c',UPU_identifier,format_identifier,issuer_code,...
        equipement_id,item_priority,serial_number_month,serial_number_day,serial_number_hour,...
        serial_number_10min,serial_number_item,tracking_indicator);

    %% return
    
    assert(isa(s18ccode, 'char'));
    assert(all( size(s18ccode) == [ 1, 24 ]))
    assert(isa(boundingbox, 'single'));
    assert(all( size(boundingbox) == [ 1, 4 ]))
    assert(isa(exitcode, 'int32'));
    assert(all( size(exitcode) == [ 1, 1 ]))
end
