

f = imread('test3.png');

figure(1)
imshow(f);
title('crop out the bar code region')
r = getrect();
r = round(r);
x = r(2):r(2)+r(4);
y = r(1):r(1)+r(3);

gt = false(size(f,[1 2]));
gt(x,y) = true;

imwrite(gt,'test3_gt.png')