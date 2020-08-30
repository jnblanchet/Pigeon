function z = galois_mldivide(A, b) %z = A\B matrix division; NOT identical to (A^-1)*B
    if numel(A)==1
        A = A(ones(size(b)));
        z = galois_scalardivide(1,A);
        z = galois_times(b,z);
    else
        z = zeros(size(A,2),size(b,2),'uint32');
        [L,U,P] = galois_hu(A);
        for i = 1:size(b,2)
            m = galois_lslv(L,uint32(single(P)*single(b(1:size(A,2),i))));
            m = galois_uslv(U,m);
            z(:,i) = m;
        end
    end
end
