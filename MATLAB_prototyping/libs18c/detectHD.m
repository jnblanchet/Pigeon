function s18ccode = detectHD(frame) %#codegen
    %DETECT Locates, reads and parses an S18C code from 
    % Specify the Dimensions and Data Types
    assert(isa(frame, 'uint8'));
    assert(all( size(frame) == [ 1080, 1920, 3 ]))
    
    
    
    s18ccode = 'J18CUSA8E6N062315014880T';
    assert(isa(s18ccode, 'char'));
    assert(all( size(A) == [ 1, 24 ]))
end
