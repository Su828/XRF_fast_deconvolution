% Code (c) Su Yan, Imperial College London, 01 July 2024
% s.yan18@imperial.ac.uk

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

clc;close all;clear all;

%% load the preprocessed parameters
result_file = 'dataset/R117_decon_results_fast_global.mat';
load(result_file)

%% display the elemental maps
view_para.atomic_No_view = 30; % select the Atomic Number of an element to view
view_para.lines_chosen = [1 2 3 4 5 6 7]; % select the element lines to view
% set the maximum threshold for displaying an elemental map
view_para.max_value=[inf inf inf inf inf inf inf]; 
% set the minimum threshold for displaying an elemental map
view_para.min_value=[0 0 0 0 0 0 0];
view_para.line_names={'K-alpha','K-beta','L-l','L-alpha','L-beta','L-gamma','M-alpha'};

try
    view_para = view_fast_decon_maps(para,view_para,decon_results);
    disp(sprintf(['Viewing elemental maps of ', view_para.element_name, ...
        ' %d'],view_para.atomic_No_view));
catch error_reason
    warning('Failed to display elemental maps!');
    rethrow(error_reason)
end

