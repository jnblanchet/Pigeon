function [hist,grid_x,grid_y] = extractBarCodeFeatures(f,BLOCK_SIZE,SCALE_FACT)
    % f should be double [0,1] grayscale
    
%     SCALE_FACT = 8;
%     f = imresize(imresize(f,2/SCALE_FACT),2/SCALE_FACT);
    if SCALE_FACT ~= 1
        f = imresize(f,1/SCALE_FACT,'nearest');
    end

    hx = [-1 -2 -1; 0 0 0; 1 2 1];
    hy = hx';

    for c=3:-1:1
        gx(:,:,c) = imfilter(f(:,:,c),hx);
        gy(:,:,c) = imfilter(f(:,:,c),hy);
    end
    colorphase = cat(3,...
                    atan2(gx(:,:,2),gx(:,:,1)),...
                    atan(gx(:,:,3)./(sqrt(gx(:,:,1).^2+gx(:,:,2).^2))),...
                    atan2(gy(:,:,2),gy(:,:,1)),...
                    atan(gy(:,:,3)./(sqrt(gy(:,:,1).^2+gy(:,:,2).^2)))...
                 );
%     mag = sqrt(gx.^2 + gy.^2);
%     colorphase = cat(3,...
%                     atan(mag(:,:,2)./mag(:,:,1)),...
%                     atan(mag(:,:,3)./(sqrt(mag(:,:,1).^2+mag(:,:,2).^2)))...
%                  );
    colorphase(isnan(colorphase)) = 0;
    
    N_BINS_P1 = 6;
    N_BINS_P2 = 6;
    N_BINS = N_BINS_P1 * N_BINS_P2;
    grid_x = floor(size(f,1) / BLOCK_SIZE);
    grid_y = floor(size(f,2) / BLOCK_SIZE);
    hist = zeros(grid_x,grid_y,N_BINS,'single');
    for cell_x = 0:grid_x-1
        for cell_y = 0:grid_y-1
            for px_x = cell_x * BLOCK_SIZE:(cell_x+1) * BLOCK_SIZE - 1
                for px_y = cell_y * BLOCK_SIZE:(cell_y+1) * BLOCK_SIZE - 1
                    % gx
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,1)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,2)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    % repeat for gy
                    b1 = floor((pi + colorphase(px_x+1,px_y+1,3)) ./ (2*pi) * (N_BINS_P1-1));
                    b2 = floor((pi/2 + colorphase(px_x+1,px_y+1,4)) ./ (pi) * (N_BINS_P2-1));
                    b = b1 + b2 * N_BINS_P1;
                    hist(cell_x+1,cell_y+1,b+1) = hist(cell_x+1,cell_y+1,b+1) + 1;
                end
            end
        end
    end
    % heuristic: the last bins are useless
    maxbin = 30;
    hist = hist(:,:,1:maxbin);
    
    hist = hist / (BLOCK_SIZE*BLOCK_SIZE);
end