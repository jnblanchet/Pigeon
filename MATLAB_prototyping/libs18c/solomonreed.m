function [corrected, ecc, numerr] = solomonreed(codewords_decimal)
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
encoded_ = uint32([msg ecc]);

max_errors = floor((n - k) / 2);
orig_vals = encoded_;
% Initialize the error vector
errors_ = zeros(1, n, 'uint32');

% Get the alpha
alpha_power = [2    4    8   16   32    3    6   12   24   48   35    5];

% Find the syndromes (Check if dividing the message by the generator
% polynomial the result is zero)
Synd_ = galois_polyval(encoded_, alpha_power);

% Syndromes = trim(Synd);
Syndromes_ = trim_(Synd_);

% If all syndromes are zeros (perfectly divisible) there are no errors
numerr = uint32(0);
if isempty(Syndromes_)
    corrected = orig_vals(1:k);
    return;
end

% Prepare for the euclidean algorithm (Used to find the error locating
% polynomials)
r0_ = uint32([1, zeros(1, 2 * max_errors)]);
r0_ = trim_(r0_);

size_r0 = length(r0_);
r1_ = Syndromes_;
f0_ = uint32([zeros(1, size_r0 - 1) 1]);
f1_ = uint32(zeros(1, size_r0));

g0_ = f1_; g1_ = f0_;

% Do the euclidean algorithm on the polynomials r0(x) and Syndromes(x) in
% order to find the error locating polynomial
while true
    % Do a long division
    [quotient_, remainder_] = galois_deconv(r0_, r1_);
    % Add some zeros
    quotient_ = pad_(quotient_, length(g1_));
    
    % Find quotient*g1 and pad

    c_ = galois_conv(quotient_, g1_);
    c_ = trim_(c_);
    c_ = pad_(c_, length(g0_));

    % Update g as g0-quotient*g1
    g_ = galois_plus(g0_,c_);
    
    % Check if the degree of remainder(x) is less than max_errors    
    if all(remainder_(1:end - max_errors) == 0)
        break;
    end
    
    % Update r0, r1, g0, g1 and remove leading zeros
    r0_ = trim_(r1_); r1_ = trim_(remainder_);
    g0_ = g1_; g1_ = g_;
end

% Remove leading zeros
% g = trim(g);
g_ = trim_(g_);

% Find the zeros of the error polynomial on this galois field
alpha_poly = [17   41   53   59   60   30   15   38   19   40   20   10    5   35   48   24   12    6    3   32   16    8    4    2    1];
evalPoly_ = galois_polyval(g_,alpha_poly);
error_pos_ = find(evalPoly_ == 0);
numerr = uint32(numel(error_pos_));

% If no error position is found we return the received work, because
% basically is nothing that we could do and we return the received message
if isempty(error_pos_)
    numerr = uint32(99); % everything is wrong
    corrected = orig_vals(1:k);
    return;
end


% Prepare a linear system to solve the error polynomial and find the error
% magnitudes

size_error = length(error_pos_);
er_ = zeros(size_error,'uint32');
b_ = Syndromes_(1:size_error)';
for idx_ = size_error:-1:1
    e_ = galois_power( 2, (idx_ * (n - error_pos_))); % tHIS DOESN'T WORK
    er_(idx_, :) = e_; 
end

% Solve the linear system
error_mag_ = (galois_mldivide(er_ ,b_))';

% Put the error magnitude on the error vector
errors_(error_pos_) = error_mag_;

% Now to fix the errors just add with the encoded code
corrected = galois_plus(encoded_(1:k),errors_(1:k));
end

% Remove leading zeros from Galois array
function gt = trim_(g)
    valid = true(size(g));
    for i=1:numel(g)
        if g(i) > 0
            break;
        end
        valid(i) = false;
    end
    gt = g(valid);
end

function xpad = pad_(x, k)
    len = length(x);
    if (len < k)
        xpad = [zeros(1, k - len) x];
    else
        xpad = x;
    end
end