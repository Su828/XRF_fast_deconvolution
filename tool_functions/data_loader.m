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

function [para,data_cube] = data_loader(para)
% the function to load data

switch para.data_type
    case 'edf'
        [para,data_cube]=load_edf_files(para);
    case 'raw'
        [para,data_cube]=load_raw_file(para);
end
if para.filter_size>1
    filter_h = ones(para.filter_size,para.filter_size,'single')./para.filter_size./para.filter_size;
    data_cube = convn(data_cube,filter_h,'same');
end
data_size = size(data_cube);
para.size_1 = data_size(1);
para.size_2 = data_size(2);
para.size_3 = data_size(3);
channel_axis = 0:(para.size_1-1);
para.channel_axis = channel_axis;
if isfield(para,'max_window_use')
    max_channel = para.pulse_para.Bspline_data(para.max_window_use,2);
    channel_axis_use = 0:max_channel;
    para.channel_axis_use = channel_axis_use;
else
    para.channel_axis_use = channel_axis;
end

if para.flags.plot_flag
    % show maximum intensity projection along spectral dimension
    figure
    imshow(squeeze(max(data_cube,[],1)),[])
    xlabel(sprintf('size3: %d pixels',para.size_3))
    ylabel(sprintf('size2: %d pixels',para.size_2))

    % plot average and maximum spectra
    figure
    plot(channel_axis,squeeze(mean(data_cube,[2,3])))
    xlim([min(channel_axis) max(channel_axis)])
    title('Average spectrum')
    xlabel('Channel No.')
    ylabel('Photon counts')
    figure
    plot(channel_axis,squeeze(max(data_cube,[],[2,3])))
    xlim([min(channel_axis) max(channel_axis)])
    title('Maximum spectrum')
    xlabel('Channel No.')
    ylabel('Photon counts')
end