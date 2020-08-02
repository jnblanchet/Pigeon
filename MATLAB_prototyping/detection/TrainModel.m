clear
clc
close all
%% loop through rotations to model several scenarios
X = [];
lbl = [];
for trainingSample = 1:100
    %% load data
    output = sprintf('data/synthetic/code%05d.jpg',trainingSample);
    outputgt = sprintf('data/synthetic/gt%05d.jpg',trainingSample);
    random_scale_factor = max(.35,rand(1)+0.5);
    f = im2double(rgb2gray(imread(output)));
    f = imresize(f,random_scale_factor);
%     f = imrotate(f,angle,'nearest','loose');
    figure(1), imshow(f), title('input frame');    
    imshow(f);

    %% extract features
    BLOCK_SIZE = 30;
    B = extractBarCodeFeatures(f,BLOCK_SIZE);
    montage(B)

    %% analyse features using groundtruth: build a model
    gt = imread(outputgt)>0;
    gt = imresize(gt,random_scale_factor,'nearest');
%     gt = imrotate(gt,angle,'nearest','loose');
    isBarcodeBlock = blockproc(gt,[BLOCK_SIZE BLOCK_SIZE],@(x) max(x.data(:)));
    X = [X;reshape(B,size(B,1)*size(B,2),size(B,3))];
    lbl = [lbl;reshape(isBarcodeBlock>0,[],1)];
end

X(isnan(X)) = 0;

% is linear regression enough?
M = X \ lbl;
score = X * M; % eval
% imshow(reshape(score,size(B,1),size(B,2)),[])
% x = 0:0.01:1;
x = 0:0.01:1;
figure(2)
clf
h1 = histogram(score(logical(lbl)),x);
x_ = h1.BinEdges(1:end-1) - (h1.BinEdges(2) - h1.BinEdges(1))/2;
h1 = h1.Values(2:end) / sum(h1.Values(2:end));
h2 = histogram(score(~logical(lbl)),x);
h2 = h2.Values(2:end) / sum(h2.Values(2:end));
x_ = x_(2:end)
plot(x_, h1);
hold on
plot(x_, h2);
hold off
T = 0.165;

save model M T
