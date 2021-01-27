function huffStream = huffEnc(runSymbols)
    %This function encodes the run length symboles into a bit stream using Huffman Coding.

    %Global variables.
    global isLuminanceBlock;
    global F1;
    global F2;
    global K3;
    global K4;
    global K5;
    global K6;
    
    %Initialize stream.
    huffStream = [];
    
    %Encode DC coefficient.
    
    %Difference between DC coefficient and prediction.
    DIFF = runSymbols(1, 2);
    
    %For each category.
    for i = 1 : size(F1, 1)
        
        %Check if the difference is in the category's positive interval.
        if (DIFF >= F1.DIFF_values(i, 1) && DIFF <= F1.DIFF_values(i, 2))            
            %Category number.
            SSSS = F1.SSSS(i);            
            
            %If it is a luminance block.
            if isLuminanceBlock
                %Get the codeword from Table K3 from the correct category.
                code = K3.Codeword{SSSS + 1};
                
                %If the catefory isn't zero.
                if SSSS > 0
                    %Append the value of the difference to the code.
                    code = append(code, dec2bin(DIFF));
                end
                
            %If it is a chrominance block.    
            else
                %Get the codeword from Table K4 from the correct category.
                code = K4.Codeword{SSSS + 1};
                
                %If the catefory isn't zero.
                if SSSS > 0
                    %Append the value of the difference to the code.
                    code = append(code, dec2bin(DIFF));
                end
            end
            
            %Break from the loop, since the category has been found.
            break;
            
        %Check if the difference is in the category's negative interval.
        elseif (DIFF >= - F1.DIFF_values(i, 2) && DIFF <= - F1.DIFF_values(i, 1))
            %Category number.
            SSSS = F1.SSSS(i);            
            
            %If it is a luminance block.
            if isLuminanceBlock
                %Get the codeword from Table K3 from the correct category.
                code = K3.Codeword{SSSS + 1};
                
                %If the catefory isn't zero.
                if SSSS > 0
                    %Since the difference value is negative, the complement of its absolute value is appended to the end of the code.
                    mask = 2^SSSS - 1;
                    code = append(code, dec2bin(bitxor(abs(DIFF), mask), SSSS));
                end
                
            %If it is a chrominance block.
            else
                %Get the codeword from Table K4 from the correct category.
                code = K4.Codeword{SSSS + 1};
                
                %If the catefory isn't zero.
                if SSSS > 0
                    %Since the difference value is negative, the complement of its absolute value is appended to the end of the code.
                    mask = 2^SSSS - 1;
                    code = append(code, dec2bin(bitxor(abs(DIFF), mask), SSSS));
                end
            end
            
            %Break from the loop, since the category has been found.
            break;
        end
        
    end
    
    %Append the code to the stream.
    huffStream = [huffStream code];
    
    %Encode AC coefficients.
    
    %For each run symbol.
    for i = 2 : size(runSymbols, 1)
        
        %Get the run length and the quantization symbol.
        runLength = runSymbols(i, 1);
        symbol = runSymbols(i, 2);
        
        %Check for End Of Block symbol.
        if (runLength == 0 && symbol == 0)
           %If it is a luminance block. 
           if isLuminanceBlock
               %Get the EOB codeword from Table K5.
               code = K5.CodeWord{1};
           %If it is a chrominance block.       
           else
               %Get the EOB codeword from Table K6.
               code = K6.CodeWord{1};
           end
           
           %Append the code to the stream.
           huffStream = [huffStream code];
           
           %Break from the loop, since there are no more run symbols.
           break;
           
        %Check if the quantization symbol is zero.   
        elseif symbol == 0
           
           %If it is a luminance block. 
           if isLuminanceBlock
               %Get the ZRL codeword from Table K5.
               code = K5.CodeWord{runLength * 10 + 2};
           %If it is a chrominance block.       
           else
               %Get the ZRL codeword from Table K6.
               code = K6.CodeWord{runLength * 10 + 2};
           end 
        
        %Otherwise it is a normal run symbol.
        else
            
            %For each category.
            for j = 1 : size(F2, 1)

               %Check if the quantization symbol is in the category's positive interval. 
               if (symbol >= F2.AC_coefficients(j, 1) && symbol <= F2.AC_coefficients(j, 2))
                  %Category number.
                  SSSS = F2.SSSS(j);
                  
                  %Calculate table index.
                  if runLength < 15
                      index = runLength * 10 + SSSS + 1;
                  else
                      index = runLength * 10 + SSSS + 2;
                  end 

                  %If it is a luminance block.
                  if isLuminanceBlock
                      %Get the codeword from Table K5 from the correct category.
                      code = K5.CodeWord{index};
                      
                      %Append the value of the quantization symbol to the code.
                      code = append(code, dec2bin(symbol));
                      
                  %If it is a chrominance block.
                  else
                      %Get the codeword from Table K6 from the correct category.
                      code = K6.CodeWord{index};
                      
                      %Append the value of the quantization symbol to the code.
                      code = append(code, dec2bin(symbol));
                  end
                  
                  %Break from the loop, since the category has been found.
                  break;
               
               %Check if the difference is in the category's negative interval.
               elseif (symbol <= - F2.AC_coefficients(j, 1) && symbol >= - F2.AC_coefficients(j, 2))
                   %Category number.
                   SSSS = F2.SSSS(j);
                    
                   %Calculate table index.
                   if runLength < 15
                       index = runLength * 10 + SSSS + 1;
                   else
                       index = runLength * 10 + SSSS + 2;
                   end
        
                   %If it is a luminance block.
                   if isLuminanceBlock
                      %Get the codeword from Table K5 from the correct category. 
                      code = K5.CodeWord{index};
                      
                      %Since the quantization symbol is negative, the complement of its absolute value is appended to the end of the code.
                      mask = 2^SSSS - 1;
                      code = append(code, dec2bin(bitxor(abs(symbol), mask), SSSS));
                      
                   %If it is a chrominance block.    
                   else
                      %Get the codeword from Table K6 from the correct category. 
                      code = K6.CodeWord{index};
                      
                      %Since the quantization symbol is negative, the complement of its absolute value is appended to the end of the code.
                      mask = 2^SSSS - 1;
                      code = append(code, dec2bin(bitxor(abs(symbol), mask), SSSS));
                   end

                   %Break from the loop, since the category has been found.
                   break;
               end

            end
           
        end      
                
        %Append the code to the stream.
        huffStream = [huffStream code];
        
    end
        
end

