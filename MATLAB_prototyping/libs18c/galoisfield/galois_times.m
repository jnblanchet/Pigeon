function z = galois_times(x,y)
    z = zeros(size(y),'uint32');
    for idx=numel(y):-1:1
        z(idx)=galois_mul(x(idx), y(idx));
    end
end

