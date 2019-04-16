clear all;
addpath('matlab_tools');
addpath_recurse("matlab_tools")

close all;

load('data/insightface_train_set.mat','insightface_train_set');
load('data/insightface_train_label.mat','insightface_train_label');
load('data/insightface_gallery.mat','insightface_gallery');
load('data/insightface_gallery_label.mat','insightface_gallery_label');
load('data/insightface_probe_c.mat','insightface_probe_c');
load('data/insightface_probe_label_c.mat','insightface_probe_label_c');
load('data/insightface_probe_o1.mat','insightface_probe_o1');
load('data/insightface_probe_o2.mat','insightface_probe_o2');
load('data/insightface_probe_o3.mat','insightface_probe_o3');
load('data/insightface_probe_label_o1.mat','insightface_probe_label_o1');
load('data/insightface_robe_label_o2.mat','insightface_probe_label_o2');
load('data/insightface_probe_label_o3.mat','insightface_probe_label_o3');

cntxx=1;
for alpha=1:3
    Nb=1024;
    opts.lambda = 0.5;% 0.5 1 2
    opts.beta = 1;% 0.5 0.8 1
    opts.K = 16;
    opts.dX = size(insightface_train_set,2);
    opts.L = ceil(Nb / ceil(log2(opts.K))); % train maximum number of bits
    opts.gaussian=1; %1/0=gaussian/laplace
    % original eer
    
    SHparamNew.nbits=1024;
        SHparamNew.alpha=0;

    %*&&&&&&&&&&&&&&&&&&&&&*&&&&&&&&&&&&&&&&&&&&&*&&&&&&&&&&&&&&&&&&&&&*&&&&&&&&&&&&&&&&&&&&&*&&&&&&&&&&&&&&&&&&&&&
    % model = learning_IoM(train_data, opts);
    model = random_IoM(opts);
    
    db_data.X=insightface_gallery';
    [all_code, ~] = IoM(db_data, opts, model);
    hashed_code_facenet_gallery=all_code.Hx';
    
    db_data.X=insightface_probe_c';
    [all_code, ~] = IoM(db_data, opts, model);
    hashed_code_facenet_probe_c=all_code.Hx';
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    distance=pdist2( hashed_code_facenet_gallery,hashed_code_facenet_probe_c,  'hamming')*SHparamNew.nbits;
    hamming_gen_score = distance(insightface_gallery_label'==insightface_probe_label_c);
    hamming_imp_score = distance(insightface_gallery_label'~=insightface_probe_label_c);
    
    
    [EER_HASH, mTSR, mFAR, mFRR, mGAR] =computeperformance(1-hamming_gen_score/SHparamNew.nbits, 1-hamming_imp_score/SHparamNew.nbits, 0.001);  % isnightface 3.43 % 4.40 %
    EER_DD(cntxx)=EER_HASH;
    for i=1:size(insightface_gallery,1)
        for j=1:size(insightface_probe_c,1)
            sampleA=insightface_gallery(i,:);
            sampleB=insightface_probe_c(j,:);
            newdistance(i,j)=   norm(sampleA-sampleB);
            
        end
    end
    
    
    euclidean_gen_score = newdistance(insightface_gallery_label'==insightface_probe_label_c);
    euclidean_imp_score = newdistance(insightface_gallery_label'~=insightface_probe_label_c);
    
    % [EER_ORIG, mTSR, mFAR, mFRR, mGAR] =computeperformance(1-euclidean_gen_score, 1-euclidean_imp_score, 0.001);  % isnightface 3.43 % 4.40 %
    close all;
    scatter(euclidean_gen_score,hamming_gen_score,'s')
    hold on
    scatter(euclidean_imp_score,hamming_imp_score,'o')
    legend('Intra','Inter','Location','northwest');
    title('bit length = 1024');
    xlabel('Euclidean distance');
    ylabel('Hamming distance');
    var(hamming_imp_score)
    var_DD(cntxx)=var(hamming_imp_score);
    saveas(gcf,['graph/correlation_alpha_iom',num2str(SHparamNew.alpha),'_bits',num2str(SHparamNew.nbits),'.tif'])
    % dscatter(euclidean_gen_score,hamming_gen_score,'marker','o')
    % hold on
    % dscatter(euclidean_imp_score,hamming_imp_score,'marker','s')
    %
    % legend('Intra','Inter','Location','northwest');
    % title('bit length = 1024');
    % xlabel('Euclidean distance');
    % ylabel('Hamming distance');
    cntxx =  cntxx+1;
end

