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

function view_para = view_fast_decon_maps(para,view_para,decon_results)

T_s = para.pulse_para.T_s;
ECC_use = round(para.ECC_interested,-log10(T_s));
ECC_use=ECC_use(:,[1 3 6 7 9 11 12]);
All_Elements = para.All_Elements;

atomic_number_chosen = view_para.atomic_No_view; 
lines_chosen = view_para.lines_chosen;
line_names = view_para.line_names;
% set the maximum threshold for displaying an elemental map
max_quantity_value = view_para.max_value;
% set the minimum threshold for displaying an elemental map
min_quantity_value = view_para.min_value;

amplitude_estimated = decon_results.maps_decon;
peak_to_use = decon_results.peak_to_use;
element_name = All_Elements{atomic_number_chosen};

element_line_chosen=ECC_use(atomic_number_chosen,lines_chosen);

for n=1:length(lines_chosen)
    element_line=element_line_chosen(n);
    elemental_map=squeeze(amplitude_estimated(:,:,peak_to_use==element_line));
    % varibale 'elemental_map' is the raw data of the selected elemental map
    
    if ~isempty(elemental_map)
        max_value=max_quantity_value(n);
        if max_value==inf
            max_value=max(elemental_map,[],'all');
        end
        
        figure('Name',[element_name,' ', line_names{lines_chosen(n)}, ' -- quantity map'])
        imshow(elemental_map',[min_quantity_value(n) max_value])
        title([element_name,' ', line_names{lines_chosen(n)}, ' -- quantity map'],'FontSize',20)
        axis tight
        colorbar('FontSize',20)
        
        figure('Name',[element_name,' ', line_names{lines_chosen(n)}, ' -- quantity histogram'])
        quantity_histogram=elemental_map(:);
        quantity_histogram=quantity_histogram(quantity_histogram>0);
        histogram(quantity_histogram,300)
        axis tight
    else
        disp([element_name,' ', line_names{lines_chosen(n)}, ' is not detected!'])
    end
end
view_para.element_name = element_name;