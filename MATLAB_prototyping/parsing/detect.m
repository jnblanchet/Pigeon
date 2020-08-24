
%     code_ = 'FDFTTTAADDFDAFAAAFTTADTDAATTFFAAATFATDAAFAFDDFFDAFATAATFTDATFFDADFDADTFFDDT';
%     code_ = 'DFDFFAADATFADFTDADFATFDDTDDTDDFTFTAFDFFATATTFADTFAATATAFATTDDTAFFDADFDFDFF';
    
% J18CPTA153U061615500043N
% J18CPTA153U061615500043N
% 
code_ = 'FDFTTTAADDFDAFAAAFTTADTDAATTFFAAATFATDAAFAFDDFFDAFATAATFTDATFFDADFDADTFFDDT';
fullBinary = true(2,75);
for i=1:numel(code_)
    if code_(i) == 'F'
        fullBinary(:,i) = [false; false];
    elseif code_(i) == 'A'
        fullBinary(:,i) = [false; true];
    elseif code_(i) == 'D'
        fullBinary(:,i) = [true; false];
    end
end
fullBinary = fullBinary(:)';
decimal = sum(reshape(fullBinary,6,[])' .* [32 16 8 4 2 1],2);
    
    % check orientation
    left_sync = code_(7:9);
    right_sync = code_(numel(code_)-8:numel(code_)-6);
    isvalid = true;
    if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
        % if the sync codes are wrong, the code may be flipped
        codes = ['T','A','D','F'];
        code_ = codes(1+T(end:-1:1) * 2 + B(end:-1:1));
        left_sync = code_(7:9);
        right_sync = code_(numel(code_)-8:numel(code_)-6);
        if ~isequal('AAD',left_sync) || ~isequal('DAD',right_sync)
            % error: code was misread because the sync codes are wrong
            isvalid = false;
        end
    end
    
    if ~isvalid
        error('not valid sync');
    end
    % crop out sync codes, copy the rest to a new buffer
    valid = true(1,numel(code_));
    valid([7:9 numel(code_)-8:numel(code_)-6]) = false;
    code = code_(valid);
    buscode = code_; % copy the bus code to the returned buffer

    % crop out ECC TODO: solomon reed correction
    % ecc = code(59:70);
    % code(59:70) = [];

    assert(all( size(code) == [1 69]));
    
    % convert to binary
    binary = true(2,69);
    for i=1:numel(code)
        if code(i) == 'F'
            binary(:,i) = [false; false];
        elseif code(i) == 'A'
            binary(:,i) = [false; true];
        elseif code(i) == 'D'
            binary(:,i) = [true; false];
        end
    end
    binary = binary(:)';

    assert(all( size(binary) == [1 138]));
    
    % +1 for MATLAB 1 based indexing
    parsebin2dec = @(bin) bin2dec(char(uint8(bin)+48));

    %% field 1: UPU identifier
    UPU_identifier = 'J'; % always J

    s18ccode(1) = UPU_identifier;

        disp(sprintf('UPU_identifier is always J: %c',char(UPU_identifier)));

    
    %% field 2: format
    % TODO: error detection, only [1 4] possible
    format_identifier_bits = (0:3)+1;
    format_identifier_id = parsebin2dec(binary(format_identifier_bits));
    if format_identifier_id ~= 2
        exitcode = int32(-4);
        return;
    end
    
    %format_identifiers = {'18A','18B','18C','18D'};
    format_identifier = '   ';
    if format_identifier_id == 0
        format_identifier = '18A';
    elseif format_identifier_id == 1
        format_identifier = '18B';
    elseif format_identifier_id == 2
        format_identifier = '18C';
    elseif format_identifier_id == 3
        format_identifier = '18D';
    end
    
    s18ccode(2:4) = format_identifier;
        disp(sprintf('format_identifier is: %s',char(format_identifier)));
    
    
    %% field 3: issuer_code
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

    s18ccode(5:7) = issuer_code;
        disp(sprintf('issuer_code is: %s',char(issuer_code)));

    %% field 4: equipement_id
    hex_table1 = '0123456789ABCDEF';
    equipement_id_bits_1 = (20:23)+1; % hex 0-9;A-F
    equipement_id_bits_2 = (24:27)+1;
    equipement_id_bits_3 = (28:31)+1;

    equipement_id_1 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_1)));
    equipement_id_2 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_2)));
    equipement_id_3 = hex_table1(1+parsebin2dec(binary(equipement_id_bits_3)));

    equipement_id = [equipement_id_1, equipement_id_2, equipement_id_3];

    s18ccode(8:10) = equipement_id;
        disp(sprintf('equipement_id is: %s',char(equipement_id)));

    %% field 5: item_priority
    item_priority_bits = (32:33)+1; % hex 0-9;A-F

    priorities = ['N','L','H','U']; % from 0 to 3
    item_priority = priorities(1+parsebin2dec(binary(item_priority_bits)));

    s18ccode(11) = item_priority;

        disp(sprintf('item_priority is: %s',char(item_priority)));

    
    %% field 6: serial_number
    serial_number_bits = (34:49)+1;
    %3 characters
    %1: floor(D/5120) + 1
    %2: floor(mod(D,5120)/160)
    %3: floor(mod(D,160)/6)
    %4: mod(mod(D,160),6)
    serial_number = (parsebin2dec(binary(serial_number_bits)));
    serial_number_month = int32(floor(serial_number/5120) + 1);
    serial_number_day = int32(floor(mod(serial_number,5120)/160));
    serial_number_hour = int32(floor(mod(serial_number,160)/6));
    serial_number_10min = int32(mod(mod(serial_number,160),6));
    
    serial_number_formatted = sprintf('%02d%02d%02d%d',serial_number_month,serial_number_day,serial_number_hour,serial_number_10min);
    assert(all( size(serial_number_formatted) == [ 1, 7 ]))
    
    s18ccode(12:18) = serial_number_formatted;
        disp(sprintf('serial_number is: %02d%02d%02d%d',serial_number_month,serial_number_day,serial_number_hour,serial_number_10min));
    

    %% field 7 (note: 18D not implemented)

    n = numel(binary)-1;
    serial_number_item_bits = ([(n-9):n])+1;
    serial_number_item = int32(parsebin2dec([binary(serial_number_item_bits)]));
    % TODO: remove err correction code before this point
% 142 = 1000 1110
% 143 = 1000 1111
    serial_number_item_formatted = sprintf('%05d',serial_number_item);
    assert(all( size(serial_number_item_formatted) == [ 1, 5 ]))
    
    s18ccode(19:23) = serial_number_item_formatted;
    
        disp(sprintf('serial_number_item is: %s',serial_number_item_formatted));
    
    
    %% field 8
    tracking_indicator_bits = ([(n-11):(n-10)])+1; % hex 0-9;A-F

    tracking = ['T','F','D','N']; % from 0 to 3
    tracking_indicator = tracking(1+parsebin2dec(binary(tracking_indicator_bits)));
    
    s18ccode(24) = tracking_indicator;
    
    disp(sprintf('tracking is: %c',tracking_indicator));

    
%     s18ccode = sprintf('%c%s%s%s%c%02d%02d%02d%d%05d%c',UPU_identifier,format_identifier,issuer_code,...
%         equipement_id,item_priority,serial_number_month,serial_number_day,serial_number_hour,...
%         serial_number_10min,serial_number_item,tracking_indicator);


    % Error correction
%     error_correction_bits = 50:124;
%     error_correction = binary(error_correction_bits);
    disp(sprintf('final code is: %s',s18ccode));
    
    
    