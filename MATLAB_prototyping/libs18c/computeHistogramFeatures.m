function [oriented_hist,rotation_invariant_hist,grid_x,grid_y] = computeHistogramFeatures(f,BLOCK_SIZE,N_BINS)
    gx = conv2(f,[-1 -2 -1; 0 0 0; 1 2 1],'same');
    gy = conv2(f,[-1 0 1; -2 0 2; -1 0 1],'same');

    theta = atan2(gy,(gx+eps));
    mag = (abs(gy) + abs(gx));

    bins = floor((theta + pi) / (2*pi) * (N_BINS));

    % accumulate histogram (in a c friendly way)
    grid_x = floor(size(f,1) / BLOCK_SIZE);
    grid_y = floor(size(f,2) / BLOCK_SIZE);
    oriented_hist = zeros(grid_x,grid_y,N_BINS,'single');
    for cell_x = 0:grid_x-1
        for cell_y = 0:grid_y-1
            for px_x = cell_x * BLOCK_SIZE:(cell_x+1) * BLOCK_SIZE - 1
                for px_y = cell_y * BLOCK_SIZE:(cell_y+1) * BLOCK_SIZE - 1
                    if(mag(px_x+1,px_y+1) >0.5)
                        b = bins(px_x+1,px_y+1);
                        if b > 0 && b < N_BINS % in float precision, sometimes the phase is > 2*pi
                            oriented_hist(cell_x+1,cell_y+1,b+1) = oriented_hist(cell_x+1,cell_y+1,b+1) + 1;
                        end
                    end
                end
            end
        end
    end
    % normalize
    oriented_hist = oriented_hist / max(oriented_hist(:));
    rotation_invariant_hist = zeros(size(oriented_hist));
    for x=1:size(oriented_hist,1)
        for y=1:size(oriented_hist,2)
            h = oriented_hist(x,y,:);
            [~,roll] = max(h,[],3);
            rotation_invariant_hist(x,y,:) = h([roll:end 1:roll-1]);
        end
    end
end

