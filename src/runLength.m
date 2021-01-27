function runSymbols = runLength(qBlock, DCpred)
    %This function calculates the run length symbols for the quantized DCT coefficients of a block.

    %DC coefficient.
    runSymbols = [0 qBlock(1,1) - DCpred];
    
    %Zig-zag scanning indices.
    I = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 ... 
         49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 ...
         53 60 61 54 47 40 48 55 62 63 56 64];
    
    %Flag to check if the run length gets larger than 15, since it is going to be stored in 4 bits.
    runLengthGreaterThan15 = false; 
    precedingZeros = 0;
    
    %For each element.
    for i = 2 : 64        
        %Check if the run length is larger than 15.
        if precedingZeros > 15
            %Raise the flag.
            runLengthGreaterThan15 = true;
        end
        
        %If the quantization symbol is zero, increase the preceding zeros.
        if qBlock(I(i)) == 0
            precedingZeros = precedingZeros + 1;
        %Otherwise.
        else
           %If the flag was raised. 
           if runLengthGreaterThan15
               %Add zero quantization symbols until the preceding zeros are less than 15.
               while precedingZeros > 15
                   runSymbols = [runSymbols; 15 0];
                   precedingZeros = precedingZeros - 15;
               end
               
               %Then lower the flag.
               runLengthGreaterThan15 = false;
           end            
           
           %Add the non zero quantization symbol and erase the preceding zeros.
           runSymbols = [runSymbols; precedingZeros qBlock(I(i))];
           precedingZeros = 0;
        end
        
    end
    
    %Add End Of Block symbol if the last coefficient was zero.
    if precedingZeros > 0
        runSymbols = [runSymbols; 0 0];
    end
    
end

