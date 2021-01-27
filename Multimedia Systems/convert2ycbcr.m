function [imageY, imageCb, imageCr] = convert2ycbcr(imageRGB, subimg)
    %This function converts an RGB image to YCbCr color space and then subsamples it.  
    
    %Initialize arrays.
    [N, M, ~] = size(imageRGB);
    imageY = zeros(N, M, 'uint8');
    imageCb = zeros(N, M, 'uint8');
    imageCr = zeros(N, M, 'uint8'); 
    
    %Convert RGB image to YCbCr color space.
    for i = 1 : N
        for j = 1 : M
           imageY(i,j) = 0.299 * imageRGB(i, j, 1) + 0.587 * imageRGB(i, j, 2) + 0.114 * imageRGB(i, j, 3);
           imageCb(i,j) = 128 - 0.168736 * imageRGB(i, j, 1) - 0.331264 * imageRGB(i, j, 2) + 0.5 * imageRGB(i, j, 3);
           imageCr(i,j) = 128 + 0.5 * imageRGB(i, j, 1) - 0.418688 * imageRGB(i, j, 2) - 0.081312 * imageRGB(i, j, 3);
        end
    end
    
    %Subsample image.
    
    %4:4:4 subsampling.
    if subimg == [4 4 4]
        
        %No subsampling.
    
    %4:2:2 subsampling.
    elseif subimg == [4 2 2]
        
        %Keep half of the columns for Cb and Cr.
        imageCb = imageCb(:, 1:2:M);
        imageCr = imageCr(:, 1:2:M);
    
    %4:2:0 subsampling.
    elseif subimg == [4 2 0]
        
        %Keep half of the columns and half of the lines for Cb and Cr.
        imageCb = imageCb(1:2:N, 1:2:M);
        imageCr = imageCr(1:2:N, 1:2:M);
        
    else        
        error("Unknown subsampling method.")
    end

end