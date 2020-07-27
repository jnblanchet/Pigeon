clear
clc

%% load data
f = im2double(rgb2gray(imread('test2.png')));
imshow(f);

%% extract features
BLOCK_SIZE = 50;
B = extractBarCodeFeatures(f,BLOCK_SIZE);
montage(B/600)

%% analyse features using groundtruth: build a model
isBarcodeBlock = blockproc(imread('test2_gt.png'),[BLOCK_SIZE BLOCK_SIZE],@(x) max(x.data(:)));
X = reshape(B,size(B,1)*size(B,2),size(B,3));
lbl = reshape(isBarcodeBlock>0,[],1);
% is linear regression enough?
M = X \ lbl;
score = X * M; % eval

T = 0.36;


%% generalize on new data
f = im2double(rgb2gray(imread('test3.png')));
imshow(f);

%% extract features
B = extractBarCodeFeatures(f,BLOCK_SIZE);
montage(B/600)

%% analyse features using groundtruth: build a model
X = reshape(B,size(B,1)*size(B,2),size(B,3));
score = X * M; % eval

valid = double(reshape(score,size(B,1),size(B,2)) >0.37);
valid = double(imresize(valid, size(f,[1 2]),'nearest'));

figure(2)
subplot(1,2,1)
imshow(f)
colorbar
title('gt')
subplot(1,2,2)
imshow(valid .* f)
title('score')
% colormap('jet')
colorbar

