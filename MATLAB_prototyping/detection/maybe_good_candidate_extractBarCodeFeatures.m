function [hist,grid_x,grid_y] = extractBarCodeFeatures(f,BLOCK_SIZE)
    % f should be double [0,1] grayscale
        
    
    lab = rgb2lab(imresize(f,0.25));
    lap = [1 1 1; 1 -8 1; 1 1 1];
    lab(:,:,2:3) = lab(:,:,2:3) - 2*imfilter(lab(:,:,2:3),lap);
    g = lab2rgb(lab);
    
    hsv = rgb2hsv(imresize(g,4));
    h = hsv(:,:,1);
    s = hsv(:,:,2);    
    N_BINS = 20;
    
    grid_x = floor(size(f,1) / BLOCK_SIZE);
    grid_y = floor(size(f,2) / BLOCK_SIZE);
    hist = zeros(grid_x,grid_y,N_BINS,'single');
    for cell_x = 0:grid_x-1
        for cell_y = 0:grid_y-1
            for px_x = cell_x * BLOCK_SIZE:(cell_x+1) * BLOCK_SIZE - 1
                for px_y = cell_y * BLOCK_SIZE:(cell_y+1) * BLOCK_SIZE - 1
                    s_ = s(px_x+1,px_y+1);
                    if s_ > 0.04 && s_ < 0.45
                        b = round(h(px_x+1,px_y+1) * N_BINS);
                        if b > 0 && b < N_BINS % in float precision, sometimes the phase is > 2*pi
                            hist(cell_x+1,cell_y+1,b+1) = hist(cell_x+1,cell_y+1,b+1) + 1;
                        end
                    end
                end
            end
        end
    end
    
    hist = hist / max(hist(:));    
end