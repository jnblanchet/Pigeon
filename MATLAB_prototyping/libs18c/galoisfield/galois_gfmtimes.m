function z = galois_gfmtimes(x,y)
    z=zeros(size(x,1),size(y,2),'uint32');
    x=x';
    for idx=1:size(x,2)
        for jdx=1:size(y,2)
            prod=galois_gftimes(x(:,idx),y(:,jdx));
            for k =1:size(x,1)
                z(idx,jdx) = bitxor(z(idx,jdx),prod(k));
            end
        end
    end
end

function z = galois_gftimes(x,y)
    m = 6;
    q = 2^m-1;
    E2P = uint32([2    4    8   16   32    3    6   12   24   48   35    5   10   20   40   19   38   15   30   60   59   53   41   17   34 ...
        7   14   28   56   51   37    9   18   36   11   22   44   27   54   47   29   58   55   45   25   50   39   13   26   52 ...
        43   21   42   23   46   31   62   63   61   57   49   33    1]');
    P2E = uint32([0    1    6    2   12    7   26    3   32   13   35    8   48   27   18    4   24   33   16   14   52   36   54    9   45 ...
        49   38   28   41   19   56    5   62   25   11   34   31   17   47   15   23   53   51   37   44   55   40   10   61   46 ...
        30   50   22   39   43   29   60   42   21   20   59   57   58]');
    
    z=zeros(size(y),'uint32');
    nzs = x~=0 & y~=0;
    r = z;
    r(nzs) = rem(P2E(x(nzs))+P2E(y(nzs)),q);
    z(r==0 & nzs) = uint32(1);
    z(r~=0) = E2P(r(r~=0));

end