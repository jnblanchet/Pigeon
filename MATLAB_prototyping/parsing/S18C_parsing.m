f = imread('simple.png');
imshow(f);
f = rgb2gray(f);
plot(sum(f))

T = f(5,:);
C = f(round(end/2),:);
B = f(end-5,:);

[~,mu] = kmeans(C(:),2,'MaxIter',20);
thresh = mean(mu);

binary_signal = C<thresh;
regions = regionprops(binary_signal,'Centroid');
assert(numel(regions)==75,'expected 75 bars!');
% assert(numel(regions)==57,'expected 57 bars!');
sample_coord = [regions.Centroid];
sample_coord = sample_coord(1:2:end);
figure(2)
imshow(f);
hold on 
scatter(sample_coord,20*ones(size(sample_coord)),'filled')
hold off
sample_coord = round(sample_coord);

jump = abs(sample_coord(1:end-1) - sample_coord(2:end));
assert(sum(abs(jump - mean(jump)) > (std(jump)*2.5)) == 0, 'there seems to be at least on bar missing');

T_bin = T < thresh;
B_bin = B < thresh;

% top,bottom bits values: 00, 01, 10, 11 where 1 is white
codes = ['T','D','A','F'];
code = codes(1+T_bin(sample_coord) * 2 + B_bin(sample_coord));
code_og = code;

left_sync = code(7:9);
assert(isequal('AAD',left_sync),'left synchonization code is wrong');
right_sync = code(numel(code)-8:numel(code)-6);
assert(isequal('DAD',right_sync),'right synchonization code is wrong');
% crop out sync codes
code([7:9 numel(code)-8:numel(code)-6]) = [];
% crop out ECC
% ecc = code(59:70);
% code(59:70) = [];




% directly from samples
binary = ~[T_bin(sample_coord);B_bin(sample_coord)];
% crop out sync codes and ECC (like above, but on binary this time)
binary(:,[7:9 numel(code)-8:numel(code)-6]) = [];
% binary(:,[59:70]) = [];
binary = binary(:)';



% +1 for MATLAB 1 based indexing
parsebin2dec = @(bin) bin2dec(char(uint8(bin)+48));

%% field 1
UPU_identifier = 'J'; % always J

%% field 2
format_identifier_bits = (0:3)+1;
format_identifier_id = parsebin2dec(binary(format_identifier_bits));
format_identifiers = {'18A','18B','18C','18D'};
format_identifier = format_identifiers{format_identifier_id+1};

%% field 3
issuer_code_bits = (4:19)+1;
%3 characters
%1: S18 table 1, INT(I/1600)
%2: INT(MOD(I,1600)/40_ S18a, table 1
%3: MOD(I,40)


alphabet_table1 = 'ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210';
issuer_code_id = parsebin2dec(binary(issuer_code_bits));
% issuer_code_id = 16003;
% issuer_code_id = parsebin2dec([0 0 1 0 0 0 0 0 0 1 1 1 0 0 0 1]);
% pzw
issuer_code_id_1 = floor((issuer_code_id) / 1600);
issuer_code_1 = alphabet_table1(issuer_code_id_1+1);

issuer_code_id_2 = floor(mod((issuer_code_id),1600)/40);
issuer_code_2 = alphabet_table1(issuer_code_id_2+1);

issuer_code_id_3 = floor(mod((issuer_code_id),40));
issuer_code_3 = alphabet_table1(issuer_code_id_3+1);

issuer_code = [issuer_code_1, issuer_code_2, issuer_code_3];


%% field 4
hex_table1 = '0123456789ABCDEF';
equipement_id_bits_1 = (20:23)+1; % hex 0-9;A-F
equipement_id_bits_2 = (24:27)+1;
equipement_id_bits_3 = (28:31)+1;

equipement_id_1 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_1)));
equipement_id_2 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_2)));
equipement_id_3 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_3)));

equipement_id = [equipement_id_1, equipement_id_2, equipement_id_3];

%% field 5
item_priority_bits = (32:33)+1; % hex 0-9;A-F

priorities = ['N','L','H','U']; % from 0 to 3
item_priority = priorities(1+parsebin2dec(binary(item_priority_bits)));

%% field 6
serial_number_bits = (34:49)+1;
%3 characters
%1: floor(D/5120) + 1
%2: floor(mod(D,5120)/160)
%3: floor(mod(D,160)/6)
%4: mod(mod(D,160),6)

serial_number = parsebin2dec(binary(serial_number_bits));


serial_number_month = floor(serial_number/5120) + 1;
serial_number_day = floor(mod(serial_number,5120)/160);
serial_number_hour = floor(mod(serial_number,160)/6);
serial_number_10min = mod(mod(serial_number,160),6);
serial_number = [serial_number_month serial_number_day serial_number_hour serial_number_10min];


%% field 7 (TODO: 18D not implemented)
% i'm supposed to crop out ECC i think, serial is at the end
n = numel(binary)-1;
serial_number_item_bits = ([50:54 (n-8):n])+1;
serial_number_item = parsebin2dec(binary(serial_number_item_bits));
% TODOHACK: this code is sketchy as best.

%% field 8
tracking_indicator_bits = (50:51)+1; % hex 0-9;A-F

tracking = ['T','F','D','N']; % from 0 to 3
tracking_indicator = tracking(1+parsebin2dec(binary(item_priority_bits)));


fprintf('%s\n',code_og);
fprintf('CODE = %c%s%s%s%c%02d%02d%02d%d%05d%c\n',UPU_identifier,format_identifier,issuer_code,...
    equipement_id,item_priority,serial_number_month,serial_number_day,serial_number_hour,...
    serial_number_10min,serial_number_item,tracking_indicator);
fprintf('UPU_identifier = %c\n',UPU_identifier);
fprintf('format_identifier = %s\n',format_identifier);
fprintf('issuer_code = %s\n',issuer_code);
fprintf('equipement_id = %s\n',equipement_id);
fprintf('item_priority = %c\n',item_priority);
fprintf('serial_number_month = %02d\n',serial_number_month);
fprintf('serial_number_day = %02d\n',serial_number_day);
fprintf('serial_number_hour = %02d\n',serial_number_hour);
fprintf('serial_number_10min = %d\n',serial_number_10min);
fprintf('serial_number_item = %05d\n',serial_number_item);
fprintf('tracking_indicator = %c\n',tracking_indicator);



% % % %RSENCODER Encode message with the Reed-Solomon algorithm
% % % % m is the number of bits per symbol
% % % % prim_poly: Primitive polynomial p(x). Ie for DM is 301
% % % % k is the size of the message
% % % % n is the total size (k+redundant)
% % % % Example: msg = uint8('Test')
% % % % enc_msg = rsEncoder(msg, 8, 301, 12, numel(msg));
% % % m=2;
% % % charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
% % % 
% % % charset(dec_code)
% % % 
% % % DFDFFAADATFADFTDADFATFDDTDDTDDFTFTAFDFFATATTFADTFAATATAFATTDDTAFFDADFDFDFF
% % % J18CUSA8E6N062315014880T
% % % J18CUSA8E6N062315014880
% % % 
% % % dec2bin(find(charset=='J')-1,5)
% % % '001010'
% % % 
% % % 
% % % UPU Identifier              1   J
% % % Format Identifier = 18C 	3   18C
% % % Issuer Code                 3   USA
% % % Equipment Identifier        3   8E6
% % % Item Priority               1   N
% % % Serial Number- Month        2   06
% % % Serial Number – Day         2   23
% % % Serial Number – Hour        2   15
% % % Serial Number – 10 Min      1   0
% % % Serial Number – Item no par	5   14880
% % % Tracking Indicator          1   T
