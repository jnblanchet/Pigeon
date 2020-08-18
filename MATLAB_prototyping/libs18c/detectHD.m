function [s18ccode,boundingbox] = detectHD(frame) %#codegen
% frame = imresize(imread('C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real2\IMG_20200817_175602.jpg'),[1920 1080]);
% frame = imrotate(frame,90);
% z = zeros(size(frame,[1 2]),'uint8');
% r = frame(:,:,1)';
% g = frame(:,:,2)';
% b = frame(:,:,3)';
% frame = [r(:)';g(:)';b(:)';z(:)'];
% frame = reshape(frame,[ 4, 1920, 1080 ]);

    %DETECT Locates, reads and parses an S18C code from 
    % Specify the Dimensions and Data Types
    % define some regionprops info for compilation
    coder.extrinsic('regionprops');
    
    % check types and sizes
    assert(isa(frame, 'uint8'));
    assert(all( size(frame) == [ 4, 1080, 1920])); % frames comes in as RGBA packed row major
    r = reshape(frame(1:4:end),1920,1080)';
    g = reshape(frame(2:4:end),1920,1080)';
    b = reshape(frame(3:4:end),1920,1080)';
    frame_reshaped = cat(3,r,g,b);
    
%     assert(isa(gx_buff, 'single'));
%     assert(all( size(gx_buff) == [ 1080, 1920 ]))
%     
%     assert(isa(gy_buff, 'single'));
%     assert(all( size(gy_buff) == [ 1080, 1920 ]))
%     
%     assert(isa(phase_buff, 'single'));
%     assert(all( size(phase_buff) == [ 1080, 1920 ]))
%     
%     assert(isa(mag_buff, 'single'));
%     assert(all( size(mag_buff) == [ 1080, 1920 ]))

    s18ccode = '000000000000000000000000';
    s18ccode = char(frame_reshaped(1:100:2400));
%     boundingbox = zeros(1,4,'single');
%     errorcode = 0;
    %% tmp: load data
%     framein = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\trainning2\code00060.jpg';
%     frame = imread(framein);
%     imshow(frame)
    %% preprocessing
    f = im2single(frame_reshaped);
        
%% feature extraction
    BLOCK_SIZE = 5;
    SCALE_FACT = 4;

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

    % accumulate histogram (in a c friendly way)
    N_BINS_P1 = 6;
    N_BINS_P2 = 6;
    N_BINS = N_BINS_P1 * N_BINS_P2;
    grid_x = floor(size(f_small,1) / BLOCK_SIZE);
    grid_y = floor(size(f_small,2) / BLOCK_SIZE);
    hist = zeros(grid_x,grid_y,N_BINS,'single');
    for cell_x = 0:grid_x-1
        for cell_y = 0:grid_y-1
            for px_x = cell_x * BLOCK_SIZE:(cell_x+1) * BLOCK_SIZE - 1
                for px_y = cell_y * BLOCK_SIZE:(cell_y+1) * BLOCK_SIZE - 1
                    % gx
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,1)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,2)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    if b >= 0 && b < N_BINS
                        hist(cell_x+1,cell_y+1,b+1) = hist(cell_x+1,cell_y+1,b+1) + 1;
                    end
                    % repeat for gy
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,3)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,4)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    if b >= 0 && b < N_BINS
                        hist(cell_x+1,cell_y+1,b+1) = hist(cell_x+1,cell_y+1,b+1) + 1;
                    end
                end
            end
        end
    end
    
    % normalize
    maxbin = 30;
    hist = hist(:,:,1:maxbin);
    hist = hist / (2*BLOCK_SIZE*BLOCK_SIZE);
    hist = reshape(hist,size(hist,1)*size(hist,2),size(hist,3));
    
    %% Classify
    M = [    0.0527    1.5903    0.9982   -0.0369   -0.5392   -0.1954    0.1030    0.7808    2.9037   -0.8245   -1.3336   -1.5216    0.7569   -1.2331    0.1142   -0.4805    0.7901   -1.8255    1.6295   -2.3931   -0.4514   -0.0468   2.2480    0.8620   -1.4884   -1.3545   -0.4550   -0.5069    3.8599   -1.3284]';
    score = hist * M; % eval
    score = reshape(score,grid_x,grid_y);
    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
    valid = score > prctile(score(:),96);

    webcoder.console.log(sprintf('found %d good bar-like cells out of %d \n',int32(sum(valid(:))),int32(numel(valid))));    

    %% quick dilation to connect barcode cell fragments
    
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
    
    %% find barcode candidates regions       
    [CC,n] = bwlabel(valid_);
    webcoder.console.log(sprintf('found %d good connected regions\n',int32(n)));    
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
        webcoder.console.log(sprintf('largest candidate has %d blocks.\n',int32(maxarea)));
        best_bar_code = CC == id;
    else
        best_bar_code = logical(CC);
    end

    % find bounding box
    scale = size(frame_reshaped,1) / size(valid_,1);
    [x,y] = ind2sub(size(best_bar_code),find(best_bar_code));
    x0 = (min(x)-1) * scale;
    x1 = (max(x)) * scale;
    y0 = (min(y)-1) * scale;
    y1 = (max(y)) * scale;
    webcoder.console.log(sprintf('best boudingbox is %.1f,%.1f,%.1f,%.1f .\n',single(y0),single(x0),single(y1),single(x1)));
    boundingbox = (single([y0 x0 y1 x1]));

%     MIN_AREA_EXPECTED = uint32(0.04 * numel(valid_)); % 4% of area of frame

        
%     
%         stats = struct('Area',0,'BoundingBox',0);
%     stats = regionprops(valid_,'Area','BoundingBox');
%     [largest_area, largest_id] = max([stats.Area]);
%     
%     if largest_area < MIN_AREA_EXPECTED
%         %too small
%     end
%     
%     largest = stats(largest_id);
%     scale = size(f,1) / size(valid_,1);
%     boundingbox = (single(largest.BoundingBox([2 1 4 3])) - [1 1 0 0]) .* scale;

    

%     
%     %% analyse each barcode candidate region
%     MIN_BAR_CODES = 50; % if fewer individual bars are detected, abandon search
%     
%     for i = 1:n
%         if barcode_candidate_area(i) < MIN_AREA_EXPECTED
%             continue;
%         end
%             %focus on that region (crop it out)
%             ROI = CC == i;
%             [x,y] = ind2sub(size(ROI),find(ROI));
%             x0 = min(x)-1;
%             x1 = max(x);
%             y0 = min(y)-1;
%             y1 = max(y);
%             
%             f_ROI = f(x0*BLOCK_SIZE+1:x1*BLOCK_SIZE,y0*BLOCK_SIZE+1:y1*BLOCK_SIZE);
%             mask_ROI = imresize(~ROI(x0:x1,y0:y1),size(f_ROI),'nearest');
%                        
%             H = hist(f_ROI(~mask_ROI),0:255);
%             T = otsuthresh(H)*255;
%             barcandidates = f_ROI < T & ~mask_ROI;
%             
%             % find bars            
%             stats = struct('Area',0,'Centroid',0,'Eccentricity',0,'Orientation',0,'PixelIdxList', 0);
%             stats = regionprops(barcandidates,'Area','Centroid','Eccentricity','Orientation','PixelIdxList');
%             if length(stats) < MIN_BAR_CODES
%                 continue;
%             end
%             % eliminate things that aren't bars
%             stats([stats.Eccentricity] < 0.8) = [];
%             % eliminate huge regions
%             A = [stats.Area];
%             regular_bar_size_estimate = median(A);
%             stats(A > 2.5 * regular_bar_size_estimate | A < regular_bar_size_estimate / 4) = [];
%             % get centers & orientations, rotate code
%             centers = reshape([stats.Centroid],2,[]);
%             orientation = median([stats.Orientation]);
%             rot = @(angle) [ cosd(angle), -sind(angle); sind(angle), cosd(angle)];
%             rotated_centers = rot(90-orientation)' * centers;
%             % keep only the ones closely related vertically
%             med = median(rotated_centers(2,:));
%             ditrib = abs(rotated_centers(2,:) - med);
%             tolerance = std(ditrib(ditrib < mean(ditrib) * 2.5))*3;
%             remove = ditrib > tolerance;
%             stats(remove) = [];
%             
%             % remove the ones that are far left or far right
%             rotated_centers = rot(90-orientation)' * reshape([stats.Centroid],2,[]);
%             [pos,ids] = sort(rotated_centers(1,:));
%             skip = min([abs(pos(1:end-1) - pos(2:end)) Inf],[Inf abs(pos(2:end) - pos(1:end-1))]);
%             tolerance = mean(skip);
%             tolerance_range = std(skip);
%             remove = (skip - tolerance) > 4 * tolerance_range;
%             stats(ids(remove)) = [];
%             
%             % find first and last bars
%             first_bar_id = ids(1);
%             last_bar_id = ids(end);
%             x0 = round(centers(1,first_bar_id)); % small padding 
%             x1 = round(centers(1,last_bar_id)); % TODO: check bounds
%             y0 = round(centers(2,first_bar_id));
%             y1 = round(centers(2,last_bar_id));
%             span = norm([x0 y0] - [x1 y1]);
%             BARCODE_SAMPLING_SIZE = [55, 2] * span / 55; % this ratio is constant for S18C
%             
%             [xx,yy] = meshgrid(0:1/(BARCODE_SAMPLING_SIZE(1)-1):1,-0.5:1/(BARCODE_SAMPLING_SIZE(2)-1):0.5);
%             translation_vector = rot(-90) * [(x1-x0); (y1-y0)];
%             translation_vector = translation_vector / BARCODE_SAMPLING_SIZE(1) * BARCODE_SAMPLING_SIZE(2) / 2;
% 
%             x_span = linspace(x0,x1,BARCODE_SAMPLING_SIZE(1));
%             y_span = linspace(y0,y1,BARCODE_SAMPLING_SIZE(1));
%             row0 = [x_span;y_span] + translation_vector;
%             row1 = [x_span;y_span];   
%             row2 = [x_span;y_span] - translation_vector;
%             
%             [xx,yy] = meshgrid(1:size(f_ROI,2),1:size(f_ROI,1));
%             row0_profile = interp2(xx,yy,f_ROI,row0(1,:),row0(2,:));
%             row1_profile = interp2(xx,yy,f_ROI,row1(1,:),row1(2,:));
%             row2_profile = interp2(xx,yy,f_ROI,row2(1,:),row2(2,:));
%            
%             figure(1)
%             imshow(f_ROI,[])
%             hold on
% %             scatter(x0,y0)
% %             scatter(x1,y1)
%             scatter(row0(1,:),row0(2,:))
%             scatter(row1(1,:),row1(2,:))
%             scatter(row2(1,:),row2(2,:))
%             hold off
% 
%             % parsing binary
%             H = hist(row1_profile,0:255);
%             thresh = otsuthresh(H)*255;
%                        
%             T = row0_profile < thresh;
%             C = row1_profile < thresh;
%             B = row2_profile < thresh;
%             
%             % TODO: check bar count
%             binary_bar_stats = struct('Centroid',0);
%             binary_bar_stats = regionprops(C,'Centroid');
%             sample_coord_xy = [binary_bar_stats.Centroid];
%             sample_coord = round(sample_coord_xy(1:2:end));
% %             figure(2)
% %             imshow(f,[]);
% %             hold on 
% %             scatter(sample_coord,20*ones(size(sample_coord)),'filled')
% %             hold off
% %             sample_coord = round(sample_coord);
% 
% %             jump = abs(sample_coord(1:end-1) - sample_coord(2:end));
% %             assert(sum(abs(jump - mean(jump)) > (std(jump)*2.5)) == 0, 'there seems to be at least on bar missing');
% 
%             % top,bottom bits values: 00, 01, 10, 11 where 1 is white
%             codes = ['T','D','A','F'];
%             code = codes(1+T(sample_coord) * 2 + B(sample_coord));
%             % check orientation
%             left_sync = code(7:9);
%             right_sync = code(numel(code)-8:numel(code)-6);
%             flipped = false;
%             if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
%                 % if the sync codes are wrong, the code may be flipped
%                 codes = ['T','A','D','F'];
%                 code = codes(1+T(sample_coord(end:-1:1)) * 2 + B(sample_coord(end:-1:1)));
%                 left_sync = code(7:9);
%                 right_sync = code(numel(code)-8:numel(code)-6);
%                 if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
%                     % error: code was misread because the sync codes are wrong
%                 end
%             end
%             % crop out sync codes
%             code([7:9 numel(code)-8:numel(code)-6]) = [];
%             % crop out ECC TODO: solomon reed correction
%             % ecc = code(59:70);
%             % code(59:70) = [];
% 
%             % TODO: convert from code above.
%             if ~flipped
%                 binary = ~[T(sample_coord);B(sample_coord)];
%                 % crop out sync codes and ECC (like above, but on binary this time)
%                 binary(:,[7:9 numel(code)-8:numel(code)-6]) = [];
%                 % binary(:,[59:70]) = [];
%                 binary = binary(:)';
%             else
%                 binary = ~[B(sample_coord(end:-1:1));T(sample_coord(end:-1:1))];
%                 % crop out sync codes and ECC (like above, but on binary this time)
%                 binary(:,[7:9 numel(code)-8:numel(code)-6]) = [];
%                 % binary(:,[59:70]) = [];
%                 binary = binary(:)';
%             end
% 
%             % +1 for MATLAB 1 based indexing
%             parsebin2dec = @(bin) bin2dec(char(uint8(bin)+48));
% 
%             %% field 1
%             UPU_identifier = 'J'; % always J
% 
%             %% field 2
%             format_identifier_bits = (0:3)+1;
%             format_identifier_id = parsebin2dec(binary(format_identifier_bits));
%             format_identifiers = {'18A','18B','18C','18D'};
%             format_identifier = format_identifiers{format_identifier_id+1};
% 
%             %% field 3
%             issuer_code_bits = (4:19)+1;
%             %3 characters
%             %1: S18 table 1, INT(I/1600)
%             %2: INT(MOD(I,1600)/40_ S18a, table 1
%             %3: MOD(I,40)
% 
% 
%             alphabet_table1 = 'ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210';
%             issuer_code_id = parsebin2dec(binary(issuer_code_bits));
%             % issuer_code_id = 16003;
%             % issuer_code_id = parsebin2dec([0 0 1 0 0 0 0 0 0 1 1 1 0 0 0 1]);
%             % pzw
%             issuer_code_id_1 = floor((issuer_code_id) / 1600);
%             issuer_code_1 = alphabet_table1(issuer_code_id_1+1);
% 
%             issuer_code_id_2 = floor(mod((issuer_code_id),1600)/40);
%             issuer_code_2 = alphabet_table1(issuer_code_id_2+1);
% 
%             issuer_code_id_3 = floor(mod((issuer_code_id),40));
%             issuer_code_3 = alphabet_table1(issuer_code_id_3+1);
% 
%             issuer_code = [issuer_code_1, issuer_code_2, issuer_code_3];
% 
% 
%             %% field 4
%             hex_table1 = '0123456789ABCDEF';
%             equipement_id_bits_1 = (20:23)+1; % hex 0-9;A-F
%             equipement_id_bits_2 = (24:27)+1;
%             equipement_id_bits_3 = (28:31)+1;
% 
%             equipement_id_1 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_1)));
%             equipement_id_2 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_2)));
%             equipement_id_3 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_3)));
% 
%             equipement_id = [equipement_id_1, equipement_id_2, equipement_id_3];
% 
%             %% field 5
%             item_priority_bits = (32:33)+1; % hex 0-9;A-F
% 
%             priorities = ['N','L','H','U']; % from 0 to 3
%             item_priority = priorities(1+parsebin2dec(binary(item_priority_bits)));
% 
%             %% field 6
%             serial_number_bits = (34:49)+1;
%             %3 characters
%             %1: floor(D/5120) + 1
%             %2: floor(mod(D,5120)/160)
%             %3: floor(mod(D,160)/6)
%             %4: mod(mod(D,160),6)
%             serial_number = parsebin2dec(binary(serial_number_bits));
%             serial_number_month = floor(serial_number/5120) + 1;
%             serial_number_day = floor(mod(serial_number,5120)/160);
%             serial_number_hour = floor(mod(serial_number,160)/6);
%             serial_number_10min = mod(mod(serial_number,160),6);
%             serial_number = [serial_number_month serial_number_day serial_number_hour serial_number_10min];
% 
% 
%             %% field 7 (TODO: 18D not implemented)
%             % i'm supposed to crop out ECC i think, serial is at the end
%             n = numel(binary)-1;
%             serial_number_item_bits = ([50:54 (n-8):n])+1;
%             serial_number_item = parsebin2dec(binary(serial_number_item_bits));
%             % TODOHACK: this code is sketchy as best.
% 
%             %% field 8
%             tracking_indicator_bits = (50:51)+1; % hex 0-9;A-F
% 
%             tracking = ['T','F','D','N']; % from 0 to 3
%             tracking_indicator = tracking(1+parsebin2dec(binary(item_priority_bits)));
% 
% 
% %             fprintf('%s\n',code_og);
%             s18ccode = sprintf('%c%s%s%s%c%02d%02d%02d%d%05d%c',UPU_identifier,format_identifier,issuer_code,...
%                 equipement_id,item_priority,serial_number_month,serial_number_day,serial_number_hour,...
%                 serial_number_10min,serial_number_item,tracking_indicator);
%             
%             % if found, we can return!
%             break;
%     end
    %% debug show
%     figure, imshow(imresize(reshape(valid,grid_x,grid_y),4,'nearest')), title('possible barcode cells')
    
%     errorcode = int32(sum(valid(:)));

    assert(isa(s18ccode, 'char'));
    assert(all( size(s18ccode) == [ 1, 24 ]))
    assert(isa(boundingbox, 'single'));
    assert(all( size(boundingbox) == [ 1, 4 ]))
    
    
    
%     assert(isa(errorcode, 'int32'));
%     assert(all( size(errorcode) == [ 1, 1 ]))
    
%     assert(isa(heatmap, 'single'));
%     assert(all( size(heatmap) == (floor(size(f,[1 2]) / (BLOCK_SIZE * SCALE_FACT)))))
end
