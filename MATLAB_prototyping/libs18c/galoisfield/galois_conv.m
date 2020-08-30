function z = galois_conv(x,y)
    z = zeros(1,length(x)+length(y)-1,'uint32');
    assert(isequal(size(z,2),length(x)+length(y)-1))
    for k = 1:length(x)
        for j = 1:length(y)
            z(k+j-1) = bitxor(z(k+j-1),galois_mul(x(k),y(j)));
        end
    end
end