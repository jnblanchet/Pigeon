function [corrected, ecc] = solomonreed(codewords_decimal)
% Define some constants defined by the S18 standard
m = 6;
prim_poly = 67;
k = 13;
redundant = 12;
n = k+redundant;

% Crop & reorder parts
msg = [codewords_decimal(1:10) codewords_decimal(23:25)];
ecc = codewords_decimal(11:22);

% Encode to galois field
encoded = gf([msg ecc], m, prim_poly);
encoded_ = uint32([msg ecc]);

max_errors = floor((n - k) / 2);
orig_vals = encoded.x;
% Initialize the error vector
errors = zeros(1, n);
errors_ = zeros(1, n, 'uint32');

% Get the alpha
alpha = gf(2, m, prim_poly);
alpha_power = [2    4    8   16   32    3    6   12   24   48   35    5];

% Find the syndromes (Check if dividing the message by the generator
% polynomial the result is zero)
Synd = polyval(encoded, alpha .^ (1:n - k));
Synd_ = galois_polyval(encoded_, alpha_power);

Syndromes = trim(Synd);
Syndromes_ = trim_(Synd_);

% If all syndromes are zeros (perfectly divisible) there are no errors
if isempty(Syndromes_)
    corrected = orig_vals(1:k);
    return;
end

% Prepare for the euclidean algorithm (Used to find the error locating
% polynomials)
r0_ = uint32([1, zeros(1, 2 * max_errors)]);
r0 = gf(r0_, m, prim_poly);
r0 = trim(r0);
r0_ = trim_(r0_);

size_r0 = length(r0_);
r1 = Syndromes;
r1_ = Syndromes_;
f0 = gf([zeros(1, size_r0 - 1) 1], m, prim_poly);
f0_ = uint32([zeros(1, size_r0 - 1) 1]);
f1 = gf(zeros(1, size_r0), m, prim_poly);
f1_ = uint32(zeros(1, size_r0));

g0 = f1; g1 = f0;
g0_ = f1_; g1_ = f0_;

% Do the euclidean algorithm on the polynomials r0(x) and Syndromes(x) in
% order to find the error locating polynomial
while true
    % Do a long division
    [quotient, remainder] = deconv(r0, r1);
    [quotient_, remainder_] = galois_deconv(r0_, r1_);
    % Add some zeros
    quotient = pad(quotient, length(g1));
    quotient_ = pad_(quotient_, length(g1_));
    
    % Find quotient*g1 and pad
    c = conv(quotient, g1);    
    c = trim(c);
    c = pad(c, length(g0));
    
    c_ = galois_conv(quotient_, g1_);
    c_ = trim_(c_);
    c_ = pad_(c_, length(g0_));

    % Update g as g0-quotient*g1
    g = g0 - c;
    g_ = galois_plus(g0_,c_);
    
    % Check if the degree of remainder(x) is less than max_errors
    if all(remainder(1:end - max_errors) == 0)
        break;
    end
    
    if all(remainder_(1:end - max_errors) == 0)
        error('WTF');
        break;
    end
    
    % Update r0, r1, g0, g1 and remove leading zeros
    r0 = trim(r1); r1 = trim(remainder);
    r0_ = trim_(r1_); r1_ = trim_(remainder_);
    g0 = g1; g1 = g;
    g0_ = g1_; g1_ = g_;
end

% Remove leading zeros
g = trim(g);
g_ = trim_(g_);

% Find the zeros of the error polynomial on this galois field
alpha_poly = [17   41   53   59   60   30   15   38   19   40   20   10    5   35   48   24   12    6    3   32   16    8    4    2    1];
evalPoly = polyval(g, alpha .^ (n - 1 : - 1 : 0));
evalPoly_ = galois_polyval(g_,alpha_poly);
error_pos = gf(find(evalPoly == 0), m);
error_pos_ = find(evalPoly_ == 0);

% If no error position is found we return the received work, because
% basically is nothing that we could do and we return the received message
if isempty(error_pos)
    corrected = orig_vals(1:k);
    return;
end

if isempty(error_pos_)
    corrected = orig_vals(1:k);
    return;
end


% Prepare a linear system to solve the error polynomial and find the error
% magnitudes
size_error = length(error_pos);
Syndrome_Vals = Syndromes.x;
b(:, 1) = Syndrome_Vals(1:size_error);
for idx = 1 : size_error
    e = alpha .^ (idx * (n - error_pos.x));
    err = e.x;
    er(idx, :) = err;
end

size_error = length(error_pos_);
b_(:, 1) = Syndromes_(1:size_error);
for idx_ = 1 : size_error
    e_ = galois_power( 2, (idx_ * (n - error_pos_))); % tHIS DOESN'T WORK
    er_(idx_, :) = e_; 
end

% Solve the linear system
error_mag = (gf(er, m, prim_poly) \ gf(b, m, prim_poly))';
error_mag_ = (galois_mldivide(er_ ,b_))';
% Put the error magnitude on the error vector
errors(error_pos.x) = error_mag.x;
errors_(error_pos_) = error_mag_;

% Bring this vector to the galois field
errors_gf = gf(errors, m, prim_poly);

% Now to fix the errors just add with the encoded code
decoded_gf = encoded(1:k) + errors_gf(1:k);

decoded_gf_ = galois_plus(encoded_(1:k),errors_(1:k));
corrected = decoded_gf.x;
assert(isequal(decoded_gf_,decoded_gf.x));
end

% Remove leading zeros from Galois array
function gt = trim_(g)
    gt = g(find(g, 1):end);
end

function xpad = pad_(x, k)
    len = length(x);
    if (len < k)
        xpad = [zeros(1, k - len) x];
    else
        xpad = x;
    end
end

function gt = trim(g)
gx = g.x;
gt = gf(gx(find(gx, 1) : end), g.m, g.prim_poly);
end

% Add leading zeros
function xpad = pad(x, k)
len = length(x);
if (len < k)
    xpad = [zeros(1, k - len) x];
end
end