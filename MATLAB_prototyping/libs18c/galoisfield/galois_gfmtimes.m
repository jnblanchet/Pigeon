function z = galois_gfmtimes(x,y,irr,twos,m,q,E2P,P2E)
    z=zeros(size(x,1),size(y,2),'uint32');
    x=x';
    for idx=1:size(x,2)
        for jdx=1:size(y,2)
            prod=galois_gftimes(x(:,idx),y(:,jdx),irr,twos,m,q,E2P,P2E);
            for k =1:size(x,1)
                z(idx,jdx) = bitxor(z(idx,jdx),prod(k));
            end
        end
    end
end



function z = galois_gftimes(x,y,irr,twos,m,q,E2P,P2E)
    %here, x and y are already uint32 arrays of the appropriate size
    z=zeros(size(y),'uint32');
    %vectorize this operation if tables are available
    if ~(isempty(E2P) || isempty(P2E))
        nzs = x~=0 & y~=0;
        r = z;
        r(nzs) = rem(P2E(x(nzs))+P2E(y(nzs)),q);
        z(r==0 & nzs) = uint32(1);
        z(r~=0) = E2P(r(r~=0));
    else
        for idx=1:numel(y)
            z(idx)=gfmultiply(x(idx), y(idx), irr,twos,m,q,E2P,P2E);
        end
    end
end