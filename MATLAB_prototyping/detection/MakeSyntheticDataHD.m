random_backgrounds = dir('D:\dataset\textures\*.jpg');

barcode = imresize(imread('padded.png'),1.6,'cubic');

for i = 1:100
        
    bkid = randi(numel(random_backgrounds));
    background = imresize(imread([random_backgrounds(bkid).folder filesep random_backgrounds(bkid).name]),[1080 1920],'cubic');

    randomScale = max(0.35,rand());
    B = imresize(barcode,randomScale);
    randomAngle = randi(360);
    B = imrotate(B+1,randomAngle,'nearest');
    offsetrange = [1080 1920] - size(B,[1 2]);
    offset = [randi(offsetrange(1)) randi(offsetrange(2))];
    B = padarray(B,[offset], 0,'pre');
    
    offset = [1080 1920] - size(B,[1 2]);
    B = padarray(B,[offset], 0,'post');
    
    mask = uint8(rgb2gray(B) == 0);
    
    composite = background .* mask + B .* (1-mask);
    
    randomEffect = randi(7);
    if randomEffect == 1
        composite = imnoise(composite,'gaussian',0,0.001);
    elseif randomEffect == 2
        composite = imfilter(composite,ones(5,5)/25);
    elseif randomEffect == 3
        composite = imfilter(composite, diag(ones(1,7)/7));
    else
        % nothing
            
    end
    
    imshow(composite);
    
    output = sprintf('data/trainning/code%05d.jpg',i);
    imwrite(composite,output);
    outputgt = sprintf('data/trainning/gt%05d.jpg',i);
    imwrite(mask==0,outputgt);
end