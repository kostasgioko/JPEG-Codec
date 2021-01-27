% Demo 2.
%This script demonstrates the entropy reduction of the image throughout the encoding procedure.

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

%% Entropy Calculation.

%Define quantization tables.

qTableL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56;
                   14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92;
                   49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
               
qTableC = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99;
                     47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99;
                     99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];

%For the first image.

%Quantization scale.
qScale = 0.6;

%Entropy in spatial domain.
%Calculate entropy for each component.
[counts, ~] = histcounts(image1(:, :, 1), 'BinMethod', 'integers');
counts = counts ./ (N1 * M1);
counts(counts == 0) = [];
entropyR1 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(image1(:, :, 2), 'BinMethod', 'integers');
counts = counts ./ (N1 * M1);
counts(counts == 0) = [];
entropyG1 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(image1(:, :, 3), 'BinMethod', 'integers');
counts = counts ./ (N1 * M1);
counts(counts == 0) = [];
entropyB1 = - sum(counts .* log2(counts));

%Convert to YCbCr.
subimg1 = [4 2 2];

[imageY1, imageCb1, imageCr1] = convert2ycbcr(image1, subimg1);

%Entropy of quantized DCT coefficients and run length symbols.

%For the Luminance.
[NY, MY] = size(imageY1);
imageQuantizedY1 = zeros(NY, MY);
DCpredY1 = 0;

RSY1 = [];
for i = 1 : 8 : NY
    for j = 1 : 8 : MY
        
        %Form the block.
        blockY1 = imageY1(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockY1 = blockDCT(blockY1);
        
        %Quantize each block.
        qBlockY1 = quantizeJPEG(dctBlockY1, qTableL, qScale);
        
        %Calculate run length symbols.
        runSymbolsY1 = runLength(qBlockY1, DCpredY1);
        DCpredY = qBlockY1(1, 1);
        
        %Concat blocks and run symbols.
        DCTY1(i : i + 7, j : j + 7) = qBlockY1;
        RSY1 = [RSY1; runSymbolsY1];
    end
end

%Calculate entropy of quantized DCT coefficients.
[counts, ~] = histcounts(DCTY1(:, :), 'BinMethod', 'integers');
counts = counts ./ (NY * MY);
counts(counts == 0) = [];
entropyDCTY1 = - sum(counts .* log2(counts));

%Calculate entropy of run length symbols.
frequenciesY1 = [];

for i = 1 : size(RSY1, 1)
    
    if ~isempty(frequenciesY1)
        [found, index] = ismember(RSY1(i, :), frequenciesY1(:, 1:2), 'rows');
        
        if found
            frequenciesY1(index, 3) = frequenciesY1(index, 3) + 1;
        else
            frequenciesY1 = [frequenciesY1; RSY1(i, :), 1];
        end
    else
        frequenciesY1 = [frequenciesY1; RSY1(i, :), 1];
    end       
    
end

frequenciesY1(:, 3) = frequenciesY1(:, 3) / sum(frequenciesY1(:, 3));
entropyRSY1 = - sum(frequenciesY1(:, 3) .* log2(frequenciesY1(:, 3)));

%For the Chrominances.
[NC, MC] = size(imageCb1);
imageQuantizedCb1 = zeros(NC, MC);
imageQuantizedCr1 = zeros(NC, MC);
DCpredCb1 = 0;
DCpredCr1 = 0;

RSCb1 = [];
RSCr1 = [];
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
        
        %Calculate run length symbols.
        runSymbolsCb1 = runLength(qBlockCb1, DCpredCb1);
        runSymbolsCr1 = runLength(qBlockCr1, DCpredCr1);
        DCpredCb1 = qBlockCb1(1, 1);
        DCpredCr1 = qBlockCr1(1, 1);
        
        %Concat blocks and run symbols..
        DCTCb1(i : i + 7, j : j + 7) = qBlockCb1;
        DCTCr1(i : i + 7, j : j + 7) = qBlockCr1;
        RSCb1 = [RSCb1; runSymbolsCb1];
        RSCr1 = [RSCr1; runSymbolsCr1];

    end
end

%Calculate entropy of quantized DCT coefficients.
[counts, ~] = histcounts(DCTCb1(:, :), 'BinMethod', 'integers');
counts = counts ./ (NC * MC);
counts(counts == 0) = [];
entropyDCTCb1 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(DCTCr1(:, :), 'BinMethod', 'integers');
counts = counts ./ (NC * MC);
counts(counts == 0) = [];
entropyDCTCr1 = - sum(counts .* log2(counts));

%Calculate entropy of run length symbols.
frequenciesCb1 = [];

for i = 1 : size(RSCb1, 1)
    
    if ~isempty(frequenciesCb1)
        [found, index] = ismember(RSCb1(i, :), frequenciesCb1(:, 1:2), 'rows');
        
        if found
            frequenciesCb1(index, 3) = frequenciesCb1(index, 3) + 1;
        else
            frequenciesCb1 = [frequenciesCb1; RSCb1(i, :), 1];
        end
    else
        frequenciesCb1 = [frequenciesCb1; RSCb1(i, :), 1];
    end       
    
end

frequenciesCb1(:, 3) = frequenciesCb1(:, 3) / sum(frequenciesCb1(:, 3));
entropyRSCb1 = - sum(frequenciesCb1(:, 3) .* log2(frequenciesCb1(:, 3)));

frequenciesCr1 = [];

for i = 1 : size(RSCr1, 1)
    
    if ~isempty(frequenciesCr1)
        [found, index] = ismember(RSCr1(i, :), frequenciesCr1(:, 1:2), 'rows');
        
        if found
            frequenciesCr1(index, 3) = frequenciesCr1(index, 3) + 1;
        else
            frequenciesCr1 = [frequenciesCr1; RSCr1(i, :), 1];
        end
    else
        frequenciesCr1 = [frequenciesCr1; RSCr1(i, :), 1];
    end       
    
end

frequenciesCr1(:, 3) = frequenciesCr1(:, 3) / sum(frequenciesCr1(:, 3));
entropyRSCr1 = - sum(frequenciesCr1(:, 3) .* log2(frequenciesCr1(:, 3)));

%Calculate total entropies.
entropyRGB1 = entropyR1 + entropyG1 + entropyB1;

entropyDCT1 = entropyDCTY1 + entropyDCTCb1 + entropyDCTCr1;

entropyRS1 = entropyRSY1 + entropyRSCb1 + entropyRSCr1;

%Calculate total sizes.
sizeRGB1 = ceil(entropyRGB1 * N1 * M1);

sizeDCT1 = ceil(entropyDCTY1 * NY * MY + entropyDCTCb1 * NC * MC + entropyDCTCr1 * NC * MC);

sizeRS1 = ceil(entropyRSY1 * size(RSY1, 1) + entropyRSCb1 * size(RSCb1, 1) + entropyRSCr1 * size(RSCr1, 1));


disp("First image")
disp("-----------")
disp("Entropies")
disp(strcat("Entropy in spatial domain (RGB): ", num2str(entropyRGB1), " (Sample: value of all three components)"))
disp(strcat("Entropy of quantized DCT coefficients: ", num2str(entropyDCT1), " (Sample: value of all three components)"))
disp(strcat("Entropy of run length symbols: ", num2str(entropyRS1), " (Sample: run length symbol of all three components)"))
disp(" ")
disp("Sizes in bits")
disp(strcat("Total size in spatial domain (RGB): ", num2str(sizeRGB1)))
disp(strcat("Total size of quantized DCT coefficients: ", num2str(sizeDCT1)))
disp(strcat("Total size of run length symbols: ", num2str(sizeRS1)))

%For the second image.

%Quantization scale.
qScale = 5;

%Entropy in spatial domain.
%Calculate entropy for each component.
[counts, ~] = histcounts(image2(:, :, 1), 'BinMethod', 'integers');
counts = counts ./ (N2 * M2);
counts(counts == 0) = [];
entropyR2 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(image2(:, :, 2), 'BinMethod', 'integers');
counts = counts ./ (N2 * M2);
counts(counts == 0) = [];
entropyG2 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(image2(:, :, 3), 'BinMethod', 'integers');
counts = counts ./ (N2 * M2);
counts(counts == 0) = [];
entropyB2 = - sum(counts .* log2(counts));

%Convert to YCbCr.
subimg2 = [4 4 4];

[imageY2, imageCb2, imageCr2] = convert2ycbcr(image2, subimg2);

%Entropy of quantized DCT coefficients and run length symbols.

%For the Luminance.
[NY, MY] = size(imageY2);
imageQuantizedY2 = zeros(NY, MY);
DCpredY2 = 0;

RSY2 = [];
for i = 1 : 8 : NY
    for j = 1 : 8 : MY
        
        %Form the block.
        blockY2 = imageY2(i : i + 7, j : j + 7);
        
        %Apply the DCT transformation.
        dctBlockY2 = blockDCT(blockY2);
        
        %Quantize each block.
        qBlockY2 = quantizeJPEG(dctBlockY2, qTableL, qScale);
        
        %Calculate run length symbols.
        runSymbolsY2 = runLength(qBlockY2, DCpredY2);
        DCpredY = qBlockY2(1, 1);
        
        %Concat blocks and run symbols.
        DCTY2(i : i + 7, j : j + 7) = qBlockY2;
        RSY2 = [RSY2; runSymbolsY2];
    end
end

%Calculate entropy of quantized DCT coefficients.
[counts, ~] = histcounts(DCTY2(:, :), 'BinMethod', 'integers');
counts = counts ./ (NY * MY);
counts(counts == 0) = [];
entropyDCTY2 = - sum(counts .* log2(counts));

%Calculate entropy of run length symbols.
frequenciesY2 = [];

for i = 1 : size(RSY2, 1)
    
    if ~isempty(frequenciesY2)
        [found, index] = ismember(RSY2(i, :), frequenciesY2(:, 1:2), 'rows');
        
        if found
            frequenciesY2(index, 3) = frequenciesY2(index, 3) + 1;
        else
            frequenciesY2 = [frequenciesY2; RSY2(i, :), 1];
        end
    else
        frequenciesY2 = [frequenciesY2; RSY2(i, :), 1];
    end       
    
end

frequenciesY2(:, 3) = frequenciesY2(:, 3) / sum(frequenciesY2(:, 3));
entropyRSY2 = - sum(frequenciesY2(:, 3) .* log2(frequenciesY2(:, 3)));

%For the Chrominances.
[NC, MC] = size(imageCb2);
imageQuantizedCb2 = zeros(NC, MC);
imageQuantizedCr2 = zeros(NC, MC);
DCpredCb2 = 0;
DCpredCr2 = 0;

RSCb2 = [];
RSCr2 = [];
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
        
        %Calculate run length symbols.
        runSymbolsCb2 = runLength(qBlockCb2, DCpredCb2);
        runSymbolsCr2 = runLength(qBlockCr2, DCpredCr2);
        DCpredCb2 = qBlockCb2(1, 1);
        DCpredCr2 = qBlockCr2(1, 1);
        
        %Concat blocks and run symbols..
        DCTCb2(i : i + 7, j : j + 7) = qBlockCb2;
        DCTCr2(i : i + 7, j : j + 7) = qBlockCr2;
        RSCb2 = [RSCb2; runSymbolsCb2];
        RSCr2 = [RSCr2; runSymbolsCr2];

    end
end

%Calculate entropy of quantized DCT coefficients.
[counts, ~] = histcounts(DCTCb2(:, :), 'BinMethod', 'integers');
counts = counts ./ (NC * MC);
counts(counts == 0) = [];
entropyDCTCb2 = - sum(counts .* log2(counts));

[counts, ~] = histcounts(DCTCr2(:, :), 'BinMethod', 'integers');
counts = counts ./ (NC * MC);
counts(counts == 0) = [];
entropyDCTCr2 = - sum(counts .* log2(counts));

%Calculate entropy of run length symbols.
frequenciesCb2 = [];

for i = 1 : size(RSCb2, 1)
    
    if ~isempty(frequenciesCb2)
        [found, index] = ismember(RSCb2(i, :), frequenciesCb2(:, 1:2), 'rows');
        
        if found
            frequenciesCb2(index, 3) = frequenciesCb2(index, 3) + 1;
        else
            frequenciesCb2 = [frequenciesCb2; RSCb2(i, :), 1];
        end
    else
        frequenciesCb2 = [frequenciesCb2; RSCb2(i, :), 1];
    end       
    
end

frequenciesCb2(:, 3) = frequenciesCb2(:, 3) / sum(frequenciesCb2(:, 3));
entropyRSCb2 = - sum(frequenciesCb2(:, 3) .* log2(frequenciesCb2(:, 3)));

frequenciesCr2 = [];

for i = 1 : size(RSCr2, 1)
    
    if ~isempty(frequenciesCr2)
        [found, index] = ismember(RSCr2(i, :), frequenciesCr2(:, 1:2), 'rows');
        
        if found
            frequenciesCr2(index, 3) = frequenciesCr2(index, 3) + 1;
        else
            frequenciesCr2 = [frequenciesCr2; RSCr2(i, :), 1];
        end
    else
        frequenciesCr2 = [frequenciesCr2; RSCr2(i, :), 1];
    end       
    
end

frequenciesCr2(:, 3) = frequenciesCr2(:, 3) / sum(frequenciesCr2(:, 3));
entropyRSCr2 = - sum(frequenciesCr2(:, 3) .* log2(frequenciesCr2(:, 3)));

%Calculate total entropies.
entropyRGB2 = entropyR2 + entropyG2 + entropyB2;

entropyDCT2 = entropyDCTY2 + entropyDCTCb2 + entropyDCTCr2;

entropyRS2 = entropyRSY2 + entropyRSCb2 + entropyRSCr2;

%Calculate total sizes.
sizeRGB2 = ceil(entropyRGB2 * N2 * M2);

sizeDCT2 = ceil(entropyDCTY2 * NY * MY + entropyDCTCb2 * NC * MC + entropyDCTCr2 * NC * MC);

sizeRS2 = ceil(entropyRSY2 * size(RSY2, 1) + entropyRSCb2 * size(RSCb2, 1) + entropyRSCr2 * size(RSCr2, 1));

disp(" ")
disp("Second image")
disp("-----------")
disp("Entropies")
disp(strcat("Entropy in spatial domain (RGB): ", num2str(entropyRGB2), " (Sample: value of all three components)"))
disp(strcat("Entropy of quantized DCT coefficients: ", num2str(entropyDCT2), " (Sample: value of all three components)"))
disp(strcat("Entropy of run length symbols: ", num2str(entropyRS2), " (Sample: run length symbol of all three components)"))
disp(" ")
disp("Sizes in bits")
disp(strcat("Total size in spatial domain (RGB): ", num2str(sizeRGB2)))
disp(strcat("Total size of quantized DCT coefficients: ", num2str(sizeDCT2)))
disp(strcat("Total size of run length symbols: ", num2str(sizeRS2)))
