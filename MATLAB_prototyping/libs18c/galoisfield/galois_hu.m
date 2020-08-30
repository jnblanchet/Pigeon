function [L,U,P] = galois_hu(A)   
    n=length(A);
    U=A;
    pivs=zeros(1,n);
    for k=1:n-1
        pivid = find(U(k:n,k)~=0,1) + k - 1;
        if pivid ~= k
            U([k pivid],:) = U([pivid k],:);
        end
        pivs(k) = pivid;
        Ukk_inv= galois_findinverse(U(k,k));
        U(k+1:n,k)=galois_times(U(k+1:n,k),Ukk_inv(ones(n-k,1)));
        U(k+1:n,k+1:n) = bitxor(U(k+1:n,k+1:n),galois_gfmtimes(U(k+1:n,k),U(k,k+1:n)));
    end
    L=U;
    L(logical(eye(n))) = uint32(1);
    L = tril(L);
    U=triu(U);
    P=eye(n,'uint32');
    for k=1:n-1
        P([k pivs(k)],:)=P([pivs(k) k],:);
    end
    if(nargout==2)
        L = galois_gfmtimes(P',L);
    end
end

