function [Q,R]=galois_deconv(b,a)
    num_b = numel(b);
    num_a = numel(a);
    b_=b;
    Q = zeros(1,num_b-num_a+1,'uint32');
    inv = galois_findinverse(a(1));
    for idx = 1:(num_b-num_a+1)
        Q(idx) =  galois_mul(b(idx),inv);
        m = Q(idx);
        m = galois_times(m(ones(num_a,1)),a);
        b(idx:idx + num_a-1) = bitxor(b(idx :idx + num_a-1),m);
    end
    R = galois_plus(galois_conv(a,Q),b_);
end


