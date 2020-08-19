function g = applyLookUpTable(f,lutx,luty)

    [H,W,~] = size(f);
    H = H-1; W = W-1; % edge clamp
    g = zeros(size(lutx,1),size(lutx,2),size(f,3));
    for i=1:size(lutx,1)
        for j=1:size(lutx,2)
            x = lutx(i,j);
            y = luty(i,j);
            
            if x < 1
                x = 1;
            elseif x > H
                x = H;
            end
            if y < 1
                y = 1;
            elseif y > W
                y = W;
            end
            
            x0 = floor(x);
            y0 = floor(y);
            x1 = x0+1;
            y1 = y0+1;
            
            alpha = x1 - x;
            beta = x1 - x;
            
            g(i,j,:) = ...
                alpha * beta * f(x0,y0,:) + ...
                alpha * (1-beta) * f(x0,y1,:) + ...
                (1-alpha) * beta * f(x1,y0,:) + ...
                (1-alpha) * (1-beta) * f(x1,y1,:);
        end
    end

end