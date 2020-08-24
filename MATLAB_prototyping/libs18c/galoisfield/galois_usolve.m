function x=galois_usolve(U,b)
    % solve the equation U*x=b using reverse substitution where U
    % has full rank and b is a column

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

    n=length(U);
    x=zeros(size(b),'uint32');
    %x(n)=b(n)/U(n,n);
    x(n)=galois_mul(b(n),findinverse(U(n,n),...
        GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2), ...
        GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
    for k=n-1:-1:1
        Ukk_inv = findinverse(U(k,k), GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
        % x(k)=(b(k) - U(k,k+1:n)*x(k+1:n))/U(k,k);
        Ux = galois_gfmtimes(U(k,k+1:n),x(k+1:n),...
            GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
        x(k)= galois_mul(bitxor(b(k),Ux),...
            Ukk_inv,GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
    end
end
