function x=galois_uslv(A,b)
    n=length(A);
    x=zeros(size(b),'uint32');
    x(n)=galois_mul(b(n),galois_findinverse(A(n,n)));
    for k=n-1:-1:1
        A_inv = galois_findinverse(A(k,k));
        A_ = galois_gfmtimes(A(k,k+1:n),x(k+1:n));
        x(k)= galois_mul(bitxor(b(k),A_),A_inv);
    end
end
