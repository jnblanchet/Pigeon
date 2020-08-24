function z = galois_times(x,y,irr,twos,m,q,E2P,P2E)
    for idx=numel(y):-1:1
        z(idx)=galois_mul(x(idx), y(idx), irr,twos,m,q,E2P,P2E);
    end
end

