% contains unit tests for the solomon reed error correction
addpath('galoisfield')


% FDFTTTAADDFDAFAAAFTTADTDAATTFFAAATFATDAAFAFDDFFDAFATAATFTDATFFDADFDADTFFDDT
% FDF TTT AAD DFD AFA AAF TTA DTD AAT TFF AAA TFA TDA AFA FDD FFD AFA TAA TFT DAT FFD ADF DAD TFF DDT
decimal = [8    63    22    34    17    20    61    46    23    48    21    49    57    17    10     2    17    53    51    39     2    24    38    48    43];
msg = [decimal(1:10) decimal(23:25)];
ecc = decimal(11:22);

% no errors
assert(isequal(solomonreed(decimal),msg),'errors found in uncorrupted message!');
% 1 corrupted bit
assert(isequal(solomonreed([9 decimal(2:end)]),msg),'corrupted message was not corrected correctly!');

for offset = -12:12 %  repeat corrupting different bits
    range = (1:25) + offset;
    corrupt = @(msg,step) min(63,decimal + double(mod(range,25) == 0));
    % 1 corrupted bit
    assert(isequal(solomonreed(corrupt(decimal,25)),msg),'corrupted message was not corrected correctly!');

    % 2 corrupted bits
    assert(isequal(solomonreed(corrupt(decimal,10)),msg),'corrupted message was not corrected correctly!');

    % 3 corrupted bits
    assert(isequal(solomonreed(corrupt(decimal,7)),msg),'corrupted message was not corrected correctly!');

    % 4 corrupted bits
    assert(isequal(solomonreed(corrupt(decimal,6)),msg),'corrupted message was not corrected correctly!');

    % 5 corrupted bits
    assert(isequal(solomonreed(corrupt(decimal,5)),msg),'corrupted message was not corrected correctly!');

    % 6 corrupted bits
    assert(isequal(solomonreed(corrupt(decimal,4)),msg),'corrupted message was not corrected correctly!');

end


disp('all tests passed!')
