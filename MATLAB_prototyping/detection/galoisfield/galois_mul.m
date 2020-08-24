function z = galois_mul(x,y,irr,twos,m,q,E2P,P2E)
    %here, x and y are already uint32 arrays of the appropriate size
    z=zeros(size(y),'uint32');
    %vectorize this operation if tables are available
    if ~(isempty(E2P) || isempty(P2E))
        nzs = x~=0 & y~=0;
        r = z;
        r(nzs) = rem(P2E(x(nzs))+P2E(y(nzs)),q);
        z(r==0 & nzs) = uint32(1);
        z(r~=0) = E2P(r(r~=0));    
    end
end