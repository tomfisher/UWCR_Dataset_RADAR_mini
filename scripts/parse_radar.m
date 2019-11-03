%%% This script is used to read the binary file produced by the AWR1843/1642 and DCA1000
%%% and Mmwave Studio
%%% Command to run in Matlab GUI -readDCA1000('<ADC capture bin file>') 

%%% function name: readDCA1000
%%% input: The folder location of file to be read, the ADC samples in one chirp
%%% output: The raw ADC data 2D matrix, the first dimension represnts Rxs,
%%%         the second dimension represents chirps


function [retVal] = readDCA1000(folder_locaion, numADCSamples)
%% global variables
% change based on sensor config
% numADCSamples = 128; % number of ADC samples per chirp should be variable
numADCBits = 16; % number of ADC bits per sample
numRX = 4; % number of receivers
numLanes = 2; % do not change. number of lanes is always 2
isReal = 0; % set to 1 if real only data, 0 if complex data0
adcData = [];
%% read file
% search all files under this folder
files = dir(folder_locaion); % find all the files under the folder
n_files = length(files);
processed_files = [3:n_files];

for index = 1:length(processed_files)
    inum = processed_files(index);
    file_name = files(inum).name;
    file_location = strcat(folder_locaion,'/',file_name);
    % read .bin file
    fid = fopen(file_location,'r');
    adcData_tmp = fread(fid, 'int16');
    adcData = [adcData; adcData_tmp];
end

% if 12 or 14 bits ADC per sample compensate for sign extension
if numADCBits ~= 16
    l_max = 2^(numADCBits-1)-1;
    adcData(adcData > l_max) = adcData(adcData > l_max) - 2^numADCBits;
end
fclose(fid);
fileSize = size(adcData, 1);
% real data reshape, filesize = numADCSamples*numChirps
if isReal
    numChirps = fileSize/numADCSamples/numRX;
    LVDS = zeros(1, fileSize);
    %create column for each chirp
    LVDS = reshape(adcData, numADCSamples*numRX, numChirps);
    %each row is data from one chirp
    LVDS = LVDS.';
else
    % for complex data
    % filesize = 2 * numADCSamples*numChirps
    numChirps = fileSize/2/numADCSamples/numRX;
    LVDS = zeros(1, fileSize/2);
    %combine real and imaginary part into complex data
    %read in file: 2I is followed by 2Q
    counter = 1;
    for i=1:4:fileSize-1
        LVDS(1,counter) = adcData(i) + sqrt(-1)*adcData(i+2);
        LVDS(1,counter+1) = adcData(i+1)+sqrt(-1)*adcData(i+3);
        counter = counter + 2;
    end
    % create column for each chirp
    LVDS = reshape(LVDS, numADCSamples*numRX, numChirps);
    %each row is data from one chirp
    LVDS = LVDS.';
end
%organize data per RX
adcData = zeros(numRX,numChirps*numADCSamples);
for row = 1:numRX
    for i = 1: numChirps
        adcData(row, (i-1)*numADCSamples+1:i*numADCSamples) = LVDS(i,(row-1)*numADCSamples+1:row*numADCSamples);
    end
end
% return receiver data
% data format is [Rx; chirps]
retVal = adcData;
