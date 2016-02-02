function GenerateDummyData(numOfExamples, outpt_dir)
    
    %make waves dir if not exists
    if ~exist(outpt_dir, 'dir')
        mkdir(outpt_dir) 
    end
    
    %min and max frequency
    min_f = 500;
    max_f = 2000;
    %min and max zero gaps 
    min_pad = 3000;
    max_pad = 6000;
    %min and max signal length
    min_signal_len = 0.05;
    max_signal_len = 0.15;
    
    %loop to generate the number of examples that was requested
    for i=1:numOfExamples
        f1 = round((max_f-min_f)*rand() + min_f);
        f2 = round((max_f-min_f)*rand() + min_f);
        f3 = round((max_f-min_f)*rand() + min_f);

        %generating the sine waves and summing them up
        len = (max_signal_len-min_signal_len)*rand() + min_signal_len;
        step=6.2500e-05;
        t=0:step:len;    
        y1=0.8*sin(2*pi*f1*t);
        y2=0.8*sin(2*pi*f2*t);
        y3=0.8*sin(2*pi*f3*t);        
        y_total = y1+y2+y3;
    
        %setting the padding with zeros
        start_pad_len = round((max_pad-min_pad)*rand() + min_pad);
        end_pad_len = round((max_pad-min_pad)*rand() + min_pad);
        zero_vec_start = zeros(1,start_pad_len);
        zero_vec_end = zeros(1,end_pad_len);
        
        %create the final sine wave signal
        result = [zero_vec_start,y_total,zero_vec_end];
        file_name = strcat(num2str(i),'_',num2str(f1),'_',num2str(f2),'_',num2str(f3));
        wav_path = strcat(outpt_dir,'/',file_name,'.wav');
        wavwrite(result,16000,16,wav_path);
        
        %create the label files
        start_label = start_pad_len/16000;       
        end_label = start_label + size(y_total,2)/16000;
        label_path = strcat(outpt_dir,'/',file_name,'.label');        
        fid = fopen(label_path, 'w');
                
        fprintf(fid,'%d ',size(result,2)/16000 - 0.0001);
        fprintf(fid,'%d ',start_label);
        fprintf(fid,'%d \n',end_label);
        fclose(fid);
    end