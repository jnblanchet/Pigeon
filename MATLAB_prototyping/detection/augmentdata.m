function [g,gt_] = augmentdata(f,gt)
% data augmentation
hsv = rgb2hsv(f);
tmp = hsv;
gt_ = gt;
% 25% chance brightness change
if rand < 0.25
    tmp(:,:,3) = tmp(:,:,3) .* (1 - (randi(20) - 10) / 100);
end
% 25% chance hue shift
if rand < 0.25
    shift = (2*rand - 1) * (0.015 / 2 * pi);
    tmp(:,:,1) = mod(tmp(:,:,1) + shift,1.0);
end
% 25% chance saturation shift
if rand < 0.25
    tmp(:,:,2) = tmp(:,:,2) .* (1 - (randi(30) - 15) / 100);
end

tmp = hsv2rgb(tmp);

% 25% change rotation
if rand < 0.25
    a = randi(30) -15;
    tmp = imrotate(tmp,a,'crop');
    gt_ = imrotate(gt_,a,'crop');
end
% 25% chance small noise
if rand < 0.25
    tmp = imnoise(tmp,'gaussian',0,0.0001);
end
% 25% chance to boost blue channel
if rand < 0.25
    tmp(:,:,3) = tmp(:,:,3) .* (1 + (randi(15)) / 100);
end
g = tmp;
% imshow(tmp)
end