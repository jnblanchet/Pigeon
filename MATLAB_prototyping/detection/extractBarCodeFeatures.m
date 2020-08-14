function [hist,oriented_hist,theta,mag] = extractBarCodeFeatures(f,BLOCK_SIZE)
    % f should be double [0,1] grayscale
    
    hx = [-1 -2 -1; 0 0 0; 1 2 1];
    hy = hx';

    gx = imfilter(f,hx,'replicate');
    gy = imfilter(f,hy,'replicate');
    
    % theta = atan2(gy,(gx+eps));
    theta = atan2(gy,(gx+eps));
    mag = (abs(gy) + abs(gx));
    
    N_BINS = 20;
    bins = floor((theta + pi) / (2*pi+eps) * (N_BINS));
figure(100), imshow((mag>0.07 & mag<0.25))
    for b=N_BINS-1:-1:0
        hist(:,:,b+1) = blockproc(double(bins==b).*(mag>0.07 & mag<0.25),[BLOCK_SIZE BLOCK_SIZE],@(x) sum(x.data,[1 2]));
    end
    
    hist = hist / max(hist(:));
    % edges are always 0
%     hist([1 end],:,:) = 0;
%     hist(:,[1 end],:) = 0;

    oriented_hist = hist;
    
    for x=1:size(hist,1)
        for y=1:size(hist,2)
            h = hist(x,y,:);
            [~,roll] = max(h,[],3);
            hist(x,y,:) = h([roll:end 1:roll-1]);
        end
    end
end