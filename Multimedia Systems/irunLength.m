function qBlock = irunLength(runSymbols, DCpred)
    %This function forms the DCT quantized block from the run length symbols.

    %Initialize block.
    qBlock = zeros(8);

    %DC coefficient.
    qBlock(1, 1) = runSymbols(1, 2) + DCpred;
    
    %Zig-zag scanning indices.
    I = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 ... 
         49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 ...
         53 60 61 54 47 40 48 55 62 63 56 64];
    
    %Element index. 
    i = 2;
    %For each symbol.
    for k = 2 : size(runSymbols, 1)
        %If it is the End Of Block symbol, then break from the loop.
        if (runSymbols(k, 1) == 0 && runSymbols(k, 2) == 0)
            break;
        end
        
        %Otherwise add the correct amount of zeros to the block.
        preceedingZeros = runSymbols(k, 1);            
        while preceedingZeros > 0
            
            qBlock(I(i)) = 0;
            preceedingZeros = preceedingZeros - 1;
            i = i + 1;
            
        end
        
        %if the quantization symbol was non zero, add it to the block.
        if runSymbols(k, 2) ~= 0

            qBlock(I(i)) = runSymbols(k, 2);
            i = i + 1;
            
        end
       
    end
end

