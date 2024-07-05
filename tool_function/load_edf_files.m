% Code (c) Su Yan, Imperial College London, 17 November 2022
% s.yan18@imperial.ac.uk

function [para,data_cube]=load_edf_files(para)

% A function used to read '*.edf' files created by 'DataMuncher' software.

% Once calling the function, a dialog box will pop up to select the '*.edf'
% files, which allows single or multiple files to be selected.

% The input parameters (Dim_1, Dim_2) can be found from any of the 
% '*.edf' files opened with 'Notepad'.
%   For example: 
%       Dim_1=4096;
%       Dim_2=1391;

% This is in part of the EPSRC-funded ARTICT (Art Through the ICT Lens: Big
% Data Processing Tools to Support the Technical Study, Preservation and
% Conservation of Old Master Paintings​) project (EP/R032785/1). 
% More information: https://art-ict.github.io/artict/home.html

% If you use our code, please cite the following papers:

% S. Yan, J.J. Huang, H. Verinaz-Jadan, N. Daly, C. Higgitt, and P.L. Dragotti, 
% "A fast automatic method for deconvoluting macro X-ray fluorescence data 
% collected from easel paintings," IEEE Transactions on Computational Imaging, 
% vol. 9, pp. 649-664, 2023.

% S. Yan, J.J. Huang, N. Daly, C. Higgitt, and P.L. Dragotti, "When de
% Prony Met Leonardo: An Automatic Algorithm for Chemical Element
% Extraction From Macro X-Ray Fluorescence Data," IEEE Transactions on
% Computational Imaging, vol. 7, pp. 908–924, 2021.

% S. Yan, J.J. Huang, N. Daly, C. Higgitt, and P.L. Dragotti, "Revealing
% Hidden Drawings in Leonardo s  the Virgin of the Rocks’ from Macro X-Ray
% Fluorescence Scanning Data through Element Line Localisation," in ICASSP
% 2020-2020 IEEE International Conference on Acoustics, Speech and Signal
% Processing (ICASSP). IEEE, 2020, pp. 1444–1448.

Dim_1 = para.size_1;
Dim_2 = para.size_2;
Size = Dim_1*Dim_2;

[load_file_name,load_path,~] = uigetfile('*.edf','MultiSelect','on');

if iscell(load_file_name)
    row_num=length(load_file_name);
    data_cube=zeros(Dim_1,Dim_2,row_num);
    for i=1:row_num
        fileID  = fopen([load_path, load_file_name{i}],'r');
        data_cube_slice = fread(fileID);
        data_cube_slice=reshape(data_cube_slice(end-Size+1:end),[Dim_1,Dim_2]);
        data_cube(:,:,i)=data_cube_slice;
        fclose(fileID);
    end
else
    data_cube=zeros(Dim_1,Dim_2);
    fileID  = fopen([load_path, load_file_name],'r');
    data_cube_slice = fread(fileID);
    data_cube_slice=reshape(data_cube_slice(end-Size+1:end),[Dim_1,Dim_2]);
    data_cube=data_cube_slice;
    fclose(fileID);
end
data_cube = single(data_cube);
idx = strfind(open_file_name, '.edf');
para.file_name = open_file_name(1:(idx-1));
para.folder_name = load_path;
