function z = galois_conv(x,y) % Convolution of gf vectors
    GF_TABLE_M = 6;
    q = 2^GF_TABLE_M-1;
    GF_TABLE_PRIM_POLY = uint32(67);
    GF_TABLE1 = uint32([2    4    8   16   32    3    6   12   24   48   35    5   10   20   40   19   38   15   30   60   59   53   41   17   34 ...
        7   14   28   56   51   37    9   18   36   11   22   44   27   54   47   29   58   55   45   25   50   39   13   26   52 ...
        43   21   42   23   46   31   62   63   61   57   49   33    1]');
    GF_TABLE2 = uint32([0    1    6    2   12    7   26    3   32   13   35    8   48   27   18    4   24   33   16   14   52   36   54    9   45 ...
        49   38   28   41   19   56    5   62   25   11   34   31   17   47   15   23   53   51   37   44   55   40   10   61   46 ...
        30   50   22   39   43   29   60   42   21   20   59   57   58]');
    twos = [1      2      4      8     16     32     64    128    256    512   1024];

    z = x;
    % zero pad:
    z(length(x)+length(y)-1) = 0;
    z = uint32(zeros(size(z)))';
    %if input vectors belong to extension fields of GF(2),
    %perform regular GF operations
    for k = 1:length(x)
        for j = 1:length(y)
            z(k+j-1) = bitxor(z(k+j-1),galois_mul(x(k),...
                y(j),GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2));
        end
    end
    
    % make the orientation match the longest input
    if size(x,2) > size(x,1)
        %follow y
        z = z';
    end
end