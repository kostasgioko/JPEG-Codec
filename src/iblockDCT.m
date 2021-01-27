function block = iblockDCT(dctBlock)
    %This function applies the inverse DCT transformation to an 8x8 DCT transformed block of the image.

    %Apply the inverse DCT transformation to the block.
    block = idct2(dctBlock);

    %Shift the samples by adding 128 according to the protocol.
    block = block + 128;
    block = uint8(block);
    
end