function z = galois_scalardivide(x,y)
    y_inv = galois_findinverse(y);
    y_inv = y_inv(ones(size(x)));
    z = galois_times(x,y_inv);
end