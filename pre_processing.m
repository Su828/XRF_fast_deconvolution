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

%% Parameters in para
para = [];
para.flags = [];
addpath(genpath('tool_functions'))

para.decon_method = 'fast_global'; % 'FAD': fast global method or 'AFRID': pixel-wise method
para.flags.plot_flag = 1;
para.flags.save_flag = 1;

switch para.decon_method
    case 'fast_global'
        disp('Pre-processing for Fast Automatic Deconvolution (FAD) Method...')
    case 'FRI_pixel'
        disp('Pre-processing for Automatic FRI-based Deconvolution (AFRID) Method...')
end

%% load MA-XRF data
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

%% fit the reference pulse with a gaussian
% (the 1st peak in the spectrum is recommended)
para.ref_pulse_region = [65,125]; % the channel region of the reference peak

try
    para = fit_Gaussian_to_reference_pulse(para,average_spectrum);
    disp('Reference pulse estimation completed!');
catch error_reason
    warning('Reference pulse estimation failed!');
    rethrow(error_reason)
end

%% energy to channel calibration
para.channel_input = [95.5, 465, 735, 900, 1358];
para.energy_input = [0, 3690, 6399.507, 8041.13, 12613.7];

try
    para = energy_channel_calibration(para);
    disp('Energy to channel calibration completed!');
catch error_reason
    warning('Energy to channel calibration failed!');
    rethrow(error_reason)
end

%% genereate element characteristic energy and channel Map
para.atomic_No_interesed = [13 14 15 16 17 18 19 20 22 23 ...
    24 25 26 27 28 29 30 33 34 35 38 ...
    45 47 48 50 51 53 56 79 80 82 83];

try
    para = Create_element_channel_maps_without_fitting(para);
    disp('Element characteristic maps generated!');
catch error_reason
    warning('Failed to generate element characteristic maps!');
    rethrow(error_reason)
end

%% remove background noise
para.denoise_iter = 25; % default 25
para.denoise_width = 10*para.ref_pulse_FWHM;

try
    [para, spectrum_denoised, back_noise] = remove_background_noise_spectrum(para,average_spectrum);
    disp('Background noise removed!');
catch error_reason
    warning('Failed to remove background noise!');
    rethrow(error_reason)
end

%% estimate pulse width adjustment coefficient
para.peaks_to_fit = {[466,498], [637], [736,745], [789,800], ...
    [1141,1151]};
para.regions_to_fit = {[439,520], [603,665], [713,769], [769,832], ...
    [1120,1202]};

try
    para = estimate_pulse_width_adjustment_coefficient(para,spectrum_denoised);
    disp('Pulse width adjustment coefficient estimated!');
catch error_reason
    warning('Failed to estimate pulse width adjustment coefficient!');
    rethrow(error_reason)
end

%% generate pulse widths for sliding windows
% try the default values ​​for these parameters first
para.window_size = 300;
para.window_shifted = para.window_size/2;
para.confidence_interval_width = 75;
para.pulse_para = [];
para.pulse_para.P_max = 65; % max order of B-spline
para.pulse_para.P_min = 35; % min order of B-spline
para.pulse_para.T_max = 8; % max scale factor
para.pulse_para.T_s = 1/100; % time resulotion
para.pulse_para.P = 200-1; % number of exponentials generated, also the number of the samples taken from frequency domain
para.pulse_para.alpha_traget = -0.35; % normal range [-0.25, -0.4]
para.pulse_para.phi_mode='causal';

try
    para = generate_pulse_widths(para);
    disp('Pulse widths generated!');
catch error_reason
    warning('Failed to generate pulse widths!');
    rethrow(error_reason)
end

%% estimate pulse detection uncertainty
% try the default values ​​for these parameters first
para.pulse_para.CRLB_scale_factor = 13;
para.pulse_para.uncertainty_intervals = [3.5 10.5];

try
    para = estimate_pulse_detection_uncertainty(para);
    disp('Pulse detection uncertainty estimated!');
catch error_reason
    warning('Failed to estimate pulse detection uncertainty!');
    rethrow(error_reason)
end

%% adjust the window regions if needed (optional step)
para.pulse_para.window_start_idx = [2 4 6 7 8 9 10 11 13 14 15];
para.pulse_para.window_start = [220 520 762 885 1030 1190 1320 1420 1785 1900 2080];
para.pulse_para.window_end_idx = [2 4 5 6 7 8 9 11 12 13];
para.pulse_para.window_end = [520 762 885 1030 1190 1420 1539 1785 2050 2080];

try
    para = adjust_window_region(para);
    disp('Window regions adjusted!');
catch error_reason
    warning('Failed to adjust window regions!');
    rethrow(error_reason)
end

%% initialise FRI pulse detection
% try the default values ​​for these parameters first
para.detect_para = [];
para.detect_para.noise_threshold_FRI = 1;
para.detect_para.noise_threshold_LS = 1;
para.detect_para.noise_threshold_min = 0.3;
para.detect_para.noise_threshold_FRI_ave = 0.1;
para.detect_para.noise_threshold_LS_ave = 0.1;
para.detect_para.noise_threshold_min_ave = 0.1;
para.detect_para.detection_mode = 'K_increasing';

try
    para = initialise_FRI_pulse_detection(para);
    disp('FRI pulse detection initialisation completed!');
catch error_reason
    warning('Failed to initialise FRI pulse detection!');
    rethrow(error_reason)
end

%% save the parameters for deconvolution
if para.flags.save_flag
    save([para.folder_name,para.file_name,'_pre_para_',para.decon_method,'.mat'],'para',...
        'maximum_spectrum','back_noise','spectrum_denoised','average_spectrum')
end
disp('Pre-processing for XRF deconvolution completed!');

