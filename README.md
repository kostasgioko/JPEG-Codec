# JPEG-Codec
A JPEG image encoder/decoder implemented in Matlab for the 'Multimedia Systems' university course.
The compression mode is the Baseline Sequential DCT-based.

# Installation
1) Clone the repository.
2) Open folder in Matlab.

# Usage Example
1) Encode image.
Encode a .mat file containing the image data into a .jpg image with the specified subsampling and quantization scale.

JPEGencStream = JPEGencodeStream('img1_down.mat', [4 4 4], 1);
fileID = fopen('image.jpg', 'w');
fwrite(fileID, JPEGencStream, 'uint8');
fclose(fileID);

2) Decode image.
Decode a .jpg image into a matlab array containing the image data.

fileID = fopen('image.jpg');
JPEGencStreamDec = fread(fileID, 'uint8');
fclose(fileID);
JPEGencStreamDec = JPEGencStreamDec';
imgCmp = JPEGdecodeStream(JPEGencStreamDec);
