%Results for paragraph 4.2
%Effect of quantization scale on image quality.
%Effect of erasing high frequency DCT coefficients on image quality.

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

%This variable is used if we want to erase some of the high frequency coefficients of a DCT block.
global eraseHighFrequencyCoefficients;
eraseHighFrequencyCoefficients = [];

%% Effect of quantization.

%Encode and decode each image using different values for qScale (No subsampling).

%Values for qScale.
qScale = [0.1, 0.3, 0.6, 1, 2, 5, 10];

%For the first image.

numberOfBits = zeros(1, length(qScale));
MSE = zeros(1, length(qScale));

figure
subplot(2, 2, 1)
imshow(image1)
title('Initial RGB image.')

%For each qScale value.
for i = 1 : length(qScale)
    
    %Encode image.
    JPEGenc = JPEGencode('img1_down.mat', [4 4 4], qScale(i));
    
    %Count the number of bits of the encoded image.
    bitCount = 0;
    for j = 2 : size(JPEGenc, 2)        
        bitCount = bitCount + length(JPEGenc{j}.huffStream);        
    end
    
    numberOfBits(i) = bitCount;
    
    %Decode image.
    imgRec = JPEGdecode(JPEGenc);
    
    %Calculate Mean Square Error between initial and decoded image.
    MSE(i) = immse(image1, imgRec);
    
    %Add to plot.
    if i < 4
        subplot(2, 2, i + 1)
    else
        if i == 4
            sgtitle('First image')
            figure
        end
        subplot(2, 2, i - 3)
    end
    imshow(imgRec)
    title(strcat("Reconstructed image with qScale = ", num2str(qScale(i))))
end
sgtitle('First image')

figure

subplot(1, 3, 1)
plot(qScale, numberOfBits)
xlabel('qScale')
ylabel('Number of Bits')

subplot(1, 3, 2)
plot(qScale, MSE)
xlabel('qScale')
ylabel('Mean Square Error')

subplot(1, 3, 3)
plot(MSE, numberOfBits)
xlabel('Mean Square Error')
ylabel('Number of Bits')

sgtitle('First image')

%For the second image.

numberOfBits = zeros(1, length(qScale));
MSE = zeros(1, length(qScale));

figure
subplot(2, 2, 1)
imshow(image2)
title('Initial RGB image.')

%For each qScale value.
for i = 1 : length(qScale)
    
    %Encode image.
    JPEGenc = JPEGencode('img2_down.mat', [4 4 4], qScale(i));
    
    %Count the number of bits of the encoded image.
    bitCount = 0;
    for j = 2 : size(JPEGenc, 2)        
        bitCount = bitCount + length(JPEGenc{j}.huffStream);        
    end
    
    numberOfBits(i) = bitCount;
    
    %Decode image.
    imgRec = JPEGdecode(JPEGenc);
    
    %Calculate Mean Square Error between initial and decoded image.
    MSE(i) = immse(image2, imgRec);
    
    %Add to plot.
    if i < 4
        subplot(2, 2, i + 1)
    else
        if i == 4
            sgtitle('Second image')
            figure
        end
        subplot(2, 2, i - 3)
    end
    imshow(imgRec)
    title(strcat("Reconstructed image with qScale = ", num2str(qScale(i))))
end
sgtitle('Second image')

figure

subplot(1, 3, 1)
plot(qScale, numberOfBits)
xlabel('qScale')
ylabel('Number of Bits')

subplot(1, 3, 2)
plot(qScale, MSE)
xlabel('qScale')
ylabel('Mean Square Error')

subplot(1, 3, 3)
plot(MSE, numberOfBits)
xlabel('Mean Square Error')
ylabel('Number of Bits')

sgtitle('Second image')

%% Effects of erasing high frequency DCT coefficients.

%Quantization scale.
qScale = 1;

%Amounts of high frequency DCT coefficients to erase.

eraseAmounts = [20, 40, 50, 60, 63];

%For the first image.

figure
subplot(2, 3, 1)
imshow(image1)
title('Initial RGB image.')
for i = 1 : length(eraseAmounts)
    
    eraseHighFrequencyCoefficients = eraseAmounts(i);
    
    %Encode image.
    JPEGenc = JPEGencode('img1_down.mat', [4 4 4], qScale);

    %Decode image.
    imgRec = JPEGdecode(JPEGenc);
    
    %Add to plot.
    subplot(2, 3, i + 1)
    imshow(imgRec)
    title(strcat("Image after erasing the ", num2str(eraseHighFrequencyCoefficients), " highest frequency DCT coefficients."))
end
sgtitle('First image')

%For the second image.

figure
subplot(2, 3, 1)
imshow(image2)
title('Initial RGB image.')
for i = 1 : length(eraseAmounts)
    
    eraseHighFrequencyCoefficients = eraseAmounts(i);
    
    %Encode image.
    JPEGenc = JPEGencode('img2_down.mat', [4 4 4], qScale);

    %Decode image.
    imgRec = JPEGdecode(JPEGenc);
    
    %Add to plot.
    subplot(2, 3, i + 1)
    imshow(imgRec)
    title(strcat("Image after erasing the ", num2str(eraseHighFrequencyCoefficients), " highest frequency DCT coefficients."))
end
eraseHighFrequencyCoefficients = [];

sgtitle('Second image')