path = 'C:\Users\SPRTSTR\Documents\GitProjects\d-code-competition\MATLAB_prototyping\data\real\';
images = dir([path '*.jpg']);


for i=1:numel(images)
    f = imread([path filesep images(i).name]);
    
%     if std(size(f,[1 2]) ./ [1080 1920]) > std(size(f,[1 2]) ./ [1920 1080])
%         f = imrotate(f,-90);
%     end

    hr = imhist(f);
    
    f2 = uint8(double(f) ./ mu);
        imshow([f,f2])
    hsv = rgb2hsv(f);
    h = hsv(:,:,1);
    s = hsv(:,:,2);
%     
%     gx_buff = zeros([1080 1920],'single');
%     gy_buff = zeros([1080 1920],'single');
%     phase_buff = zeros([1080 1920],'single');
%     mag_buff = zeros([1080 1920],'single');
% 
%     s18ccode = detectHD(a, gx_buff, gy_buff, phase_buff, mag_buff);
    
%     montage(hsv/100)
    pause
end