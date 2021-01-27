function imageRGB = convert2rgb(imageY, imageCb, imageCr, subimg)
    %This function upsamples a YCbCr image and then converts it to RGB color space.

    %Initialize arrays.
    [N, M] = size(imageY);
    
    imageR = zeros(N, M, 'int32');
    imageG = zeros(N, M, 'int32');
    imageB = zeros(N, M, 'int32');
    
    imageY = int32(imageY);
    imageCb = int32(imageCb);
    imageCr = int32(imageCr);

    %Upsample image.
    
    %If subsampling was 4:4:4.
    if subimg(1) == 4 && subimg(2) == 4 && subimg(3) == 4
       
        %No upsampling.
        imageYCbCr = cat(3, imageY, imageCb, imageCr);
    
    %If subsampling was 4:2:2.    
    elseif subimg(1) == 4 && subimg(2) == 2 && subimg(3) == 2
        
        %Double the columns for Cb and Cr.
        imageCb = imresize(imageCb, [N, M], 'bilinear');
        imageCr = imresize(imageCr, [N, M], 'bilinear');
        
        imageYCbCr = cat(3, imageY, imageCb, imageCr);
    
    %If subsampling was 4:2:0.    
    elseif subimg(1) == 4 && subimg(2) == 2 && subimg(3) == 0
        
        %Double the columns and lines for Cb and Cr.
        imageCb = imresize(imageCb, 2, 'bilinear');
        imageCr = imresize(imageCr, 2, 'bilinear');
        
        imageYCbCr = cat(3, imageY, imageCb, imageCr);
    else        
        error("Unknown subsampling method.")        
    end
    
    %Convert YCbCr image to RGB color space.
    for i = 1 : N
        for j = 1 : M
            
            imageR(i, j) = imageYCbCr(i, j, 1) + 1.402 * (imageYCbCr(i, j, 3) - 128);
            imageG(i, j) = imageYCbCr(i, j, 1) - 0.344136 * (imageYCbCr(i, j, 2) - 128) - 0.714136 * (imageYCbCr(i, j, 3) - 128);
            imageB(i, j) = imageYCbCr(i, j, 1) + 1.772 * (imageYCbCr(i, j, 2) - 128);
            
        end
    end
    
    imageRGB = cat(3, imageR, imageG, imageB);
    imageRGB = uint8(imageRGB);
end