function x=galois_lslv(L,b)
    n=length(L);
    x=zeros(size(b),'uint32');
    x(1)=galois_mul(b(1),galois_findinverse(L(1,1)));
    for k = 2:n
        Lx=galois_gfmtimes(L(k,1:(k-1)),x(1:(k-1)));
        x(k)=galois_mul(bitxor(b(k),Lx),galois_findinverse(L(k,k)));
    end
end
