random_backgrounds = dir('D:\dataset\textures\*.jpg');

barcode = imresize(imread('padded.png'),1.6,'cubic');

for i = 1:200
        
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
    
    randomEffect = randi(10);
    if randomEffect == 1
        composite = imnoise(composite,'gaussian',0,0.001);
    elseif randomEffect == 2
        composite = imfilter(composite,ones(3,3)/25);
    elseif randomEffect == 3
        composite = imfilter(composite, diag(ones(1,3)/3));
    elseif randomEffect > 7 %this is the nominal use case, and needs to be common!
        % white background with small noise
        background(:) = 255;
        composite = background .* mask + B .* (1-mask);
        composite = imnoise(composite,'gaussian',0,0.001);
    else
        % nothing
    end
    
    imshow(composite);
    
    output = sprintf('data/trainning2/code%05d.jpg',i);
    imwrite(composite,output);
    outputgt = sprintf('data/trainning2/gt%05d.jpg',i);
    imwrite(mask==0,outputgt);
end