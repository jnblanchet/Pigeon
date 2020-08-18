clear
clc
close all
load model.mat 

% load reallbl.mat
% gtstruct = table2cell(gTruth.LabelData);% realdata
path = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real\';
% path = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real_diffcam\';
% path = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\dark1\';

images = dir([path '*.jpg']);

for trainingSample = 1:numel(images)
    %% load data
    output = sprintf('data/real/code%05d.jpg',trainingSample);
    output = [path filesep images(trainingSample).name];
    f = im2double(imread(output));         
    %% extract features
    BLOCK_SIZE = 5;
    SCALE_FACT = 4;
    [H,bx,by] = extractBarCodeFeatures(f,BLOCK_SIZE,SCALE_FACT);
    H = reshape(H,size(H,1)*size(H,2),size(H,3));
    
    %% classify
    score = H * M; % eval
    score = reshape(score,bx,by);
    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
    valid = score > prctile(score(:),99);
    
    
    %% crop
    [R,xp] = radon(valid); % where 1 col = 1 deg from 0 to 179

    [peak,bestid] = max(R(:));
    [x,code_orientation] = ind2sub(size(R),bestid);
    offset = xp(x);
    orientation = code_orientation - 1; % because 0 to 179
    
    A = [ % TODO: handle borders
        (offset-3:offset+3).^2
        offset-3:offset+3
        ones(1,7)
        ]';
    b = R(x-3:x+3,code_orientation);
    sol=A\b;
    bounds=roots(sol);
    if bounds(2) < bounds(1)
        bounds = [bounds(2) bounds(1)];
    end

    % extract band
    scale = size(f,1) / size(valid,1);
    rot = @(angle) [cosd(angle), -sind(angle); sind(angle), cosd(angle)];
        
    W = numel(xp);
    H = ceil(bounds(2) - bounds(1) + 3);
    [yy,xx] = meshgrid(-W/2:W/2-1, -H/2:H/2-1);

    center = size(valid,[2 1])/2;
    pts = (rot(orientation)' * ([xx(:),yy(:)]' + [offset;0])) + center';
    
    % TODO, restrict crop to px in image
    resamp = makeresampler('linear','fill');
    xx = imresize(reshape(pts(1,:),[H,W]) * scale,scale/4);
    yy = imresize(reshape(pts(2,:),[H,W]) * scale,scale/4);
    
    Hcrop = xx(1,:) > 0 & xx(1,:) < size(f,2) & yy(1,:) > 0 & yy(1,:) < size(f,1);
    if sum(Hcrop) == 0
        warning('no barcode candidate found on this frame');
        continue;
    end
    xx = xx(:,Hcrop);
    yy = yy(:,Hcrop);

    tmap_B = cat(3,xx,yy);
    imbar = tformarray(f,[],resamp,[2 1],[1 2],[],tmap_B+1,0);
    balance = mean(imbar,[1 2]);
    balance = balance ./ mean(balance);
    imbar = imbar ./ balance;
    
    %% Re-run pipeline at a higher resolution
%     BLOCK_SIZE = 10;
%     SCALE_FACT = 1;
%     [H,bx,by] = extractBarCodeFeatures(imbar,BLOCK_SIZE,SCALE_FACT);
%     H = reshape(H,size(H,1)*size(H,2),size(H,3));
%     score = H * M;
%     score = reshape(score,bx,by);


    red_ratio = @(im) (2*im(:,:,1)) - (im(:,:,2) + im(:,:,3));
    score = red_ratio(imbar);
    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
%     score = imtophat(score,true(11,21));
    
    hx = [-ones(1,3) -1:0.5:1 ones(1,3)]';
    gx = imfilter(score,hx,'replicate');
    gx = (gx - min(gx(:))) / (max(gx(:)) - min(gx(:)));
    top = gx > prctile(gx(:),99);
    bottom = gx < prctile(gx(:),1);
    
    se_bot = [false(5,1); true(3,1)];
    se_top = [true(3,1); false(5,1)];
    
    bestoverlap = -1;
    overlap = 0;
    for i=1:10 % will break before 10
        top_ = imdilate(top,se_bot);
        bottom_ = imdilate(bottom,se_top);
        
        overlap = sum(top_ & bottom_,[1 2]);
        if overlap > bestoverlap
            bestoverlap = overlap;
            top = top_;
            bottom = bottom_;
        else
            break;
        end
    end
    imshow([top_;bottom_;top_|bottom_],[])

    pause
    continue
    
    
    [H,T,R] = hough(top,'Theta', [-90:-87 87:89],'RhoResolution', 4);
    imshow(H,[],'XData',T,'YData',R,...
                'InitialMagnification','fit');
    xlabel('\theta'), ylabel('\rho');
    axis on, axis normal, hold on;

    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));

lines = houghlines(top,T,R,P,'FillGap',5,'MinLength',10);
figure, imshow(top), hold on
max_len = 0;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

   % Determine the endpoints of the longest line segment
   len = norm(lines(k).point1 - lines(k).point2);
   if ( len > max_len)
      max_len = len;
      xy_long = xy;
   end
end


    % strategy:
    % 1) find top edges
    % 2) find bottom edges
    % morphology to simplify into 1 dot
    % RANSAC to fit 4 lines
    
    pause
    continue
    
    
%     score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
    valid = score > prctile(score(:),80);
    score = imdilate(score,true(1,3));
    score = imclose(score,true(1,5));

    score = (score - min(score(:))) / (max(score(:)) - min(score(:)));
%     valid = score > graythresh(score);
    

    valid = bwareafilt(valid,1);
    valid = imdilate(valid,true(3,7));
    
    Hcrop = find(valid(round(size(valid,1)/2),:));
    Vcrop = find(sum(valid,2)>0);
    
    scale = size(imbar,1) / size(valid,1);
    cropped_code = imbar(round((Vcrop(1)-1)*scale):round((Vcrop(end)-1)*scale),round((Hcrop(1)-1)*scale):round((Hcrop(end)-1)*scale));

    imshow(cropped_code)
    
%     imshow(imbar .* imresize(valid,size(imbar,[1 2]),'nearest'))
    
    pause
    continue
    %
    
    tmap_B = cat(3,xx,yy);
    red_ratio = @(im) (2*im(:,:,1)) - (im(:,:,2) + im(:,:,3));
    imbar = red_ratio(tformarray(f,[],resamp,[2 1],[1 2],[],tmap_B+1,0));
    
    bmin = min(imbar(:));
    bmax = max(imbar(:));
    imbar = (imbar - bmin) / (bmax-bmin);
    
    imbar_th = imtophat(imbar,true(3));
    
    % crop out the biggest dark rectangle (roughly)
    T = graythresh(imbar_th);
    Hcrop = find(imbar_th(round(size(imbar_th,1)/2),:) < T);
    Vcrop = find(imbar_th(:,round(size(imbar_th,2)/2)) < T);
%     imbar = imbar(Vcrop(1):Vcrop(end),Hcrop(1):Hcrop(end));
    imbar_th = imbar_th(Vcrop(1):Vcrop(end),Hcrop(1):Hcrop(end));

%     imbar = (imbar ./ max(imbar));
%     T = graythresh(imbar);
    imbar_smooth = imfilter(imbar_th,ones(51,51)/(51*51));
    imbar_smooth = imbar_smooth ./ max(imbar_smooth(:));
    T = graythresh(imbar_smooth);
    imshow(imbar_smooth)
%     
%     R = radon(imbar_smooth,-4:4);
%     plot(R)
%     imshow(imbar);
% plot(sum(imbar,2))
pause
continue
%     imshow(imclose(imtophat(imbar,true(1,10)),true(10)),[])
    
    
    
    [R,xp] = radon(gx,89:91); % where 1 col = 1 deg from 0 to 179
    plot(R)
    
    pause
continue;
    
    
    

    W = numel(xp) * scale * 0.8;
    H = round(scale * (bounds(2) - bounds(1) + 3));
    [yy,xx] = meshgrid(0:100:W-1, 0:100:H-1);
    figure(3)
    imshow(f)
    hold on
    scatter(yy(:),xx(:));
    hold off
    
    rot()
    
    
    scale = size(f,1) / size(valid,1);
    center = size(f,[1 2])/2;
    point = center + scale * (bounds(1)-1.5) * [cosd(orientation+90) sind(orientation+90)];
    point0_top = point - 750*[cosd(orientation) sind(orientation)];
    point1_top = point + 750*[cosd(orientation) sind(orientation)];
    
    scale = size(f,1) / size(valid,1);
    center = size(f,[1 2])/2;
    point = center + scale * (bounds(2)+1.5) * [cosd(orientation+90) sind(orientation+90)];
    point0_bot = point - 750*[cosd(orientation) sind(orientation)];
    point1_bot = point + 750*[cosd(orientation) sind(orientation)];

    figure(4)
    imshow(f)
    line([point0_top(2), point1_top(2)],[point0_top(1), point1_top(1)])
    line([point0_bot(2), point1_bot(2)],[point0_bot(1), point1_bot(1)])
    
    
    
% % %     
% % %     %find the line
% % % % imshow(imrotate(valid,90-orientation))
% % % 
% % % 
% % % % TODO: dp this automatically
% % % imshow(f)
% % % crop = imcrop(f)
% % %     
% % % red_ratio = @(im) im(:,:,1) ./ (im(:,:,2) + im(:,:,3));
% % % imshow(radon(red_ratio(crop)),[])
% % %     % filter the score blocs (nevermind, this was fun but useless)
% % %     ids = find(valid);
% % %     [x,y] = ind2sub(size(valid),ids);
% % %     rot = @(angle) [cosd(angle), -sind(angle); sind(angle), cosd(angle)];
% % %     
% % %     center = size(valid,[1 2])/2;
% % %     pts = rot(90-orientation) * ([x,y] - center)' + [offset;0] ;
% % %     
% % %     filter = abs(pts(1,:)) < 3;
% % % %     scatter(pts(2,filter),pts(1,filter))
% % %     valid(ids(~filter)) = false;
% % %     
% % %     
% % %     scale = size(f,1) / size(valid,1);
% % %     centroid = median([x(filter) y(filter)]) .* scale;
% % %     
% % %     figure(3)
% % %     imshow(f)
% % %     hold on
% % %     scatter(centroid(2),centroid(1),'filled')
% % %     hold off
% % %     pause
% % %     continue
    
    
    
    
%     valid = imdilate(valid,true(3));
%     valid = bwareafilt(valid, 1);
% imshow(valid)
%     pause
% continue
    
    % let's fit a parabola to the top 3
    A = [ % TODO: handle borders
        (offset-1:offset+1).^2
        offset-1:offset+1
        ones(1,3)
        ]';
    b = R(x-1:x+1,code_orientation);
    sol=A\b;
    bounds=roots(sol);
    if bounds(2) < bounds(1)
        bounds = [bounds(2) bounds(1)];
    end
        
    
    scale = size(f,1) / size(valid,1);
    center = size(f,[1 2])/2;
    point = center + scale * (bounds(1)-1.5) * [cosd(orientation+90) sind(orientation+90)];
    point0_top = point - 750*[cosd(orientation) sind(orientation)];
    point1_top = point + 750*[cosd(orientation) sind(orientation)];
    
    scale = size(f,1) / size(valid,1);
    center = size(f,[1 2])/2;
    point = center + scale * (bounds(2)+1.5) * [cosd(orientation+90) sind(orientation+90)];
    point0_bot = point - 750*[cosd(orientation) sind(orientation)];
    point1_bot = point + 750*[cosd(orientation) sind(orientation)];

    figure(4)
    imshow(f)
    line([point0_top(2), point1_top(2)],[point0_top(1), point1_top(1)])
    line([point0_bot(2), point1_bot(2)],[point0_bot(1), point1_bot(1)])
    pause
%     continue
%     surf(R(x-3:x+3,code_orientation-4:code_orientation+4))
    % the length is proportional, and position alors the angled axis is easy to find with a linear search
    
imshow(imrotate(f,-code_orientation + 90))

    
    pause
    continue;
    % 
    figure(3)
    
    subplot(2,2,1)
    imshow(f)
    % colorbar
    title('gt')
    
    subplot(2,2,2)
    imshow(valid_ .* f)
    title('valid mask')
    
    subplot(2,2,3)
    imshow(score,[])
    title('score')
    colorbar
    pause
    continue;
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
        pause
    end
%     pause
%     assert(debugfound,'couldn''t locate code');

end