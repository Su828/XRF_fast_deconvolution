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

clc; close all; clear all;
addpath(genpath('tool_functions'))

%% load the parameters from pre_processing
para_file = 'dataset/R117_pre_para_fast_global.mat';
load(para_file)

%% parameter settings
para.flags.load_data_flag = 1;
para.flags.parfor_flag = 1; % if use parallel computing to speed up
para.flags.plot_flag = 1;
para.flags.save_flag = 1;
para.flags.show_loss_flag = 1;

para.max_window_use = 15; % the index of windows interested to deconvolve
para.detect_para.K_max = 18; % max number of pulses within a window
para.detect_para.K_min = 1; % min number of pulses within a window 

para.enhance_element_No = []; % function to be updated

%% load MA-XRF data
if para.flags.load_data_flag
    para.data_type = 'raw'; % data type should be either 'edf' or 'raw'
    para.size_1 = 4096; % channel length
    para.size_2 = 414;
    para.size_3 = 302;
    para.filter_size = 3; % spatial average filter size
    
    try
        [para, data_cube] = data_loader(para);
        average_spectrum = mean(data_cube,[2,3]);
        maximum_spectrum = max(data_cube,[],[2,3]);
        disp('Data loaded!');
    catch error_reason
        warning('Failed to load data!');
        rethrow(error_reason)
    end
end

%% FRI-based element detection on average and maximum spectrum

try
    [para,FRI_results] = element_detection_ave_max(para,average_spectrum,maximum_spectrum);
    disp('FRI-based element detection completed!');
catch error_reason
    warning('FRI-based element detection failed!');
    rethrow(error_reason)
end

%% Fast deconvolution
para.lambda_TV = 0.2;
para.rho_TV_loss = 1;
para.sparse_coef = 0.0005;
para.learning_rate = 1;
para.decon_iter = 50;

try
    [para,decon_results] = fast_deconvolution_FISTA(para,data_cube,FRI_results,maximum_spectrum,back_noise);
    disp('XRF deconvolution completed!');
catch error_reason
    warning('XRF deconvolution failed!');
    rethrow(error_reason)
end

%% save the para
if para.flags.save_flag
    save([para.folder_name,para.file_name,'_decon_results_',para.decon_method,'.mat'],'para',...
        'maximum_spectrum','back_noise','spectrum_denoised','average_spectrum','FRI_results','decon_results')
end
