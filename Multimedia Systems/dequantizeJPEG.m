function dctBlock = dequantizeJPEG(qBlock, qTable, qScale)
    %This function dequantizes quantized DCT block of the image.    
    
    %Multiply each element of the block with the corresponding quantization value, and then with the quantization scale.
    dctBlock = qScale .* qTable .* qBlock;
    
end