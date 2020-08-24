function x=galois_lsolve(L,b)
    %  solution to equations L*x=b. b must be a column vector. and
    %  L is lower-triangular and square of full rank
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

    n=length(L);
    x=zeros(size(b),'uint32');
    % x(1) = b(1)/L(1,1);
    x(1)=galois_mul(b(1),findinverse(L(1,1),GF_TABLE_PRIM_POLY,...
        twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2),GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,...
        GF_TABLE1,GF_TABLE2);
    for k = 2:n
        % x(k) = (b(k) - L(k, 1:k-1)*x(1: k-1))/L(k,k);
        Lx=gfmtimes(L(k,1:(k-1)),x(1:(k-1)),GF_TABLE_PRIM_POLY,twos,...
            GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
        x(k)=galois_mul(bitxor(b(k),Lx),findinverse(L(k,k),...
            GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2),...
            GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
    end
end

function z = gfmtimes(x,y,irr,twos,m,q,E2P,P2E)
    z=zeros(size(x,1),size(y,2),'uint32');
    x=x';
    for idx=1:size(x,2)
        for jdx=1:size(y,2)
            prod=galois_times(x(:,idx),y(:,jdx),irr,twos,m,q,E2P,P2E);
            for k =1:size(x,1)
                z(idx,jdx) = bitxor(z(idx,jdx),prod(k));
            end
        end
    end
end
