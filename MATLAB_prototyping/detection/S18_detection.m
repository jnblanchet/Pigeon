clear
clc
close all
%% loop through rotations to model several scenarios
X = [];
lbl = [];
for angle = -90 : 2.5 : 90
    %% load data
    random_scale_factor = (rand(1)+0.5).^3;
    f = im2double(rgb2gray(imread('test2.png')));
    f = imresize(f,random_scale_factor);
    f = imrotate(f,angle,'nearest','loose');
    figure(1), imshow(f), title('input frame');
    imshow(f);
    
    %% extract features
    BLOCK_SIZE = 30;
    B = extractBarCodeFeatures(f,BLOCK_SIZE);
    montage(B)
    
    %% analyse features using groundtruth: build a model
    gt = imread('test2_gt.png');
    gt = imresize(gt,random_scale_factor,'nearest');
    gt = imrotate(gt,angle,'nearest','loose');
    isBarcodeBlock = blockproc(gt,[BLOCK_SIZE BLOCK_SIZE],@(x) max(x.data(:)));
    X = [X;reshape(B,size(B,1)*size(B,2),size(B,3))];
    lbl = [lbl;reshape(isBarcodeBlock>0,[],1)];
end
% is linear regression enough?
M = X \ lbl;
score = X * M; % eval
% imshow(reshape(score,size(B,1),size(B,2)),[])
% x = 0:0.01:1;
x = 0:0.01:1;
figure(2)
clf
h1 = histogram(score(logical(lbl)),x);
x_ = h1.BinEdges(1:end-1) - (h1.BinEdges(2) - h1.BinEdges(1))/2;
h1 = h1.Values / sum(h1.Values);
h2 = histogram(score(~logical(lbl)),x);
h2 = h2.Values / sum(h2.Values);
plot(x_, h1);
hold on
plot(x_, h2);
hold off
T = 0.15;


%% generalize on new data
% S = 0;
for angle = -90 : 1 : 90
    random_scale_factor = (rand(1)+0.75).^2;
    f = imresize(im2double(rgb2gray(imread('test3.png'))),random_scale_factor);
    f = imrotate(f,angle,'nearest','loose');
    figure(1), imshow(f), title(['input frame ' num2str(size(f,2)) ' x ' num2str(size(f,1))]);
    
    %load gt for debug
    gt = rgb2gray(imread('test3_gt.png'));
    gt = imresize(gt,random_scale_factor,'nearest');
    gt = imrotate(gt,angle,'nearest','loose');
    isBarcodeBlock = logical(blockproc(gt,[BLOCK_SIZE BLOCK_SIZE],@(x) max(x.data(:))));

    
    %% extract featuress
    [B,O,theta,mag] = extractBarCodeFeatures(f,BLOCK_SIZE);
    [bx,by,~] = size(B);
    figure(2), montage(B), title('features');
    B = reshape(B,size(B,1)*size(B,2),size(B,3));
    O = reshape(O,size(O,1)*size(O,2),size(O,3));
    
    
    %% classify
    score = B * M; % eval
    
    % propagate scores spatially
    score = reshape(score,bx,by);
    score = imdilate(score,ones(3)) + score;
    imshow(score,[])
    score = score
    
    %     valid = score > T;
    valid = score > prctile(score(:),93); % from optimization process

%% optimize threshold
%     f1 = [];
%     PERCTS = 80:0.25:99;
%     for PERC = PERCTS
%     score = B * M; % eval
% %     valid = score > T;
%     valid = score > prctile(score(:),PERC); % adaptive?
%     assert(sum(valid(:)) > 10, 'threshold found no possible code in this frame');
%     
%     tp = isBarcodeBlock(:) & valid;
%     precision = sum(tp) ./ sum(isBarcodeBlock(:));
%     recall = sum(tp) ./ sum(valid);
%     f1(end+1) = 2 / (1/precision + 1/recall);
%     end
%     plot(f1)
%     [~,tmp] = max(f1);
%     title(['best rank is r' num2str(PERCTS(tmp))])
% %     pause
% 
%     end
%     S = S + f1;
%     end

%         plot(S)
%     [~,tmp] = max(S);
%     title(['best rank is r' num2str(PERCTS(tmp))])
    
    
    % remove outliers using orientation
    % centroid = mean(O(valid,:));
    % weights = score(valid);
    % centroid = sum(O(valid,:) .* weights) / sum(weights);
    % valid(valid) = (vecnorm(O(valid,:) - centroid,2,2)) < 0.25;
    
    % [~,direction] = max(O(valid,:),[],2);
    % consensus = mode(direction);
    % valid(valid) = direction == consensus;
    
    % have the strongest 10 vote
    [~,direction] = max(O(valid,:),[],2);
    valid_scores = score(valid);
    [~,top] = sort(valid_scores,'descend');
    T_strongest_scores = valid_scores(top(10));
    consensus = mode(direction(valid_scores > T_strongest_scores));
    valid(valid) = direction == consensus;
    
    O(valid(top),:)
    
    
    figure(3), plot(O(valid,:)'), title('oriented features for valid cells (high correlation expected)');
    
    %% analyse the result
    valid = reshape(valid,bx,by);
    valid_ = double(imresize(valid, size(f,[1 2]),'nearest'));
    score = reshape(score,bx,by);

%     figure(3)
%     
%     subplot(2,2,1)
%     imshow(f)
%     % colorbar
%     title('gt')
%     
%     subplot(2,2,2)
%     imshow(valid_ .* f)
%     title('valid mask')
%     
%     subplot(2,2,3)
%     imshow(score,[])
%     title('score')
%     colorbar
    
    %% let's try to filter the results a little bit
    MIN_BAR_CODES = 57; % if less, don't bother
    DILATION_SIZE = floor(2 + numel(valid) / 500); % larger for larger images
    valid_d = imdilate(valid,true(DILATION_SIZE));
    figure(4), imshow(valid_d), title('possible regions of interest');

    MIN_AREA_EXPECTED = 0.04 * numel(valid_d); % 4% of area of frame
    % hold on
    barcodeCandidatesRegions = regionprops(valid_d,'area','Extrema','PixelIdxList');
    
    debugfound = false;
    for id = 1:numel(barcodeCandidatesRegions)
        if barcodeCandidatesRegions(id).Area > MIN_AREA_EXPECTED
            %focus on that region
            valid_d(:) = false;
            valid_d(barcodeCandidatesRegions(id).PixelIdxList) = true;
            valid_d_large = imresize(valid_d,size(theta),'nearest');
            
            barthresh = graythresh(f(valid_d_large));
            barcandidates = f < barthresh & valid_d_large;
            
            % find bars
            stats = regionprops(barcandidates,'Centroid','Orientation','Area','Eccentricity','PixelIdxList');
            if numel(stats) < MIN_BAR_CODES
                continue;
            end
            % eliminate huge regions
            A = [stats.Area];
            regular_bar_size_estimate = median(A);
            stats(A > 2 * regular_bar_size_estimate | A < regular_bar_size_estimate / 4) = [];
            % eliminate things that aren't bars
            stats([stats.Eccentricity] < 0.8) = [];
            % get centers
            centers = reshape([stats.Centroid],2,[]);
            % get orientation
            orientation = median([stats.Orientation]);
            
            rot = @(angle) [ cosd(angle), -sind(angle); sind(angle), cosd(angle)];
            rotated_centers = rot(90-orientation)' * centers;
            
            % keep only the ones closely related vertically
            med = median(rotated_centers(2,:));
            ditrib = abs(rotated_centers(2,:) - med);
            tolerance = mean(ditrib);
            remove = ditrib > tolerance * 2;
            stats(remove) = [];
            
            % remove the ones that are far left or far right
            rotated_centers = rot(90-orientation)' * reshape([stats.Centroid],2,[]);
            [pos,ids] = sort(rotated_centers(1,:));
            skip = min([abs(pos(1:end-1) - pos(2:end)) Inf],[Inf abs(pos(2:end) - pos(1:end-1))]);
            tolerance = mean(skip);
            remove = skip > (tolerance * 1.5);
            stats(ids(remove)) = [];
            
            if numel(stats) <= 40% this is for debug only, find codes that are "kind of" well detected
                continue;
            end
            
            %     assert(numel(stats) == 57 || numel(stats) == 75,'did not filter out junk properly');
            
            % make sure we're good so far
            figure(5)
            centers = reshape([stats.Centroid],2,[]); % for display only
            rotated_centers = rot(90-orientation)' * centers;
            subplot(1,2,1);
            scatter(rotated_centers(1,:),rotated_centers(2,:))
            axis('equal')
            title('if there are still outliers at this point, we need to filter horizontally');
            subplot(1,2,2);
            imshow(f < barthresh & valid_d_large)
            hold on
            scatter(centers(1,:),centers(2,:),'filled')
            hold off
            title(num2str(numel(stats)));
            pause
            debugfound = true;
            
            % i think the best way to go here is to try to find the small bars
            % directly, and to read it
            
            
            %     valid_thetas = theta(valid_d_large);
            %     valid_thetas = valid_thetas(mag(valid_d_large) > 2.0);
            %
            %     recovered= rad2deg(atan(median(cos(valid_thetas)) ./ median(sin(valid_thetas))));
            %
            %     [row,col] = ind2sub(size(valid_d),find(valid_d));
            %     [V,D] = eig(cov([row,col]));
            %     xy_ = [row,col] * V;
            %     [~,minimums] = min(xy_);
            %     [~,maximums] = max(xy_);
            %     x0 = row(minimums(1));
            %     y0 = col(minimums(2));
            %     x1 = row(maximums(1));
            %     y1 = col(maximums(2));
            %
            %     bb = [  x0, y0;
            %             x0, y1;
            %             x1, y1;
            %             x1, y0;
            %             x0, y0;
            %     ];
            %     imshow(valid_d)
            %     hold on
            %     line(bb(:,2),bb(:,1))
            %     hold off
            
            %     bb = stats(largest_id).Extrema;
            %     bb = bb([1:2:end],:);
            %     bb(end+1,:) = bb(1,:);%loop
            %     bb = bb * BLOCK_SIZE;
            %     hold on
            %     line(bb(:,1),bb(:,2))
            
        end
        % pause
    end
    assert(debugfound,'couldn''t locate code');

end