% contains unit tests for the solomon reed error correction


% FDFTTTAADDFDAFAAAFTTADTDAATTFFAAATFATDAAFAFDDFFDAFATAATFTDATFFDADFDADTFFDDT
% FDF TTT AAD DFD AFA AAF TTA DTD AAT TFF AAA TFA TDA AFA FDD FFD AFA TAA TFT DAT FFD ADF DAD TFF DDT
decimal = [8    63    22    34    17    20    61    46    23    48    21    49    57    17    10     2    17    53    51    39     2    24    38    48    43];
msg = [decimal(1:10) decimal(23:25)];
ecc = decimal(11:22);

assert(isequal(solomonreed(decimal),msg),'errors found in uncorrupted message!');

% corrupt
assert(isequal(solomonreed([9 decimal(2:end)]),msg),'corrupted message was not corrected correctly!');

% 5 bits wrong
assert(isequal(solomonreed(decimal + double(mod(1:25,5) == 0)),msg),'corrupted message was not corrected correctly!');
