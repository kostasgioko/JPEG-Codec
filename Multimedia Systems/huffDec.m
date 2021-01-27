function runSymbols = huffDec(huffStream)
    %This function decodes the encoded bit stream and returns the run length symbols.

    %Global variables.
    global isLuminanceBlock;
    %These cells have the codewords for each code length and their respective categories.
    global HuffmanDecode_DC_L;
    global HuffmanDecode_DC_C;
    global HuffmanDecode_AC_L;
    global HuffmanDecode_AC_C;
    
    %Decode DC coefficient.
    
    %This flag is used to stop searching when a code from the stream is identified.
    found = false;   
        
    %Max code length for the DC coefficient.
    DCCodeMaxLength = 11;
    
    streamIndex = 1;    
    %For each possible code length.
    for i = 2 : DCCodeMaxLength
       
       %Get the code from the stream.
       tempCode = huffStream(streamIndex : streamIndex + i - 1);
       
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
    
    %Update stream index.
    streamIndex = streamIndex + i + SSSS;
    
    %Decode AC coefficients.
    
    %Max code length for the AC coefficients.
    ACCodeMaxLength = 16;
    
    %This flag is used if the End Of Block is found.
    EOBfound = false;
    
    %This flag is used if padded bits at the end of stream are detected, to stop decoding.
    paddedBitsFound = false;
    
    %While there is more to decode.
    while streamIndex < length(huffStream)
        
        %Lower the flag;
        found = false;
        
        %For each possible code length.
        for i = 2 : ACCodeMaxLength
            
            %Get the code from the stream.
            tempCode = huffStream(streamIndex : streamIndex + i - 1);
            
            %Check if the code is only padded bits.
            if (streamIndex + i - 1 == length(huffStream) && count(tempCode, '1') == length(tempCode))
                %Stop decoding.
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
                            
                        end
                        
                        %Since the code has been identified, stop searching.
                        found = true;
                        break;
                        
                    end
                    
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
end