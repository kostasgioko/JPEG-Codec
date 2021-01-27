function imgRec = JPEGdecode(JPEGenc)
    %This function takes s cell of structs with the encoded image as input, and decodes the image.
    
    %Load decoding tables.
    global HuffmanDecode_DC_L;
    global HuffmanDecode_DC_C;
    global HuffmanDecode_AC_L;
    global HuffmanDecode_AC_C;
    load('HuffmanDecode_DC_L.mat', 'HuffmanDecode_DC_L');
    load('HuffmanDecode_DC_C.mat', 'HuffmanDecode_DC_C');
    load('HuffmanDecode_AC_L.mat', 'HuffmanDecode_AC_L');
    load('HuffmanDecode_AC_C.mat', 'HuffmanDecode_AC_C');
    
    %Decode luminance blocks.
    global isLuminanceBlock;
    isLuminanceBlock = true;
    
    DCpredY = 0;
    cellIndex = 2;
    
    while strcmp(JPEGenc{cellIndex}.blkType, 'Y')
        
        %Decode the run length symbols.
        runSymbolsY = huffDec(JPEGenc{cellIndex}.huffStream);
        
        %Get the quantization coefficients from the run length symbols.
        qBlockY = irunLength(runSymbolsY, DCpredY);
        DCpredY = qBlockY(1, 1);
        
        %Dequantize each block.
        dctBlockY = dequantizeJPEG(qBlockY, JPEGenc{1}.qTableL, JPEGenc{1}.qScale);
        
        %Apply the inverse DCT transformation.
        blockY = iblockDCT(dctBlockY);
        
        %Reconstruct image.
        j = JPEGenc{cellIndex}.indHor;
        i = JPEGenc{cellIndex}.indVer;
        
        imageY(i : i + 7, j : j + 7) = blockY;
        
        %Update cell index.
        cellIndex = cellIndex + 1;
        
    end
    
    %Decode chrominance blocks.
    isLuminanceBlock = false;
    
    %Cb component.
    DCpredCb = 0;
    
    while strcmp(JPEGenc{cellIndex}.blkType, 'Cb')
        
        %Decode the run length symbols.
        runSymbolsCb = huffDec(JPEGenc{cellIndex}.huffStream);
        
        %Get the quantization coefficients from the run length symbols.
        qBlockCb = irunLength(runSymbolsCb, DCpredCb);
        DCpredCb = qBlockCb(1, 1);
        
        %Dequantize each block.
        dctBlockCb = dequantizeJPEG(qBlockCb, JPEGenc{1}.qTableC, JPEGenc{1}.qScale);
        
        %Apply the inverse DCT transformation.
        blockCb = iblockDCT(dctBlockCb);
        
        %Reconstruct image.
        j = JPEGenc{cellIndex}.indHor;
        i = JPEGenc{cellIndex}.indVer;
        
        imageCb(i : i + 7, j : j + 7) = blockCb;
        
        %Update cell index.
        cellIndex = cellIndex + 1;
        
    end
    
    %Cr component.
    DCpredCr = 0;
    
    while cellIndex <= size(JPEGenc, 2)
        
        %Decode the run length symbols.
        runSymbolsCr = huffDec(JPEGenc{cellIndex}.huffStream);
        
        %Get the quantization coefficients from the run length symbols.
        qBlockCr = irunLength(runSymbolsCr, DCpredCr);
        DCpredCr = qBlockCr(1, 1);
        
        %Dequantize each block.
        dctBlockCr = dequantizeJPEG(qBlockCr, JPEGenc{1}.qTableC, JPEGenc{1}.qScale);
        
        %Apply the inverse DCT transformation.
        blockCr = iblockDCT(dctBlockCr);
        
        %Reconstruct image.
        j = JPEGenc{cellIndex}.indHor;
        i = JPEGenc{cellIndex}.indVer;
        
        imageCr(i : i + 7, j : j + 7) = blockCr;
        
        %Update cell index.
        cellIndex = cellIndex + 1;
                
    end
    
    %Convert image to RGB color space.
    imgRec = convert2rgb(imageY, imageCb, imageCr, JPEGenc{1}.subimg);
    
end

