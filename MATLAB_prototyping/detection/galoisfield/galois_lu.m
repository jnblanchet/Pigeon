function [L,U,P] = lu(A)   
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

    n=length(A);
    U=A;
    pivs=zeros(1,n);
    for k=1:n-1
        pivid = find(U(k:n,k)~=0,1) + k - 1;  % find non zero elements
        if isempty(pivid)
            error(message('comm:gf_lu:SingularMatrix'))
        end
        if pivid ~= k
            U([k pivid],:) = U([pivid k],:);  % swap rows
        end
        pivs(k) = pivid;
        %U(k+1:n,k) = U(k+1:n,k)/U(k,k);
        Ukk_inv= findinverse(U(k,k), GF_TABLE_PRIM_POLY, twos,GF_TABLE_M,q,...
            GF_TABLE1,GF_TABLE2);
        U(k+1:n,k)=galois_times(U(k+1:n,k),Ukk_inv(ones(n-k,1)),...
            GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2);
        % U(k+1:n,k+1:n) = U(k+1:n,k+1:n) - U(k+1:n,k)*U(k,k+1:n);
        U(k+1:n,k+1:n) = bitxor(U(k+1:n,k+1:n),...
            galois_gfmtimes(U(k+1:n,k),U(k,k+1:n), GF_TABLE_PRIM_POLY,...
            twos,GF_TABLE_M,q,GF_TABLE1,GF_TABLE2));
    end
    L=U;
    L(logical(eye(n))) = uint32(1);
    L = tril(L);
    U=triu(U);
    % Create Permutation matrix:
    P=A;
    P=eye(n,'uint32');    % start with identity
    for k=1:n-1
        P([k pivs(k)],:)=P([pivs(k) k],:);   % exchange row k with row p(k)
    end
    % Adjust L according to the Permutation matrix
    if(nargout==2)
        %L = P'*L;
        L = galois_gfmtimes(P',L,L.GF_TABLE_PRIM_POLY,twos,GF_TABLE_M,q,...
            GF_TABLE1,GF_TABLE2);
    end
end

function inv = findinverse(a,irr, twos, m, q,E2P, P2E)
    if any(a==0)
        error(message('comm:gf:DivByZero')) 
    end
    % Vectorized if Tables are available
    if ~(isempty(E2P) || isempty(P2E))
        inv = E2P(q-double(P2E(a)));
    else % Otherwise, a is a scalar
        for k=1:q
            if galois_mul(a,uint32(k),irr,twos,m,q,E2P,P2E)==1
                inv=uint32(k);
                return
            end
        end
    end
end


