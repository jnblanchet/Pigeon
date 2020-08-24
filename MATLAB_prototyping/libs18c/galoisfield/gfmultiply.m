function y = gfmultiply(a,b,irr,twos, m, q, E2P, P2E)
if irr<=3
    y=a*b;
    return
end
if a*b==0
    y=uint32(0);
    return
end
if ~isempty(E2P) && ~isempty(P2E)
    r = rem(P2E(a)+P2E(b),q);
    if r==0
        y = uint32(1);
    else
        y = E2P(r);
    end
else
    y=uint32(0);
    temp=(uint32(bitget(a,1:m).*b)).*twos(1:m);
    for idx=1:m
        y=bitxor(y,temp(idx)); %add them all up
    end
    degY = floor(log2(double(y)));
    degQ = degY-m;
    if degQ<0
        return
    elseif degQ==0
        y=bitxor(y,irr);
        return
    else
        for idx = degQ:-1:0
            y = bitxor(y,bitget(y,m+idx+1)*irr*twos(idx+1));
        end
    end
end
end
