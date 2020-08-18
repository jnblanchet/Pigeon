function C = AddTwoArrays(A,B)
    %ADDTWOARRAYS Add the elements in two arrays 
    %   Add the elements, on an element-by-element basis to create
    %   a new array.
    % Specify the Dimensions and Data Types
    assert(isa(A, 'int32'));
    assert(all( size(A) == [ 1, 5 ]))
    assert(isa(B, 'int32'));
    assert(all( size(B) == [ 1, 5 ]))
    % Add the Arrays
    C = A + B;
end
