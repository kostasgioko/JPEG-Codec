function dctBlock = blockDCT(block)
    %This function applies the DCT transformation to an 8x8 block of the image.

    %Before the conversion, the samples are shifted by subtracting 128 according to the protocol.
    block = int16(block);
    block = block - 128;

    %Apply the DCT transformation to the block.
    dctBlock = dct2(block);

end