%Results for paragraph 5.1
%Effect of quantization scale on image compression ratio.

%% Initializations.

%Clear workspace.
close all
clear
clc

%Load the images
image1 = load('img1_down.mat');
image1 = image1.img1_down;

image2 = load('img2_down.mat');
image2 = image2.img2_down;

%% Effect of quantization on compression ration.

%Encode each image with different qScale values and calculate the compression ratio (No subsampling).

%Values for qScale.
qScale = [0.1, 0.3, 0.6, 1, 2, 5, 10];

%For the first image.

compressionRatios = zeros(1, length(qScale));

for i = 1 : length(qScale)
    
    %Encode image and get bitstream.
    JPEGencStream = JPEGencodeStream('img1_down.mat', [4 4 4], qScale(i));
    
    %Calculate compression ratio.
    [N1, M1, ~] = size(image1);
    compressionRatios(i) = (N1 * M1 * 3) / (length(JPEGencStream));
    
end

figure
subplot(1, 2, 1)
plot(qScale, compressionRatios)
xlabel('qScale')
ylabel('Compression Ratio')
title('First image')

%For the second image.

compressionRatios = zeros(1, length(qScale));

for i = 1 : length(qScale)
    
    %Encode image and get bitstream.
    JPEGencStream = JPEGencodeStream('img2_down.mat', [4 4 4], qScale(i));
    
    %Calculate compression ratio.
    [N2, M2, ~] = size(image2);
    compressionRatios(i) = (N1 * M1 * 3) / (length(JPEGencStream));
    
end

subplot(1, 2, 2)
plot(qScale, compressionRatios)
xlabel('qScale')
ylabel('Compression Ratio')
title('Second image')

sgtitle('Compression ratio of image in terms of quantization scale')