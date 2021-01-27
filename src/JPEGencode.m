function JPEGenc = JPEGencode(img, subimg, qScale)
    %This function encodes the image and creates a cell of structs which hold the encoded image data and the necessary information for decoding the image.
    
    %Load image.
    image = load(img);
    image = struct2cell(image);
    image = image{1};
    
    %Trim image so the dimensions are divisible by 8.   
    [N, M, ~] = size(image);
    
    N = N - mod(N, 8);
    M = M - mod(M, 8);
    
    image = image(1 : N, 1 : M, :);
    
    %This variable is used if we want to erase some of the high frequency coefficients of a DCT block.
    global eraseHighFrequencyCoefficients;

    %Load huffman tables.
    global F1;
    global F2;
    global K3;
    global K4;
    global K5;
    global K6;
    load('F1.mat', 'F1'); %Difference magnitude categories for DC coding.
    load('F2.mat', 'F2'); %Categories assigned to coefficient values.
    load('Ê3.mat', 'K3'); %Table for luminance DC coefficient differences.
    load('Ê4.mat', 'K4'); %Table for chrominance DC coefficient differences.
    load('Ê5.mat', 'K5'); %Table for luminance AC coefficient differences.
    load('Ê6.mat', 'K6'); %Table for chrominance AC coefficient differences.
    
    %First element of the cell.
    JPEGenc{1}.qTableL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56;
                   14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92;
                   49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
               
    JPEGenc{1}.qTableC = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99;
                     47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99;
                     99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];
                 
    %Check if we want to erase high frequency coefficients.
    if ~isempty(eraseHighFrequencyCoefficients)
        
        %Zig-zag scanning indices.
        I = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 ... 
            49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 ...
            53 60 61 54 47 40 48 55 62 63 56 64];
       
        %Erase the required amount of highest frequency DCT coefficients.
        JPEGenc{1}.qTableL(I(end : -1 : end - eraseHighFrequencyCoefficients + 1)) = 1023;
        JPEGenc{1}.qTableC(I(end : -1 : end - eraseHighFrequencyCoefficients + 1)) = 1023;
        
    end  

    JPEGenc{1}.DCL = table2cell(K3);
    JPEGenc{1}.DCC = table2cell(K4);
    JPEGenc{1}.ACL = table2cell(K5);
    JPEGenc{1}.ACC = table2cell(K6);
    
    JPEGenc{1}.subimg = subimg;
    JPEGenc{1}.qScale = qScale;
    
    %Convert color space and subsample.
    [imageY, imageCb, imageCr] = convert2ycbcr(image, subimg);
    
    %Encode blocks with non-interleaved method.
    
    %For the luminance.
    global isLuminanceBlock;
    isLuminanceBlock = true;
    
    DCpredY = 0;
    cellIndex = 2;
    for i = 1 : 8 : N
        for j = 1 : 8 : M
           
            %Form the block.
            blockY = imageY(i : i + 7, j : j + 7);

            %Apply the DCT transformation.
            dctBlockY = blockDCT(blockY);

            %Quantize each block.
            qBlockY = quantizeJPEG(dctBlockY, JPEGenc{1}.qTableL, qScale);

            %Calculate run length symbols.
            runSymbolsY = runLength(qBlockY, DCpredY);
            DCpredY = qBlockY(1, 1);

            %Encode the run length symbols using Huffman Coding.
            huffStreamY = huffEnc(runSymbolsY);
            
            %Add block to the overall cell.            
            JPEGenc{cellIndex}.blkType = 'Y';
            JPEGenc{cellIndex}.indHor = j;
            JPEGenc{cellIndex}.indVer = i;
            JPEGenc{cellIndex}.huffStream = huffStreamY;
            
            %Update cell index.
            cellIndex = cellIndex + 1;
                        
        end
    end
    
    %For the chrominancne.
    isLuminanceBlock = false;
    
    [NC, MC] = size(imageCb);
    
    DCpredCb = 0;
    
    %Cb component.
    for i = 1 : 8 : NC
        for j = 1 : 8 : MC
           
            %Form the block.
            blockCb = imageCb(i : i + 7, j : j + 7);
            
            %Apply the DCT transformation.
            dctBlockCb = blockDCT(blockCb);
            
            %Quantize each block.
            qBlockCb = quantizeJPEG(dctBlockCb, JPEGenc{1}.qTableC, qScale);
            
            %Calculate run length symbols.
            runSymbolsCb = runLength(qBlockCb, DCpredCb);
            DCpredCb = qBlockCb(1, 1);
            
            %Encode the run length symbols using Huffman Coding.
            huffStreamCb = huffEnc(runSymbolsCb);
                        
            %Add block to the overall cell.            
            JPEGenc{cellIndex}.blkType = 'Cb';
            JPEGenc{cellIndex}.indHor = j;
            JPEGenc{cellIndex}.indVer = i;
            JPEGenc{cellIndex}.huffStream = huffStreamCb;
            
            %Update cell index.
            cellIndex = cellIndex + 1;
            
        end
    end
    
    DCpredCr = 0;
    
    %Cr component.
    for i = 1 : 8 : NC
        for j = 1 : 8 : MC
           
            %Form the block.
            blockCr = imageCr(i : i + 7, j : j + 7);
            
            %Apply the DCT transformation.
            dctBlockCr = blockDCT(blockCr);
            
            %Quantize each block.
            qBlockCr = quantizeJPEG(dctBlockCr, JPEGenc{1}.qTableC, qScale);
            
            %Calculate run length symbols.
            runSymbolsCr = runLength(qBlockCr, DCpredCr);
            DCpredCr = qBlockCr(1, 1);
            
            %Encode the run length symbols using Huffman Coding.
            huffStreamCr = huffEnc(runSymbolsCr);
                        
            %Add block to the overall cell.
            %indHor = ceil(i / 8);
            %indVer = ceil(j / 8);
            
            JPEGenc{cellIndex}.blkType = 'Cr';
            JPEGenc{cellIndex}.indHor = j;
            JPEGenc{cellIndex}.indVer = i;
            JPEGenc{cellIndex}.huffStream = huffStreamCr;
            
            %Update cell index.
            cellIndex = cellIndex + 1;
            
        end
    end
    
end

