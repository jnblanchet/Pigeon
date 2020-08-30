function y = galois_polyval(p,x)
    y = zeros(size(x),'uint32');
    if ~isempty(p)
        y(:) = p(1);
        for i=2:length(p)
            y = bitxor(galois_mul(x, y),p(i));
        end
    end
end

