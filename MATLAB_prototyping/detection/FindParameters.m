clear
clc
close all
load model.mat
for trainingSample = 1:100
    %% load data
    output = sprintf('data/synthetic/code%05d.jpg',trainingSample);
    outputgt = sprintf('data/synthetic/gt%05d.jpg',trainingSample);
    f = im2double(rgb2gray(imread(output)));
    figure(1), imshow(f), title('input frame');    
    imshow(f);

    %% preprocessing: eliminate regions without big white padding area
    candidatefilter_small = imresize(imresize(imresize(f,[400,400]),[200,200]),[100,100]);
    candidatefilter = imdilate(candidatefilter_small,ones(3));
    candidatefilter = candidatefilter.^3;
    candidatefilter = imfilter(candidatefilter,ones(3)/9);
%     candidatefilter = candidatefilter > graythresh(candidatefilter);
    f = f .* imresize(candidatefilter,size(f));
    imshow(f);
        
%         imshow(candidatefilter);
%         imshow(candidatefilter - candidatefilter_small,[])
%         
    %% extract features
    BLOCK_SIZE = 30;
    [B,O,theta] = extractBarCodeFeatures(f,BLOCK_SIZE);
    montage(B)
        
    %% analyse features using groundtruth: build a model
    gt = imread(outputgt)>0;
    isBarcodeBlock = blockproc(gt,[BLOCK_SIZE BLOCK_SIZE],@(x) max(x.data(:)));
    [bx,by] = size(isBarcodeBlock);
    B = reshape(B,size(B,1)*size(B,2),size(B,3));
    O = reshape(O,size(O,1)*size(O,2),size(O,3));
    lbl = reshape(isBarcodeBlock>0,[],1);
    
    %% classify
    score = B * M; % eval
    
    % valid = score > T;
    valid = score > prctile(score(:),93); % from optimization process
        
    % have the strongest 10 vote
    [~,direction] = max(O(valid,:),[],2);
    valid_scores = score(valid);
    [~,top] = sort(valid_scores,'descend');
    T_strongest_scores = valid_scores(top(10));
    consensus = mode(direction(valid_scores > T_strongest_scores)); % TODO: need to scan all promising angles (for multiple codes)
    valid(valid) = direction == consensus;
    
    O(valid(top),:)
    
    
    figure(3), plot(O(valid,:)'), title('oriented features for valid cells (high correlation expected)');
    
    %% analyse the result
    valid = reshape(valid,bx,by);
    valid_ = double(imresize(valid, size(f,[1 2]),'nearest'));
    score = reshape(score,bx,by);
% 
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
            fprintf('%d regions after initial detection.\n',numel(stats));
            if numel(stats) < MIN_BAR_CODES
                continue;
            end
            % eliminate things that aren't bars
            stats([stats.Eccentricity] < 0.8) = [];
            fprintf('%d regions after Eccentricity filtering.\n',numel(stats));
            % eliminate huge regions
            A = [stats.Area];
            regular_bar_size_estimate = median(A);
            stats(A > 2.5 * regular_bar_size_estimate | A < regular_bar_size_estimate / 4) = [];
            fprintf('%d regions after Area filtering.\n',numel(stats));
            % get centers
            centers = reshape([stats.Centroid],2,[]);
            % get orientation
            orientation = median([stats.Orientation]);
            
            rot = @(angle) [ cosd(angle), -sind(angle); sind(angle), cosd(angle)];
            rotated_centers = rot(90-orientation)' * centers;
            
            % keep only the ones closely related vertically
            med = median(rotated_centers(2,:));
            ditrib = abs(rotated_centers(2,:) - med);
%             tolerance = mean(ditrib) * 2.5;
            tolerance = std(ditrib(ditrib < mean(ditrib) * 2.5))*3;
            remove = ditrib > tolerance;
            stats(remove) = [];
            fprintf('%d regions after vertial grouping filter.\n',numel(stats));
            
            % remove the ones that are far left or far right
            rotated_centers = rot(90-orientation)' * reshape([stats.Centroid],2,[]);
            [pos,ids] = sort(rotated_centers(1,:));
            skip = min([abs(pos(1:end-1) - pos(2:end)) Inf],[Inf abs(pos(2:end) - pos(1:end-1))]);
            tolerance = mean(skip);
            remove = skip > (tolerance * 1.5);
            stats(ids(remove)) = [];
            fprintf('%d regions after horizontal grouping filter.\n',numel(stats));
            
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
            subplot(2,2,2);
            imshow(f < barthresh & valid_d_large)
            hold on
            scatter(centers(1,:),centers(2,:),'filled')
            hold off
            title(num2str(numel(stats)));
            subplot(2,2,4);
            imshow(f)
%             pause
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
    pause
%     assert(debugfound,'couldn''t locate code');

end