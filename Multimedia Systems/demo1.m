% Demo 1.
%This script demonstrates the effect of transforming the images from RGB to RCbCr with subsampling and back.
%As well as, applying the DCT transformation to each block, quantizing it and apllying the inverse functions.
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

%Trim images so the dimensions are divisible by 8.   
[N1, M1, ~] = size(image1);
[N2, M2, ~] = size(image2);
    
N1 = N1 - mod(N1, 8);
M1 = M1 - mod(M1, 8);

N2 = N2 - mod(N2, 8);
M2 = M2 - mod(M2, 8);

image1 = image1(1 : N1, 1 : M1, :);

image2 = image2(1 : N2, 1 : M2, :);   

%% Color space conversion and Subsampling.

%First image.
subimg1 = [4 2 2];

[imageY1, imageCb1, imageCr1] = convert2ycbcr(image1, subimg1);

imageRGB1 = convert2rgb(imageY1, imageCb1, imageCr1, subimg1);

%Show the image before and after conversion.
figure

subplot(1, 2, 1)
imshow(image1)
title('Initial RGB image.')

subplot(1, 2, 2)
imshow(imageRGB1)
title('Image after color conversion and 4:2:2 subsampling.')

sgtitle('First image')

%Second image.
subimg2 = [4 4 4];

[imageY2, imageCb2, imageCr2] = convert2ycbcr(image2, subimg2);

imageRGB2 = convert2rgb(imageY2, imageCb2, imageCr2, subimg2);

%Show the image before and after conversion.
figure

subplot(1, 2, 1)
imshow(image2)
title('Initial RGB image.')

subplot(1, 2, 2)
imshow(imageRGB2)
title('Image after color conversion and 4:4:4 subsampling.')

sgtitle('Second image')

%% DCT transformation and Quantization.

%Define quantization tables.

qTableL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56;
                   14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92;
                   49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
               
qTableC = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99;
                     47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99;
                     99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];

%First image.

%Quantization scale.
qScale = 0.6;

%For the Luminance.
[NY, MY] = size(imageY1);
imageQuantizedY1 = zeros(NY, MY);

for i = 1 : 8 : NY
    for j = 1 : 8 : MY
        
        %Form the block.
        blockY1 = imageY1(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockY1 = blockDCT(blockY1);
        
        %Quantize each block.
        qBlockY1 = quantizeJPEG(dctBlockY1, qTableL, qScale);
                
        %Dequantize each block.
        dctBlockY1 = dequantizeJPEG(qBlockY1, qTableL, qScale);
        
        %Apply the inverse DCT transformation.
        blockY1 = iblockDCT(dctBlockY1);
        
        %Reconstruct image.
        imageQuantizedY1(i : i + 7, j : j + 7) = blockY1;
    end
end

%For the Chrominances.
[NC, MC] = size(imageCb1);
imageQuantizedCb1 = zeros(NC, MC);
imageQuantizedCr1 = zeros(NC, MC);

for i = 1 : 8 : NC
    for j = 1 : 8 : MC
        
        %Form the block.
        blockCb1 = imageCb1(i : i + 7, j : j + 7);
        blockCr1 = imageCr1(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockCb1 = blockDCT(blockCb1);
        dctBlockCr1 = blockDCT(blockCr1);
        
        %Quantize each block.
        qBlockCb1 = quantizeJPEG(dctBlockCb1, qTableC, qScale);
        qBlockCr1 = quantizeJPEG(dctBlockCr1, qTableC, qScale);
        
        %Dequantize each block.
        dctBlockCb1 = dequantizeJPEG(qBlockCb1, qTableC, qScale);
        dctBlockCr1 = dequantizeJPEG(qBlockCr1, qTableC, qScale);
        
        %Apply the inverse DCT transformation.
        blockCb1 = iblockDCT(dctBlockCb1);
        blockCr1 = iblockDCT(dctBlockCr1);
        
        %Reconstruct image.
        imageQuantizedCb1(i : i + 7, j : j + 7) = blockCb1;
        imageQuantizedCr1(i : i + 7, j : j + 7) = blockCr1;
    end
end

imageRGBQuantized1 = convert2rgb(imageQuantizedY1, imageQuantizedCb1, imageQuantizedCr1, subimg1);

% Show the image before and after processing.
figure

subplot(1, 2, 1)
imshow(image1)
title('Initial RGB image.')

subplot(1, 2, 2)
imshow(imageRGBQuantized1)
title('Image after color conversion, subsampling and DCT coefficient quantization.')

sgtitle('First image')


%Second image.

%Quantization scale.
qScale = 5;

%For the Luminance.
[NY, MY] = size(imageY2);
imageQuantizedY2 = zeros(NY, MY);

isLuminanceBlock = true;
DCpredY = 0;

for i = 1 : 8 : NY
    for j = 1 : 8 : MY
        
        %Form the block.
        blockY2 = imageY2(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockY2 = blockDCT(blockY2);
        
        %Quantize each block.
        qBlockY2 = quantizeJPEG(dctBlockY2, qTableL, qScale);        
               
        %Dequantize each block.
        dctBlockY2 = dequantizeJPEG(qBlockY2, qTableL, qScale);
        
        %Apply the inverse DCT transformation.
        blockY2 = iblockDCT(dctBlockY2);
        
        %Reconstruct image.
        imageQuantizedY2(i : i + 7, j : j + 7) = blockY2;
    end
end

%For the Chrominances.
[NC, MC] = size(imageCb2);
imageQuantizedCb2 = zeros(NC, MC);
imageQuantizedCr2 = zeros(NC, MC);

isLuminanceBlock = false;
DCpredCb = 0;
DCpredCr = 0;

for i = 1 : 8 : NC
    for j = 1 : 8 : MC
        
        %Form the block.
        blockCb2 = imageCb2(i : i + 7, j : j + 7);
        blockCr2 = imageCr2(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockCb2 = blockDCT(blockCb2);
        dctBlockCr2 = blockDCT(blockCr2);
        
        %Quantize each block.
        qBlockCb2 = quantizeJPEG(dctBlockCb2, qTableC, qScale);
        qBlockCr2 = quantizeJPEG(dctBlockCr2, qTableC, qScale);        
        
        %Dequantize each block.
        dctBlockCb2 = dequantizeJPEG(qBlockCb2, qTableC, qScale);
        dctBlockCr2 = dequantizeJPEG(qBlockCr2, qTableC, qScale);
        
        %Apply the inverse DCT transformation.
        blockCb2 = iblockDCT(dctBlockCb2);
        blockCr2 = iblockDCT(dctBlockCr2);
        
        %Reconstruct image.
        imageQuantizedCb2(i : i + 7, j : j + 7) = blockCb2;
        imageQuantizedCr2(i : i + 7, j : j + 7) = blockCr2;
    end
end

imageRGBQuantized2 = convert2rgb(imageQuantizedY2, imageQuantizedCb2, imageQuantizedCr2, subimg2);

% Show the image before and after processing.
figure

subplot(1, 2, 1)
imshow(image2)
title('Initial RGB image.')

subplot(1, 2, 2)
imshow(imageRGBQuantized2)
title('Image after color conversion, subsampling and DCT coefficient quantization.')

sgtitle('Second image')