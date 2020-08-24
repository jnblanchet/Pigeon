function [Q,R]=galois_deconv(b,a)
    % B =   conv(A,Q) + R.
    % follow orientation of B
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

    nb = numel(b);
    na = numel(a);
    
    %short circuit if the order of denominator is larger than the
    %numerator
    inptb=b;
    Q = zeros(1,nb-na+1,'uint32');
    %standard polynomial division algorithm
    inv = findinverse(a(1), GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
    for idx = 1:(nb-na+1)
        Q(idx) =  galois_mul(b(idx),inv,GF_TABLE_PRIM_POLY,...
            twos, GF_TABLE_M, q, GF_TABLE1,GF_TABLE2);
        temp = Q(idx);
        temp = galois_times(temp(ones(na,1)),a, GF_TABLE_PRIM_POLY,...
            twos, GF_TABLE_M, q, GF_TABLE1,GF_TABLE2);
        b(idx :idx + na-1) = bitxor(b(idx :idx + na-1),temp);
    end

    if nargout>1
        R = galois_plus(galois_conv(a,Q),inptb);
    end
end


