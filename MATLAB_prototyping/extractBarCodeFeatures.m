function hist = extractBarCodeFeatures(f,BLOCK_SIZE)
    % f should be double [0,1] grayscale
    
    hx = [-1 -2 -1; 0 0 0; 1 2 1];
    hy = hx';

    gx = imfilter(f,hx);
    gy = imfilter(f,hy);

    % theta = atan2(gy,(gx+eps));
    theta = atan(gy ./(gx+eps));
    mag = abs(gy) + abs(gx);

    N_BINS = 8;
    bins = floor((theta + pi/2) / (pi) * (N_BINS-1));

    for b=N_BINS-1:-1:0
        hist(:,:,b+1) = blockproc(double(bins==b).*mag,[BLOCK_SIZE BLOCK_SIZE],@(x) sum(x.data,[1 2]));
    end
end