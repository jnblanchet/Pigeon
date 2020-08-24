function inv = findinverse(a,irr, twos, m, q,E2P, P2E)
    if any(a==0)
        error(message('comm:gf:DivByZero')) 
    end
    % Vectorized if Tables are available
    if ~(isempty(E2P) || isempty(P2E))
        inv = E2P(q-double(P2E(a)));
    else % Otherwise, a is a scalar
        for k=1:q
            if gfmultiply(a,uint32(k),irr,twos,m,q,E2P,P2E)==1
                inv=uint32(k);
                return
            end
        end
    end
end