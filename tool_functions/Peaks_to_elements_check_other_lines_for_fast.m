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

function [element_numbers,element_confidence_to_save,element_quantity_to_save,different_lines_confidence_to_save,different_lines_quantity_to_save,element_KLM_confidence_to_save,element_KLM_quantity_to_save,confidence_scores]...
    =Peaks_to_elements_check_other_lines_for_fast(plot_flag,peak,intensity,All_Elements, ECC_interested,ref_location,ref_standard_deviation,b_1,adjust_index)

[~,half_width_est]=calculate_pulse_width_in_channel_b1_nofit(ref_location,ref_standard_deviation,b_1,peak,adjust_index);
ECC_to_use=ECC_interested; % ECC or ECC_interested

intensity=intensity(peak>0);
peak=peak(peak>0);

confidence_scores=zeros([length(peak) size(ECC_to_use)]);
quantity_scores=zeros([length(peak) size(ECC_to_use)]);

confidence_intervals_min=3.5;
confidence_intervals_max=10.5;
confidence_intervals=half_width_est/2;
confidence_intervals(confidence_intervals<confidence_intervals_min)=confidence_intervals_min;
confidence_intervals(confidence_intervals>confidence_intervals_max)=confidence_intervals_max;

for n=1:length(peak)
    peak_loc=peak(n);
    peak_amp=intensity(n);
    
    peak_interval=confidence_intervals(n);
    index=abs(peak_loc-ECC_to_use)<=peak_interval;
    [elements,lines]=find(index);
    if ~isempty(elements) && ~isempty(lines)
        loc_difference=abs(peak_loc-ECC_to_use(index));
        [new_elements,ia,~]=unique(elements);
        if length(elements)~=length(new_elements)
            duplicate_index = setdiff( 1:numel(elements), ia );
            duplicate_value = elements(duplicate_index);
            real_duplicate_index=[];
            for r=1:length(duplicate_index)
                larger_difference=max(loc_difference(elements==duplicate_value(r)));
                idx=find(loc_difference==larger_difference,1,'last');
                real_duplicate_index=[real_duplicate_index, idx];
                index(elements(idx),lines(idx))=false;
            end
            elements(real_duplicate_index)=[];
            lines(real_duplicate_index)=[];
        end
        
        loc_difference=abs(peak_loc-ECC_to_use(index));
        % confidence_sco=(peak_interval-loc_difference)/peak_interval;
        confidence_sco=(peak_interval*2+1-2*loc_difference)/(peak_interval*2-1);
        confidence_sco(loc_difference>peak_interval)=0;
        confidence_sco(confidence_sco>1)=1;
        
        for t=1:length(elements)
            already_index=find(squeeze(confidence_scores(:,elements(t),lines(t))), 1);
            if ~isempty(already_index)
                previous_confidence=confidence_scores(already_index,elements(t),lines(t));
                new_confidence=confidence_sco(t);
                if previous_confidence>=new_confidence
                    confidence_sco(t)=0;
                else
                    confidence_scores(already_index,elements(t),lines(t))=0;
                    quantity_scores(already_index,elements(t),lines(t))=0;
                end
            end
        end
        
        confidence_scores(n,index)=confidence_sco;
        ele_num=unique(elements);
        if length(ele_num)>1
            quantity_sco=confidence_sco*peak_amp;
        else
            quantity_sco=peak_amp;
        end
        %quantity_sco=(confidence_sco/sum(confidence_sco,'all'))*peak_amp;
        quantity_scores(n,index)=quantity_sco;
    end
end

K_alpha_quantity=sum(squeeze(sum(quantity_scores(:,:,1:2),1)),2);
K_beta_quantity= sum(squeeze(sum(quantity_scores(:,:,3:5),1)),2);
L_l_quantity=    sum(quantity_scores(:,:,6),1)';
L_alpha_quantity=sum(squeeze(sum(quantity_scores(:,:,7:8),1)),2);
L_beta_quantity= sum(squeeze(sum(quantity_scores(:,:,9:10),1)),2);
L_gamma_quantity=sum(quantity_scores(:,:,11),1)';

K_split_index=K_alpha_quantity<K_beta_quantity;
K_split_element=find(K_split_index==1);
L_split_index=L_alpha_quantity<L_beta_quantity | L_alpha_quantity<L_gamma_quantity | L_alpha_quantity<L_l_quantity ;
L_split_element=find(L_split_index==1);

if any(K_split_index|L_split_index)==1
    for a=1:length(K_split_element)
        split_element=K_split_element(a);
        element_quantity_scores=squeeze(quantity_scores(:,split_element,:));
        [target_pulses,target_lines]=find(element_quantity_scores>0);
        alpha_pulses=target_pulses(target_lines>=1 & target_lines<=2);
        if isempty(alpha_pulses)
            pulse_alpha_amp=0;
        else
            pulse_alpha_amp=intensity(alpha_pulses);
        end
        new_pulse_amp=0.5*sum(pulse_alpha_amp);
        
        split_pulses=target_pulses(target_lines>=3 & target_lines<=5);
        split_lines=target_lines(target_lines>=3 & target_lines<=5);
        for aa=1:length(split_pulses)
            if new_pulse_amp>0
                quantity_scores(split_pulses(aa),split_element,split_lines(aa))=new_pulse_amp*confidence_scores(split_pulses(aa),split_element,split_lines(aa));
            else
                quantity_scores(split_pulses(aa),split_element,split_lines(aa))=0;
                confidence_scores(split_pulses(aa),split_element,split_lines(aa))=0;
            end
        end
    end
    
    for b=1:length(L_split_element)
        split_element=L_split_element(b);
        element_quantity_scores=squeeze(quantity_scores(:,split_element,:));
        [target_pulses,target_lines]=find(element_quantity_scores>0);
        alpha_pulses=target_pulses(target_lines>=7 & target_lines<=8);
        if isempty(alpha_pulses)
            pulse_alpha_amp=0;
        else
            pulse_alpha_amp=intensity(alpha_pulses);
        end
        new_pulse_amp=0.5*sum(pulse_alpha_amp);
        
        split_pulses=target_pulses(target_lines>=9 & target_lines<=11 | target_lines==6);
        split_lines=target_lines(target_lines>=9 & target_lines<=11 | target_lines==6);
        
        for bb=1:length(split_pulses)
            if new_pulse_amp>0
                quantity_scores(split_pulses(bb),split_element,split_lines(bb))=new_pulse_amp*confidence_scores(split_pulses(bb),split_element,split_lines(bb));
            else
                quantity_scores(split_pulses(bb),split_element,split_lines(bb))=0;
                confidence_scores(split_pulses(bb),split_element,split_lines(bb))=0;
            end
        end
    end
end


% element_overlap_index=zeros([length(peak) size(ECC_to_use)]); % if has overlaps 1, if no overlaps 0
element_numbers=find(any(squeeze(any(confidence_scores,1)),2));
element_confidence=zeros(size(element_numbers));
element_KLM_confidence=zeros(length(element_numbers),3);
different_lines_confidence=zeros(length(element_numbers),7);
for ele=1:length(element_numbers)
    element_confidence_table=squeeze(confidence_scores(:,element_numbers(ele),:));
    element_line_confidence_table=sum(element_confidence_table,1);
    [pulses_index,lines_index]=find(element_confidence_table>0);
    pulse_overlap_index=zeros(size(element_line_confidence_table)); % if has overlaps 1, if no overlaps 0
    element_line_confidences=zeros(1,7);
    lines_overlap_index=zeros(1,7);
    for c=1:length(pulses_index)
        pulse_confidence_table=squeeze(confidence_scores(pulses_index(c),:,:));
        if length(find(pulse_confidence_table>0))>1
            pulse_overlap_index(lines_index(c))=1;
        end
    end
    K_alpha_index=lines_index>=1 & lines_index<=2;
    if any(K_alpha_index)
        K_alpha_combine_confidence=sum(element_line_confidence_table(1:2))/sum(ECC_to_use(element_numbers(ele),1:2)~=0);
        K_alpha_combine_confidence(isnan(K_alpha_combine_confidence))=0;
        K_alpha_confidence=max(element_line_confidence_table(1),K_alpha_combine_confidence);
        element_line_confidences(1)=K_alpha_confidence;
        lines_overlap_index(1)=any(pulse_overlap_index(lines_index(K_alpha_index)));
    end
    K_beta_index=lines_index>=3 & lines_index<=5;
    if any(K_beta_index)
        K_beta_combine_confidence=sum(element_line_confidence_table(3:5))/sum(ECC_to_use(element_numbers(ele),3:5)~=0);
        K_beta_combine_confidence(isnan(K_beta_combine_confidence))=0;
        K_beta_confidence=max(element_line_confidence_table(3),K_beta_combine_confidence);
        element_line_confidences(2)=K_beta_confidence;
        lines_overlap_index(2)=any(pulse_overlap_index(lines_index(K_beta_index)));
    end
    L_l_index=lines_index==6;
    if any(L_l_index)
        L_l_confidence=element_line_confidence_table(6);
        element_line_confidences(3)=L_l_confidence;
        lines_overlap_index(3)=any(pulse_overlap_index(lines_index(L_l_index)));
    end
    L_alpha_index=lines_index>=7 & lines_index<=8;
    if any(L_alpha_index)
        L_alpha_combine_confidence=sum(element_line_confidence_table(7:8))/sum(ECC_to_use(element_numbers(ele),7:8)~=0);
        L_alpha_combine_confidence(isnan(L_alpha_combine_confidence))=0;
        L_alpha_confidence=max(element_line_confidence_table(7),L_alpha_combine_confidence);
        element_line_confidences(4)=L_alpha_confidence;
        lines_overlap_index(4)=any(pulse_overlap_index(lines_index(L_alpha_index)));
    end
    L_beta_index=lines_index>=9 & lines_index<=10;
    if any(L_beta_index)
        L_beta_combine_confidence=sum(element_line_confidence_table(9:10))/sum(ECC_to_use(element_numbers(ele),9:10)~=0);
        L_beta_combine_confidence(isnan(L_beta_combine_confidence))=0;
        L_beta_confidence=max(element_line_confidence_table(9),L_beta_combine_confidence);
        element_line_confidences(5)=L_beta_confidence;
        lines_overlap_index(5)=any(pulse_overlap_index(lines_index(L_beta_index)));
    end
    L_gamma_index=lines_index==11;
    if any(L_gamma_index)
        L_gamma_confidence=element_line_confidence_table(11);
        element_line_confidences(6)=L_gamma_confidence;
        lines_overlap_index(6)=any(pulse_overlap_index(lines_index(L_gamma_index)));
    end
    M_alpha_index=lines_index==12;
    if any(M_alpha_index)
        M_alpha_confidence=element_line_confidence_table(12);
        element_line_confidences(7)=M_alpha_confidence;
        lines_overlap_index(7)=any(pulse_overlap_index(lines_index(M_alpha_index)));
    end
    different_lines_confidence(ele,:)=element_line_confidences;
    element_family_confidences=zeros(1,3);
    index_1=element_line_confidences>0;
    if any(index_1(1:2))
        if lines_overlap_index(1)==0 && lines_overlap_index(2)==0
            K_confidence=max(element_line_confidences(1),element_line_confidences(2));
        elseif lines_overlap_index(1)==0 && lines_overlap_index(2)==1
            K_combine_confidence=(2*element_line_confidences(1)+element_line_confidences(2))/3;
            K_confidence=max(element_line_confidences(1),K_combine_confidence);
        elseif lines_overlap_index(1)==1 && lines_overlap_index(2)==0 
            K_combine_confidence=(element_line_confidences(1)+2*element_line_confidences(2))/3;
            K_confidence=max(element_line_confidences(2),K_combine_confidence);
        elseif lines_overlap_index(1)==1 && lines_overlap_index(2)==1 
            K_confidence=(2*element_line_confidences(1)+element_line_confidences(2))/3;
        end
        element_family_confidences(1)=K_confidence;
    end
    if any(index_1(3:6))
        if all(lines_overlap_index(3:6))==1
            L_confidence=(2*element_line_confidences(4)+element_line_confidences(3)+element_line_confidences(5)+element_line_confidences(6))/5;
        elseif any(lines_overlap_index(3:6))==0
            L_confidence=max(element_line_confidences(3:6));
        else
            if lines_overlap_index(3)==0
                L_combine_confidence=(2*element_line_confidences(4)+element_line_confidences(3)+element_line_confidences(5)+element_line_confidences(6))/5;
                L_confidence=max(element_line_confidences(4),L_combine_confidence);
            else
                element_line_confidences_L=ones(size(element_line_confidences));
                element_line_confidences_L(3:6)=element_line_confidences(3:6);
                L_combine_confidence=(element_line_confidences(4)+(~lines_overlap_index(3)+1)*element_line_confidences(3)+(~lines_overlap_index(5)+1)*element_line_confidences(5)+(~lines_overlap_index(6)+1)*element_line_confidences(6))/(1+(~lines_overlap_index(3)+1)+(~lines_overlap_index(5)+1)+(~lines_overlap_index(6)+1));
                L_confidence=max([element_line_confidences_L(lines_overlap_index==0),L_combine_confidence]);
            end
        end
        element_family_confidences(2)=L_confidence;
    end
    M_confidence=element_line_confidences(7);
    element_family_confidences(3)=M_confidence;
    
    K_index=any(ECC_to_use(element_numbers(ele),1:5));
    L_index=any(ECC_to_use(element_numbers(ele),6:10));
    M_index=any(ECC_to_use(element_numbers(ele),11));
%     element_confidence(ele)=sum(element_family_confidences)/(K_index+L_index+M_index);
    element_KLM_confidence(ele,:)=element_family_confidences;
    element_confidence(ele)=(4*element_family_confidences(1)+2*element_family_confidences(2)+element_family_confidences(3))/(K_index*4+L_index*2+M_index);
end

if length(element_numbers)==1
    K_alpha_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,1:2),1)));
    K_beta_quantity= sum(squeeze(sum(quantity_scores(:,element_numbers,3:5),1)));
    L_l_quantity=    sum(quantity_scores(:,element_numbers,6),1)';
    L_alpha_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,7:8),1)));
    L_beta_quantity= sum(squeeze(sum(quantity_scores(:,element_numbers,9:10),1)));
    L_gamma_quantity=sum(quantity_scores(:,element_numbers,11),1)';
    M_alpha_quantity=sum(quantity_scores(:,element_numbers,12),1)';
    element_K_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,1:5),1)));
    element_L_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,6:11),1)));
    element_M_quantity=sum(quantity_scores(:,element_numbers,12),1)';
    element_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,:),1)));
else
    K_alpha_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,1:2),1)),2);
    K_beta_quantity= sum(squeeze(sum(quantity_scores(:,element_numbers,3:5),1)),2);
    L_l_quantity=    sum(quantity_scores(:,element_numbers,6),1)';
    L_alpha_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,7:8),1)),2);
    L_beta_quantity= sum(squeeze(sum(quantity_scores(:,element_numbers,9:10),1)),2);
    L_gamma_quantity=sum(quantity_scores(:,element_numbers,11),1)';
    M_alpha_quantity=sum(quantity_scores(:,element_numbers,12),1)';
    element_K_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,1:5),1)),2);
    element_L_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,6:11),1)),2);
    element_M_quantity=sum(quantity_scores(:,element_numbers,12),1)';
    element_quantity=sum(squeeze(sum(quantity_scores(:,element_numbers,:),1)),2);
end
element_KLM_quantity=[element_K_quantity,element_L_quantity,element_M_quantity];
different_lines_quantity=[K_alpha_quantity,K_beta_quantity,L_l_quantity,L_alpha_quantity,L_beta_quantity,L_gamma_quantity,M_alpha_quantity];


element_names=All_Elements(element_numbers);
element_confidence_plot=element_confidence;
element_quantity_plot=element_quantity;

element_confidence_to_save=zeros(size(ECC_to_use,1),1);
element_quantity_to_save=zeros(size(ECC_to_use,1),1);
element_confidence_to_save(element_numbers)=element_confidence;
element_quantity_to_save(element_numbers)=element_quantity;
element_KLM_confidence_to_save=zeros(size(ECC_to_use,1),3);
element_KLM_quantity_to_save=zeros(size(ECC_to_use,1),3);
element_KLM_confidence_to_save(element_numbers,:)=element_KLM_confidence;
element_KLM_quantity_to_save(element_numbers,:)=element_KLM_quantity;
different_lines_confidence_to_save=zeros(size(ECC_to_use,1),7);
different_lines_quantity_to_save=zeros(size(ECC_to_use,1),7);
different_lines_confidence_to_save(element_numbers,:)=different_lines_confidence;
different_lines_quantity_to_save(element_numbers,:)=different_lines_quantity;


if plot_flag
%     figure
%     bar(categorical(element_names),element_confidence_plot)
%     title('Element confidences with all charateristic lines')
%     figure
%     bar(categorical(element_names),element_quantity_plot)
%     title('Element quantities with all charateristic lines')
%     
%     figure
%     if length(element_names)==1
%         bar(element_KLM_confidence,'grouped')
%         xlabel(element_names{1})
%     else
%         bar(categorical(element_names),element_KLM_confidence,'grouped')
%     end
%     legend('K','L','M')
%     title('Element confidences with KLM lines')
%     figure
%     if length(element_names)==1
%         bar(element_KLM_quantity,'grouped')
%         xlabel(element_names{1})
%     else
%         bar(categorical(element_names),element_KLM_quantity,'grouped')
%     end
%     legend('K','L','M')
%     title('Element quantities with KLM lines')
    
    figure
    hold on
    X = categorical(element_names);
    X = reordercats(X,element_names);
    b=bar(different_lines_confidence,'histc');
    legend('K_{\alpha}','K_{\beta}','L_{l}','L_{\alpha}','L_{\beta}','L_{\gamma}','M_{\alpha}','FontSize',12)
    xlim([0.7 length(X)+1])
    set(gca, 'XTick', 1:1:length(X));
    set(gca, 'xTickLabel', X);
    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'off';
    ax.GridLineStyle = '--';
    ax.GridAlpha = 1;
    ax.Layer = 'top';
    title('Element confidences with different charateristic lines')
    xlabel('Chemical Element','FontSize',12)
    ylabel('GCS','FontSize',12)
    b(1).FaceColor = [0 0.4470 0.7410];
    b(2).FaceColor = [0.8500 0.3250 0.0980];
    b(3).FaceColor = [0.9290 0.6940 0.1250];
    b(4).FaceColor = [0.4940 0.1840 0.5560];
    b(5).FaceColor = [0.4660 0.6740 0.1880];
    b(6).FaceColor = [0.3010 0.7450 0.9330];
    b(7).FaceColor = [0.6350 0.0780 0.1840];
    figure
    legend
    hold on
    X = categorical(element_names);
    X = reordercats(X,element_names);
    b=bar(different_lines_quantity,'histc');
    legend('K_{\alpha}','K_{\beta}','L_{l}','L_{\alpha}','L_{\beta}','L_{\gamma}','M_{\alpha}','FontSize',12)
    xlim([0.7 length(X)+1])
    set(gca, 'XTick', 1:1:length(X));
    set(gca, 'xTickLabel', X);
    ax = gca;
    ax.XGrid = 'on';
    ax.YGrid = 'off';
    ax.GridLineStyle = '--';
    ax.GridAlpha = 1;
    ax.Layer = 'top';
    title('Element quantities with different charateristic lines','FontSize',12)
    xlabel('Chemical Element','FontSize',12)
    ylabel('GQS','FontSize',12)
    b(1).FaceColor = [0 0.4470 0.7410];
    b(2).FaceColor = [0.8500 0.3250 0.0980];
    b(3).FaceColor = [0.9290 0.6940 0.1250];
    b(4).FaceColor = [0.4940 0.1840 0.5560];
    b(5).FaceColor = [0.4660 0.6740 0.1880];
    b(6).FaceColor = [0.3010 0.7450 0.9330];
    b(7).FaceColor = [0.6350 0.0780 0.1840];
end



