function imgCmp = JPEGdecodeStream(JPEGencStream)
    %This function decodes the image bitstream and reconstructs the image.

    %Bitstream index.
    streamIndex = 1;
    
    %Check for the Start Of Image marker.
    marker = JPEGencStream(streamIndex : streamIndex + 1);
    streamIndex = streamIndex + 2;
    SOI = ["FF" "D8"];
    
    %Stop executing if it isn't found.
    if ( marker(1) ~= hex2dec(SOI(1)) || marker(2) ~= hex2dec(SOI(2)))
        error('No Start Of Image marker found.');        
    end
    
    %Otherwise, find the next marker and process it, until the End Of Image marker is found.
    
    %Markers for supported operations.
    SOF0 = ["FF" "C0"];
    DHT = ["FF" "C4"];
    DQT = ["FF" "DB"];
    SOS = ["FF" "DA"];
    
    %End Of Image marker.
    EOI = ["FF" "D9"];
    
    %Cell for saving the huffman stream for each scan.
    scanHuffStreamData = {};
    
    %Flag for stopping when EOI is found.
    EOIfound = false;
    
    while true
        
        %Read the next two bytes.
        marker = JPEGencStream(streamIndex : streamIndex + 1);
        streamIndex = streamIndex + 2;
        
        %Identify marker.
        %If it is the start of frame marker for Baseline DCT.
        if marker == hex2dec(SOF0)
            
            %Get frame header length
            Lf = JPEGencStream(streamIndex : streamIndex + 1);
            streamIndex = streamIndex + 2;
            Lf = 256 * Lf(1) + Lf(2);
            
            %Skip sample precision, it is 8 bits for Baseline DCT.
            streamIndex = streamIndex + 1; 

            %Get the number of lines of the image.            
            Y = JPEGencStream(streamIndex : streamIndex + 1);
            Y = 256 * Y(1) + Y(2);
            streamIndex = streamIndex + 2;

            %Get the number of samples per line of image.
            X = JPEGencStream(streamIndex : streamIndex + 1);
            X = 256 * X(1) + X(2);
            streamIndex = streamIndex + 2;

            %Get the number of image components in frame.
            %This decoder only supports RGB images converted to YCbCr representation, so Nf is always 3.
            Nf = JPEGencStream(streamIndex);
            streamIndex = streamIndex + 1;

            %Get characteristics for each component.
            componentCharacteristics = zeros(Nf, 4);
            for i = 1 : Nf
                
                %Get the component identifier.
                Ci = JPEGencStream(streamIndex);
                streamIndex = streamIndex + 1;
                
                %Get the horizontaland vertical sampling factor.
                tempByte = JPEGencStream(streamIndex);
                streamIndex = streamIndex + 1;
                Hi = floor(tempByte/16);
                Vi = mod(tempByte, 16);
                
                %Get the quantization table destination selector.
                Tqi = JPEGencStream(streamIndex);
                streamIndex = streamIndex + 1;
                
                %Save to matrix.
                componentCharacteristics(i, :) = [Ci, Hi, Vi, Tqi];
            end
            
            %Find subsampling values.
            Hmax = max(componentCharacteristics(:, 2));
            Vmax = max(componentCharacteristics(:, 3));
            
            %Y component should not be subsampled.
            if (componentCharacteristics(1, 2)  ~= Hmax || componentCharacteristics(1, 3)  ~= Vmax)
                
                error('Unknown subsampling method')
                
            end
            
            %Check if subsampling is 4:4:4.
            if (componentCharacteristics(2, 2)  == Hmax && componentCharacteristics(2, 3)  == Vmax ...
                   && componentCharacteristics(3, 2)  == Hmax && componentCharacteristics(3, 3)  == Vmax)
               
                subimg = [4 4 4];
               
            %Check if subsampling is 4:2:2.
            elseif (componentCharacteristics(2, 2)  == Hmax/2 && componentCharacteristics(2, 3)  == Vmax ...
                      && componentCharacteristics(3, 2)  == Hmax/2 && componentCharacteristics(3, 3)  == Vmax)
                
                subimg = [4 2 2];
            
            %Check if subsampling is 4:2:0.
            elseif (componentCharacteristics(2, 2)  == Hmax/2 && componentCharacteristics(2, 3)  == Vmax/2 ...
                      && componentCharacteristics(3, 2)  == Hmax/2 && componentCharacteristics(3, 3)  == Vmax/2)
                  
                 subimg = [4 2 0];
             
            %Otherwise, the subsampling value is wrong.
            else
                
                error('Unknown subsampling method')
                
            end
                    
        %If it is a huffman table definition marker.
        elseif marker == hex2dec(DHT)
            
            %The construction of the huffman tables is complex, so I just load them when I decode the data.
            %Here I skip the huffman table segment.            
            
            %Get the huffman table definition length.
            Lh = JPEGencStream(streamIndex : streamIndex + 1);
            Lh = 256 * Lh(1) + Lh(2);
            
            %Skip ahead.
            streamIndex = streamIndex + Lh;
        
        %If it is a quantization table definition marker.
        elseif marker == hex2dec(DQT)
            
            %Get the quantization table definition length.
            Lq = JPEGencStream(streamIndex : streamIndex + 1);
            streamIndex = streamIndex + 2;
            Lq = 256 * Lq(1) + Lq(2);
            
            %Find the number of quantization tables.
            numberOfTables = (Lq - 2)/65;
            
            %Form the quantization tables.
            
            %Zig-zag scanning indices.
            I = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 ... 
                49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 ...
                53 60 61 54 47 40 48 55 62 63 56 64];
            
            for i = 1 : numberOfTables
                
                %Get the quantization table destination identifier.
                tempByte = JPEGencStream(streamIndex);
                streamIndex = streamIndex + 1;
                Tq = mod(tempByte, 16);
                
                %Get the elements of the quantization table.
                qTable = zeros(8);
                for j = 1 : 64
                    
                    qTable(I(j)) = JPEGencStream(streamIndex);
                    streamIndex = streamIndex + 1;
                    
                end
                
                %Save the table.
                qTables{Tq + 1} = qTable;
                
            end           
        
        %If it is a start of scan marker.
        elseif marker == hex2dec(SOS)
                        
            %Get scan header length
            Ls = JPEGencStream(streamIndex : streamIndex + 1);
            streamIndex = streamIndex + 2;
            Ls = 256 * Ls(1) + Ls(2);
            
            %Get number of image components in scan (For non interleaved order it is always equal to 1).
            Ns = JPEGencStream(streamIndex);
            streamIndex = streamIndex + 1;
            
            %Get the component selector.
            Cs = JPEGencStream(streamIndex);
            streamIndex = streamIndex + 1;
            
            %Get the DC and AC huffman table destination selectors.
            tempByte = JPEGencStream(streamIndex);
            streamIndex = streamIndex + 1;
            Td = floor(tempByte/16);
            Ta = mod(tempByte, 16);
            
            %The rest of the characteristics are predefined for the Baseline DCT method and can be skipped.
            streamIndex = streamIndex + 3;
            
            %Get the scan data.
            scanHuffStream = [];
            %Keep reading data until a SOS marker is found.
            while ( JPEGencStream(streamIndex) ~= hex2dec(SOS(1)) ||  JPEGencStream(streamIndex + 1) ~= hex2dec(SOS(2)))
                
                %If an EOI marker is found, stop reading from the stream.
                if JPEGencStream(streamIndex : streamIndex + 1) == hex2dec(EOI)
                    EOIfound = true;
                    break;
                end
               
                %Get current data byte.
                tempByte = JPEGencStream(streamIndex);
                streamIndex = streamIndex + 1;
                
                 %Check for stuffed bytes.
                if tempByte == 255
                    streamIndex = streamIndex + 1;
                end
                
                %Convert to binary string.
                tempByte = dec2bin(tempByte, 8);              
                
                %Add to huffman stream.
                scanHuffStream = strcat(scanHuffStream, tempByte);
                
            end
            
            %Save the huffman stream.
            scanHuffStreamData{Cs} = scanHuffStream;
            
            %If the EOI marker is found, break from the outer loop.
            if EOIfound
                break;
            end
       
        %If the End Of Image marker is found before the end of the scan data, the data aren't written correctly.  
        elseif marker == hex2dec(EOI)
            
            %So stop execution.
            error('EOI marker found before the end of the image.');
            
        %If is wrong or a non supported marker, stop the execution.
        else
            error('Unknown marker or a non supported operation found.');
        end
        
    end
    
    %All data has been retrieved, so start decoding the image.
        
    %Load decoding tables.
    global HuffmanDecode_DC_L;
    global HuffmanDecode_DC_C;
    global HuffmanDecode_AC_L;
    global HuffmanDecode_AC_C;
    load('HuffmanDecode_DC_L.mat', 'HuffmanDecode_DC_L');
    load('HuffmanDecode_DC_C.mat', 'HuffmanDecode_DC_C');
    load('HuffmanDecode_AC_L.mat', 'HuffmanDecode_AC_L');
    load('HuffmanDecode_AC_C.mat', 'HuffmanDecode_AC_C');
    
    %Decode first component - Y.
    Cs = componentCharacteristics(1, 1);
    Tq = componentCharacteristics(1, 4);
    
    global isLuminanceBlock;
    isLuminanceBlock = true;
    
    %Decode the whole huffman encoded stream for the component.
    componentHuffStream = scanHuffStreamData{Cs};
        
    %Get run symbols for the whole component.
    componentRunSymbols = componentHuffDec(componentHuffStream);
    
    %Decode the blocks.
    DCpredY = 0;
    lineIndex = 1;
    columnIndex = 1;
    
    for i = 1 : length(componentRunSymbols)
       
        %Get the run length symbols for the block.
        runSymbolsY = componentRunSymbols{i};
        
        %Get the quantization coefficients from the run length symbols.
        qBlockY = irunLength(runSymbolsY, DCpredY);
        DCpredY = qBlockY(1, 1);
        
        %Dequantize each block.
        dctBlockY = dequantizeJPEG(qBlockY, qTables{Tq + 1}, 1);
        
        %Apply the inverse DCT transformation.
        blockY = iblockDCT(dctBlockY);
        
        %Reconstruct image.
        imageY(lineIndex : lineIndex + 7, columnIndex : columnIndex + 7) = blockY;
        
        %Update column index.
        columnIndex = columnIndex + 8;
        
        %If the line is completed update line index and reset column index.
        if columnIndex > X
            lineIndex = lineIndex + 8;
            columnIndex = 1;
        end
        
    end
    
    %Decode second component - Cb.
    Cs = componentCharacteristics(2, 1);
    H = componentCharacteristics(2, 2);
    Tq = componentCharacteristics(2, 4);
    
    isLuminanceBlock = false;
    
    %Decode the whole huffman encoded stream for the component.
    componentHuffStream = scanHuffStreamData{Cs};
        
    %Get run symbols for the whole component.
    componentRunSymbols = componentHuffDec(componentHuffStream);
    
    %Decode the blocks.
    DCpredCb = 0;
    lineIndex = 1;
    columnIndex = 1;
    
    for i = 1 : length(componentRunSymbols)
       
        %Get the run length symbols for the block.
        runSymbolsCb = componentRunSymbols{i};
        
        %Get the quantization coefficients from the run length symbols.
        qBlockCb = irunLength(runSymbolsCb, DCpredCb);
        DCpredCb = qBlockCb(1, 1);
        
        %Dequantize each block.
        dctBlockCb = dequantizeJPEG(qBlockCb, qTables{Tq + 1}, 1);
        
        %Apply the inverse DCT transformation.
        blockCb = iblockDCT(dctBlockCb);
        
        %Reconstruct image.
        imageCb(lineIndex : lineIndex + 7, columnIndex : columnIndex + 7) = blockCb;
        
        %Update column index.
        columnIndex = columnIndex + 8;
        
        %If the line is completed update line index and reset column index.
        if columnIndex > (X * H / Hmax)
            lineIndex = lineIndex + 8;
            columnIndex = 1;
        end
        
    end
    
    %Decode third component - Cr.
    Cs = componentCharacteristics(3, 1);
    H = componentCharacteristics(3, 2);
    Tq = componentCharacteristics(3, 4);
       
    %Decode the whole huffman encoded stream for the component.
    componentHuffStream = scanHuffStreamData{Cs};
    
    %Get run symbols for the whole component.
    componentRunSymbols = componentHuffDec(componentHuffStream);
    
    %Decode the blocks.
    DCpredCr = 0;
    lineIndex = 1;
    columnIndex = 1;
    
    for i = 1 : length(componentRunSymbols)
       
        %Get the run length symbols for the block.
        runSymbolsCr = componentRunSymbols{i};
        
        %Get the quantization coefficients from the run length symbols.
        qBlockCr = irunLength(runSymbolsCr, DCpredCr);
        DCpredCr = qBlockCr(1, 1);
        
        %Dequantize each block.
        dctBlockCr = dequantizeJPEG(qBlockCr, qTables{Tq + 1}, 1);
        
        %Apply the inverse DCT transformation.
        blockCr = iblockDCT(dctBlockCr);
        
        %Reconstruct image.
        imageCr(lineIndex : lineIndex + 7, columnIndex : columnIndex + 7) = blockCr;
        
        %Update column index.
        columnIndex = columnIndex + 8;
        
        %If the line is completed update line index and reset column index.
        if columnIndex > (X * H / Hmax)
            lineIndex = lineIndex + 8;
            columnIndex = 1;
        end
        
    end
        
    %Convert image to RGB color space.
    imgCmp = convert2rgb(imageY, imageCb, imageCr, subimg);
    
end




%This function decodes the whole component huffman stream and saves the run symbols for each block.
function componentRunSymbols = componentHuffDec(huffStream)

    %Global variables.
    global isLuminanceBlock;
    %These cells have the codewords for each code length and their respective categories.
    global HuffmanDecode_DC_L;
    global HuffmanDecode_DC_C;
    global HuffmanDecode_AC_L;
    global HuffmanDecode_AC_C;
    
    %Max code length for the DC coefficient.
    DCCodeMaxLength = 11;
    
    %Max code length for the AC coefficients.
    ACCodeMaxLength = 16;
    
    %This cell holds the run symbols for each block.
    componentRunSymbols = {};
    
    %Keep decoding until the end of the stream is reached.
    streamIndex = 1;
    
    while streamIndex < length(huffStream)
        
        %Start decoding block.
    
        %Decode DC coefficient.
        
        %This flag is used if padded bits at the end of stream are detected, to stop decoding.
        paddedBitsFound = false;

        %This flag is used to stop searching when a code from the stream is identified.
        found = false;
        
        %For each possible code length.
        for i = 2 : DCCodeMaxLength

           %Get the code from the stream.
           %streamIndex
           tempCode = huffStream(streamIndex : streamIndex + i - 1);
           
           %Check if the code is only padded bits.
            if (streamIndex + i - 1 == length(huffStream) && count(tempCode, '1') == length(tempCode))
                %Stop decoding.
                streamIndex = length(huffStream);
                paddedBitsFound = true;
                break;
            end

           %If it is a luminance block.
           if isLuminanceBlock         

               %For each possible codeword.
               for j = 1 : size(HuffmanDecode_DC_L{i}, 1)

                   %If the code is equal to the codeword.
                   if strcmp(tempCode, HuffmanDecode_DC_L{i}{j, 1})

                      %Get the category. 
                      SSSS =  HuffmanDecode_DC_L{i}{j, 2};

                      %If the category isn't zero.
                      if SSSS > 0

                          %The additional bits are the next SSSS bits from the stream.
                          additionalBits = huffStream(streamIndex + i : streamIndex + i + SSSS - 1);

                          %If the value is positive.
                          if strcmp(additionalBits(1), '1')
                              %Convert to decimal.   
                              DIFF = bin2dec(additionalBits);                         

                          %If it is negative.    
                          else
                              %Convert to decimal, complement the number and take the negative.   
                              mask = 2^SSSS - 1;                         
                              DIFF = - bitxor(bin2dec(additionalBits), mask);

                          end

                          %Run symbol for DC coefficient.
                          runSymbols = [0, DIFF];

                          %Since the code has been identified, stop looking.
                          found = true;
                          break;

                      %If the category is zero.    
                      else

                          %The DIFF value is zero.
                          runSymbols = [0 0];

                          %Since the code has been identified, stop looking.
                          found = true;
                          break;

                      end

                   end
               end

           %If it is a chrominance block.    
           else

               %For each possible codeword.
               for j = 1 : size(HuffmanDecode_DC_C{i}, 1)

                   %If the code is equal to the codeword.
                   if strcmp(tempCode, HuffmanDecode_DC_C{i}{j, 1})

                      %Get the category. 
                      SSSS =  HuffmanDecode_DC_C{i}{j, 2};

                      %If the category isn't zero.
                      if SSSS > 0

                          %The additional bits are the next SSSS bits from the stream.
                          additionalBits = huffStream(streamIndex + i : streamIndex + i + SSSS - 1);

                          %If the value is positive.
                          if strcmp(additionalBits(1), '1')
                              %Convert to decimal.   
                              DIFF = bin2dec(additionalBits);                         

                          %If it is negative.    
                          else
                              %Convert to decimal, complement the number and take the negative.   
                              mask = 2^SSSS - 1;                         
                              DIFF = - bitxor(bin2dec(additionalBits), mask);

                          end

                          %Run symbol for DC coefficient.
                          runSymbols = [0, DIFF];

                          %Since the code has been identified, stop searching.
                          found = true;
                          break;

                      %If the category is zero.    
                      else

                          %The DIFF value is zero.
                          runSymbols = [0 0];

                          %Since the code has been identified, stop looking.
                          found = true;
                          break;

                      end

                   end

               end


           end

           %Since the code has been identified, stop searching.
           if found
               break;
           end

        end
        
        %If padded bits are detected, break from the loop.
        if paddedBitsFound
            break;
        end

        %Update stream index.
        streamIndex = streamIndex + i + SSSS;

        %Decode AC coefficients.

        %This flag is used if the End Of Block is found.
        EOBfound = false;

        %This flag is used if padded bits at the end of stream are detected, to stop decoding.
        paddedBitsFound = false;

        %While there is more to decode to form a block.
        while (sum(runSymbols(:, 1)) + sum(runSymbols(:, 2) ~= 0) < 64)

            %Lower the flag;
            found = false;

            %For each possible code length.
            for i = 2 : ACCodeMaxLength

                %Get the code from the stream.
                tempCode = huffStream(streamIndex : streamIndex + i - 1);

                %Check if the code is only padded bits.
                if (streamIndex + i - 1 == length(huffStream) && count(tempCode, '1') == length(tempCode))
                    %Stop decoding.
                    streamIndex = length(huffStream);
                    paddedBitsFound = true;
                    break;
                end

                %If it is a luminance block.
                if isLuminanceBlock         

                    %For each possible codeword.
                    for j = 1 : size(HuffmanDecode_AC_L{i}, 1)

                        %If the code is equal to the codeword.
                        if strcmp(tempCode, HuffmanDecode_AC_L{i}{j, 1})

                            %Get the run length and category.
                            runLength = hex2dec(HuffmanDecode_AC_L{i}{j, 2});
                            SSSS = hex2dec(HuffmanDecode_AC_L{i}{j, 3});

                            %If the category isn't zero.
                            if SSSS > 0
                                %The additional bits are the next SSSS bits from the stream.
                                additionalBits = huffStream(streamIndex + i : streamIndex + i + SSSS - 1);

                                %If the value is positive.
                                if strcmp(additionalBits(1), '1')
                                    %Convert to decimal.   
                                    symbol = bin2dec(additionalBits);                         

                                %If it is negative.    
                                else
                                    %Convert to decimal, complement the number and take the negative.   
                                    mask = 2^SSSS - 1;                         
                                    symbol = - bitxor(bin2dec(additionalBits), mask);

                                end

                                %Add the run symbol.
                                runSymbols = [runSymbols; runLength symbol];

                            %If the category is zero.
                            else

                                %The quantization symbol is zero. so add the run symbol.
                                runSymbols = [runSymbols; runLength 0];

                                %If the run length is also zero, EOB is reached.
                                if runLength == 0
                                    %Update stream index.
                                    streamIndex = streamIndex + i;
                                    
                                    %Raise flag.
                                    EOBfound = true;
                                    break;
                                end

                            end

                            %Since the code has been identified, stop searching.
                            found = true;
                            break;

                        end

                    end

                    %If EOB is reached stop searching.
                    if EOBfound
                        break;
                    end

                %If it is a chrominance block.    
                else

                    %For each possible codeword.
                    for j = 1 : size(HuffmanDecode_AC_C{i}, 1)

                        %If the code is equal to the codeword.
                        if strcmp(tempCode, HuffmanDecode_AC_C{i}{j, 1})

                            %Get the run length and category.
                            runLength = hex2dec(HuffmanDecode_AC_C{i}{j, 2});
                            SSSS = hex2dec(HuffmanDecode_AC_C{i}{j, 3});

                            %If the category isn't zero.
                            if SSSS > 0
                                %The additional bits are the next SSSS bits from the stream.
                                additionalBits = huffStream(streamIndex + i : streamIndex + i + SSSS - 1);

                                %If the value is positive.
                                if strcmp(additionalBits(1), '1')
                                    %Convert to decimal.   
                                    symbol = bin2dec(additionalBits);                         

                                %If it is negative.    
                                else
                                    %Convert to decimal, complement the number and take the negative.   
                                    mask = 2^SSSS - 1;                         
                                    symbol = - bitxor(bin2dec(additionalBits), mask);

                                end

                                %Add the run symbol.
                                runSymbols = [runSymbols; runLength symbol];

                            %If the category is zero.    
                            else

                                %The quantization symbol is zero. so add the run symbol.
                                runSymbols = [runSymbols; runLength 0];
                                
                                %If the run length is also zero, EOB is reached.
                                if runLength == 0
                                    %Update stream index.
                                    streamIndex = streamIndex + i;
                                    
                                    %Raise flag.
                                    EOBfound = true;
                                    break;
                                end

                            end

                            %Since the code has been identified, stop searching.
                            found = true;
                            break;

                        end

                    end
                    
                    %If EOB is reached stop searching.
                    if EOBfound
                        break;
                    end

                end

                %Since the code has been identified, stop searching.
                if found
                    break;
                end

            end

            %If EOB is reached, break from the loop..
            if EOBfound
                break;
            end

            %If padded bits are detected, break from the loop.
            if paddedBitsFound
                break;
            end

            %Update stream index.
            streamIndex = streamIndex + i + SSSS;

        end
        
        %Add run symbols for block.
        componentRunSymbols{end + 1} = runSymbols;
        
    end
end