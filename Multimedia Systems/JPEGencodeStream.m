function JPEGencStream = JPEGencodeStream(img, subimg, qScale)
    %This function encodes the image and creates a bitstream with the correct syntax, ready to be saved to a binary file.

    %Encode image.
    JPEGenc = JPEGencode(img, subimg, qScale);
        
    %Start Of Image marker.
    SOI = ["FF" "D8"];
    
    JPEGencStream = hex2dec(SOI);
    
    %Table definitions.
    
    %Quantization tables.
    
    %Define quantization table marker.
    DQT = ["FF" "DB"];
    
    JPEGencStream = [JPEGencStream hex2dec(DQT)];
    
    %Quantization table definition length.
    Lq = 132; %Two quantization tables.
    
    JPEGencStream = [JPEGencStream 0 Lq];
    
    %Quantization table for luminance.
    %Quantization element table precision.
    Pq = 0;
    
    %Quantization table destination identifier.
    Tq = 0;
    
    JPEGencStream = [JPEGencStream (Pq * 16 + Tq)];
    
    %Quantization table elements.
    qTableL = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56;
                   14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92;
                   49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
               
    %Since qScale is not part of the protocol, I'll multiply the it with qTable so it is embedded into it.
    qTableL = round(qTableL .* qScale);
    
    %Ziz zag scanning indices.
    I = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 ... 
            49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 ...
            53 60 61 54 47 40 48 55 62 63 56 64];
        
    for i = 1 : 64
       JPEGencStream = [JPEGencStream qTableL(I(i))]; 
    end
    
    %Quantization table for chrominance.
    %Quantization element table precision.
    Pq = 0;
    
    %Quantization table destination identifier.
    Tq = 1;
    
    JPEGencStream = [JPEGencStream (Pq * 16 + Tq)];
    
    %Quantization table elements.
    qTableC = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99;
                     47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99;
                     99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];
                 
    qTableC = round(qTableC .* qScale);
                 
    for i = 1 : 64
       JPEGencStream = [JPEGencStream qTableC(I(i))]; 
    end
    
    %Huffman tables.
    
    %Define Huffman table marker.
    DHT = ["FF" "C4"];
    
    JPEGencStream = [JPEGencStream hex2dec(DHT)];
    
    %Huffman table definition length.
    Lh = [1 162];
    
    JPEGencStream = [JPEGencStream Lh];
    
    %DC Huffman table for luminance.
    %Table class.
    Tc = 0;
    
    %Table destination identifier.
    Th = 0;
    
    JPEGencStream = [JPEGencStream (Tc * 16 + Th)];
    
    %Number of huffman codes of length i.
    L = ["00" "01" "05" "01" "01" "01" "01" "01" "01" "00" "00" "00" "00" "00" "00" "00"];
    
    JPEGencStream = [JPEGencStream hex2dec(L)];
    
    %Values associated with each Huffman code.
    V = ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B"];
    
    JPEGencStream = [JPEGencStream hex2dec(V)];
    
    %DC Huffman table for chrominance.
    %Table class.
    Tc = 0;
    
    %Table destination identifier.
    Th = 1;
    
    JPEGencStream = [JPEGencStream (Tc * 16 + Th)];
    
    %Number of huffman codes of length i.
    L = ["00" "03" "01" "01" "01" "01" "01" "01" "01" "01" "01" "00" "00" "00" "00" "00"];
    
    JPEGencStream = [JPEGencStream hex2dec(L)];
    
    %Values associated with each Huffman code.
    V = ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B"];
    
    JPEGencStream = [JPEGencStream hex2dec(V)];
    
    %AC Huffman table for luminance.
    %Table class.
    Tc = 1;
    
    %Table destination identifier.
    Th = 0;
    
    JPEGencStream = [JPEGencStream (Tc * 16 + Th)];
    
    %Number of huffman codes of length i.
    L = ["00" "02" "01" "03" "03" "02" "04" "03" "05" "05" "04" "04" "00" "00" "01" "7D"];
    
    JPEGencStream = [JPEGencStream hex2dec(L)];
    
    %Values associated with each Huffman code.
    V = ["01" "02" "03" "00" "04" "11" "05" "12" "21" "31" "41" "06" "13" "51" "61" "07" ...
         "22" "71" "14" "32" "81" "91" "A1" "08" "23" "42" "B1" "C1" "15" "52" "D1" "F0" ...
         "24" "33" "62" "72" "82" "09" "0A" "16" "17" "18" "19" "1A" "25" "26" "27" "28" ...
         "29" "2A" "34" "35" "36" "37" "38" "39" "3A" "43" "44" "45" "46" "47" "48" "49" ...
         "4A" "53" "54" "55" "56" "57" "58" "59" "5A" "63" "64" "65" "66" "67" "68" "69" ...
         "6A" "73" "74" "75" "76" "77" "78" "79" "7A" "83" "84" "85" "86" "87" "88" "89" ...
         "8A" "92" "93" "94" "95" "96" "97" "98" "99" "9A" "A2" "A3" "A4" "A5" "A6" "A7" ...
         "A8" "A9" "AA" "B2" "B3" "B4" "B5" "B6" "B7" "B8" "B9" "BA" "C2" "C3" "C4" "C5" ...
         "C6" "C7" "C8" "C9" "CA" "D2" "D3" "D4" "D5" "D6" "D7" "D8" "D9" "DA" "E1" "E2" ...
         "E3" "E4" "E5" "E6" "E7" "E8" "E9" "EA" "F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" ...
         "F9" "FA"];
    
    JPEGencStream = [JPEGencStream hex2dec(V)];
    
    %AC Huffman table for chrominance.
    %Table class.
    Tc = 1;
    
    %Table destination identifier.
    Th = 1;
    
    JPEGencStream = [JPEGencStream (Tc * 16 + Th)];
    
    %Number of huffman codes of length i.
    L = ["00" "02" "01" "02" "04" "04" "03" "04" "07" "05" "04" "04" "00" "01" "02" "77"];
    
    JPEGencStream = [JPEGencStream hex2dec(L)];
    
    %Values associated with each Huffman code.
    V = ["00" "01" "02" "03" "11" "04" "05" "21" "31" "06" "12" "41" "51" "07" "61" "71" ...
         "13" "22" "32" "81" "08" "14" "42" "91" "A1" "B1" "C1" "09" "23" "33" "52" "F0" ...
         "15" "62" "72" "D1" "0A" "16" "24" "34" "E1" "25" "F1" "17" "18" "19" "1A" "26" ...
         "27" "28" "29" "2A" "35" "36" "37" "38" "39" "3A" "43" "44" "45" "46" "47" "48" ...
         "49" "4A" "53" "54" "55" "56" "57" "58" "59" "5A" "63" "64" "65" "66" "67" "68" ...
         "69" "6A" "73" "74" "75" "76" "77" "78" "79" "7A" "82" "83" "84" "85" "86" "87" ...
         "88" "89" "8A" "92" "93" "94" "95" "96" "97" "98" "99" "9A" "A2" "A3" "A4" "A5" ...
         "A6" "A7" "A8" "A9" "AA" "B2" "B3" "B4" "B5" "B6" "B7" "B8" "B9" "BA" "C2" "C3" ...
         "C4" "C5" "C6" "C7" "C8" "C9" "CA" "D2" "D3" "D4" "D5" "D6" "D7" "D8" "D9" "DA" ...
         "E2" "E3" "E4" "E5" "E6" "E7" "E8" "E9" "EA" "F2" "F3" "F4" "F5" "F6" "F7" "F8" ...
         "F9" "FA"];
         
    JPEGencStream = [JPEGencStream hex2dec(V)];
    
    %Frame header.
    
    %Start Of Frame marker - Baseline DCT.
    SOF0 = ["FF" "C0"];
    
    JPEGencStream = [JPEGencStream hex2dec(SOF0)];
    
    %Frame header length.
    Lf = 17;
    
    JPEGencStream = [JPEGencStream 0 Lf];
    
    %Sample precision.
    P = 8;
    
    JPEGencStream = [JPEGencStream P];
    
    %Load image to find its dimensions,.
    image = load(img);
    image = struct2cell(image);
    image = image{1};
    
    %Trim image so the dimensions are divisible by 8.   
    [Y, X, ~] = size(image);
    
    Y = Y - mod(Y, 8);
    X = X - mod(X, 8);
    
    %Number of lines.
    Y = [floor(Y/256) mod(Y, 256)];
    
    JPEGencStream = [JPEGencStream Y];
    
    %Number of samples per line.
    X = [floor(X/256) mod(X, 256)];
    
    JPEGencStream = [JPEGencStream X];
    
    %Number of image components in frame.
    Nf = 3;
    
    JPEGencStream = [JPEGencStream Nf];
    
    if subimg == [4 4 4]
        
        %First component - Y.
        %Component identifier.
        C1 = 1;

        %Sampling factor.
        H1 = 1;
        
        %Vertical sampling factor.
        V1 = 1;
        
        %Quantization table destination selector.
        Tq1 = 0;
        
        %Second component - Cb.
        %Component identifier.
        C2 = 2;

        %Sampling factor.
        H2 = 1;
        
        %Vertical sampling factor.
        V2 = 1;
        
        %Quantization table destination selector.
        Tq2 = 1;
        
        %Third component - Cr.
        %Component identifier.
        C3 = 3;

        %Sampling factor.
        H3 = 1;
        
        %Vertical sampling factor.
        V3 = 1;
        
        %Quantization table destination selector.
        Tq3 = 1;
        
    elseif subimg == [4 2 2]
        
        %First component - Y.
        %Component identifier.
        C1 = 1;

        %Sampling factor.
        H1 = 2;
        
        %Vertical sampling factor.
        V1 = 1;
        
        %Quantization table destination selector.
        Tq1 = 0;
        
        %Second component - Cb.
        %Component identifier.
        C2 = 2;

        %Sampling factor.
        H2 = 1;
        
        %Vertical sampling factor.
        V2 = 1;
        
        %Quantization table destination selector.
        Tq2 = 1;
        
        %Third component - Cr.
        %Component identifier.
        C3 = 3;

        %Sampling factor.
        H3 = 1;
        
        %Vertical sampling factor.
        V3 = 1;
        
        %Quantization table destination selector.
        Tq3 = 1;
        
    elseif subimg == [4 2 0]
        
        %First component - Y.
        %Component identifier.
        C1 = 1;

        %Sampling factor.
        H1 = 2;
        
        %Vertical sampling factor.
        V1 = 2;
        
        %Quantization table destination selector.
        Tq1 = 0;
        
        %Second component - Cb.
        %Component identifier.
        C2 = 2;

        %Sampling factor.
        H2 = 1;
        
        %Vertical sampling factor.
        V2 = 1;
        
        %Quantization table destination selector.
        Tq2 = 1;
        
        %Third component - Cr.
        %Component identifier.
        C3 = 3;

        %Sampling factor.
        H3 = 1;
        
        %Vertical sampling factor.
        V3 = 1;
        
        %Quantization table destination selector.
        Tq3 = 1;
        
    end
    
    JPEGencStream = [JPEGencStream C1 (H1 * 16 + V1) Tq1 C2 (H2 * 16 + V2) Tq2 C3 (H3 * 16 + V3) Tq3];
    
    %Scan header - First scan (Y component).
    
    %Start Of Scan marker.
    SOS = ["FF" "DA"];
    
    JPEGencStream = [JPEGencStream hex2dec(SOS)];
    
    %Scan header length.
    Ls = 8;
    
    JPEGencStream = [JPEGencStream 0 Ls];
    
    %Number of image components in scan.
    Ns = 1;
    
    JPEGencStream = [JPEGencStream Ns];
    
    %Scan component selector.
    Cs = 1;
    
    JPEGencStream = [JPEGencStream Cs];
    
    %DC huffman coding table destination selector.
    Td = 0;
    
    %AC huffman coding table destination selector.
    Ta = 0;
    
    JPEGencStream = [JPEGencStream (16 * Td + Ta)];
    
    %Start of spectral selection.
    Ss = 0;
    
    JPEGencStream = [JPEGencStream Ss];
    
    %End of spectral selection.
    Se = 63;
    
    JPEGencStream = [JPEGencStream Se];
    
    %Successive approximation.
    A = 0;
    
    JPEGencStream = [JPEGencStream A];
    
    %Huffman coded segment.
    
    %Concatenate huffman streams.
    scanHuffStream = [];
    
    cellIndex = 2;
    while strcmp(JPEGenc{cellIndex}.blkType, 'Y')
        
        scanHuffStream = strcat(scanHuffStream, JPEGenc{cellIndex}.huffStream);
        
        cellIndex = cellIndex + 1;
        
    end
    
    %Pad the stream with '1's to make it an integer amount of bytes.
    if mod(length(scanHuffStream), 8) ~= 0
        scanHuffStream = pad(scanHuffStream, length(scanHuffStream) + 8 - mod(length(scanHuffStream), 8), '1');
    end
        
    %Split the stream into bytes.
    for i = 1 : 8 : length(scanHuffStream)
        
        tempByte = scanHuffStream(i : i + 7);
        
        tempByte = bin2dec(tempByte);
                
        JPEGencStream = [JPEGencStream tempByte];
        
        %Byte stuffing.
        if tempByte == 255
            JPEGencStream = [JPEGencStream 0];
        end
    end
    
    %Scan header - Second scan (Cb component).
    
    %Start Of Scan marker.
    SOS = ["FF" "DA"];
    
    JPEGencStream = [JPEGencStream hex2dec(SOS)];
    
    %Scan header length.
    Ls = 8;
    
    JPEGencStream = [JPEGencStream 0 Ls];
    
    %Number of image components in scan.
    Ns = 1;
    
    JPEGencStream = [JPEGencStream Ns];
    
    %Scan component selector.
    Cs = 2;
    
    JPEGencStream = [JPEGencStream Cs];
    
    %DC huffman coding table destination selector.
    Td = 1;
    
    %AC huffman coding table destination selector.
    Ta = 1;
    
    JPEGencStream = [JPEGencStream (16 * Td + Ta)];
    
    %Start of spectral selection.
    Ss = 0;
    
    JPEGencStream = [JPEGencStream Ss];
    
    %End of spectral selection.
    Se = 63;
    
    JPEGencStream = [JPEGencStream Se];
    
    %Successive approximation.
    A = 0;
    
    JPEGencStream = [JPEGencStream A];
    
    %Huffman coded segment.
    
    %Concatenate huffman streams.
    scanHuffStream = [];
    
    while strcmp(JPEGenc{cellIndex}.blkType, 'Cb')
        
        scanHuffStream = strcat(scanHuffStream, JPEGenc{cellIndex}.huffStream);
        
        cellIndex = cellIndex + 1;
        
    end
    
    %Pad the stream with '1's to make it an integer amount of bytes.
    if mod(length(scanHuffStream), 8) ~= 0
        scanHuffStream = pad(scanHuffStream, length(scanHuffStream) + 8 - mod(length(scanHuffStream), 8), '1');
    end
        
    %Split the stream into bytes.
    for i = 1 : 8 : length(scanHuffStream)
        
        tempByte = scanHuffStream(i : i + 7);
        
        tempByte = bin2dec(tempByte);
        
        JPEGencStream = [JPEGencStream tempByte];
        
        %Byte stuffing.
        if tempByte == 255
            JPEGencStream = [JPEGencStream 0];
        end
    end
    
    %Scan header - Second scan (Cr component).
    
    %Start Of Scan marker.
    SOS = ["FF" "DA"];
    
    JPEGencStream = [JPEGencStream hex2dec(SOS)];
    
    %Scan header length.
    Ls = 8;
    
    JPEGencStream = [JPEGencStream 0 Ls];
    
    %Number of image components in scan.
    Ns = 1;
    
    JPEGencStream = [JPEGencStream Ns];
    
    %Scan component selector.
    Cs = 3;
    
    JPEGencStream = [JPEGencStream Cs];
    
    %DC huffman coding table destination selector.
    Td = 1;
    
    %AC huffman coding table destination selector.
    Ta = 1;
    
    JPEGencStream = [JPEGencStream (16 * Td + Ta)];
    
    %Start of spectral selection.
    Ss = 0;
    
    JPEGencStream = [JPEGencStream Ss];
    
    %End of spectral selection.
    Se = 63;
    
    JPEGencStream = [JPEGencStream Se];
    
    %Successive approximation.
    A = 0;
    
    JPEGencStream = [JPEGencStream A];
    
    %Huffman coded segment.
    
    %Concatenate huffman streams.
    scanHuffStream = [];
    
    while cellIndex <= size(JPEGenc, 2)
        
        scanHuffStream = strcat(scanHuffStream, JPEGenc{cellIndex}.huffStream);
        
        cellIndex = cellIndex + 1;
        
    end
    
    %Pad the stream with '1's to make it an integer amount of bytes.
    if mod(length(scanHuffStream), 8) ~= 0
        scanHuffStream = pad(scanHuffStream, length(scanHuffStream) + 8 - mod(length(scanHuffStream), 8), '1');
    end
       
    %Split the stream into bytes.
    for i = 1 : 8 : length(scanHuffStream)
        
        tempByte = scanHuffStream(i : i + 7);
        
        tempByte = bin2dec(tempByte);
        
        JPEGencStream = [JPEGencStream tempByte];
        
        %Byte stuffing.
        if tempByte == 255
            JPEGencStream = [JPEGencStream 0];
        end
        
    end
    
    %End Of Image marker.
    EOI = ["FF" "D9"];
    
    JPEGencStream = [JPEGencStream hex2dec(EOI)];
        
end

