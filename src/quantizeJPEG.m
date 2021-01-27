function qBlock = quantizeJPEG(dctBlock, qTable, qScale)
    %This function quantizes a DCT block of the image.
    
    %Divide each element of the block with the corresponding quantization value, then with the quantization scale and round the result.
    qBlock = round(dctBlock ./ qTable ./ qScale);
    
end