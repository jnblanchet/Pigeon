clear
clc
close all
%% loop through rotations to model several scenarios
X = [];
lbl = [];

load reallbl_2.mat
gtstruct = table2cell(gTruth.LabelData);% realdata
path = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real\';
images = dir([path '*.jpg']);


for trainingSample = 1:31
    trainingSample
    %% load data
    %     output = sprintf('data/real/code%05d.jpg',trainingSample);
    output = [path filesep images(trainingSample).name];
    %     outputgt = sprintf('data/real/gt%05d.jpg',trainingSample);
    f_ = im2double(imread(output));
    gt_ = false(size(f_,[1 2]));
    for r = gtstruct{trainingSample}'
        gt_(r(2):r(2)+r(4),r(1):r(1)+r(3)) = true;
    end
    
    rr = 30;
    if trainingSample > 2
        rr = 15;
    end
    for repeat = 1:rr
        [f,gt] = augmentdata(f_,gt_);
%             figure(1), imshow(f), title('input frame');
%             imshow(f);
        
        
        %% extract features
        BLOCK_SIZE = 10;
        SCALE_FACT = 4;
        [B,grid_x,grid_y] = extractBarCodeFeatures(f,BLOCK_SIZE,SCALE_FACT);
        %     montage(B)
        
        %% analyse features using groundtruth: build a model
        %     gt = imread(outputgt)>0;        
        %     gt = imresize(gt,random_scale_factor,'nearest');
        %     gt = imrotate(gt,angle,'nearest','loose');
        isBarcodeBlock = imresize(gt,[grid_x grid_y],'nearest');
        subsample = false(numel(isBarcodeBlock),1);
        subsample((randi(10) + 10):(randi(10) + 10):end) = true;
        subsample(isBarcodeBlock(:)) = true; % keep all positive ones
        featuremap = reshape(B,size(B,1)*size(B,2),size(B,3));
        alllabels = reshape(isBarcodeBlock>0,[],1);
        X = [X;featuremap(subsample,:)];
        lbl = [lbl;alllabels(subsample)];
    end
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

save model M
save augmented_ds X lbl