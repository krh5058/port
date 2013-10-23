function result = scramble(obj)

result = 1;

[~,d] = system(['dir /b ' obj.path.scramble filesep obj.exp.scrambleID '*']);
d = regexp(strtrim(d),'\n','split');

try
    mkdir([obj.path.scramble filesep obj.exp.sid]);
catch ME
    result = ME;
end

try
    for i = 1:length(d)
        [A,~,~] = imread([obj.path.scramble filesep d{i}]);
        
        y = size(A,1); % Rows (y)
        x = size(A,2); % Columns (x)
        
        A1 = A(:,:,1);
        A2 = A(:,:,2);
        A3 = A(:,:,3);
        
        mody = mod(y,obj.exp.scrambleSize); % Add rows
        modx = mod(x,obj.exp.scrambleSize); % Add columns
        
        y2 = y + (obj.exp.scrambleSize - mody);
        x2 = x + (obj.exp.scrambleSize - modx);
        
        B = intmax('uint8')*ones([y2 x2 3],'uint8'); % 'White' 3D uint8 matrix
        B2 = B; % Pre-allocate for scrambled image
        
        B(1:y,1:x,1) = A1;
        B(1:y,1:x,2) = A2;
        B(1:y,1:x,3) = A3;
        
        %         imshow(B)
        
        rowindex = 1:obj.exp.scrambleSize:y2;
        colindex = 1:obj.exp.scrambleSize:x2;
        
        coord_array = zeros([length(rowindex) length(colindex) 2]);
        
        %     hold on
        for r = 1:length(rowindex)
            %         plot(colindex,rowindex(r),'g');
            for c = 1:length(colindex)
                coord_array(r,c,:) = [rowindex(r) colindex(c)];
            end
        end
        %     hold off
        
        %         print(gcf,[int2str(i) '_' int2str(obj.exp.scrambleSize(s)) 'sq_grid.png'],'-dpng');
        
        %         close(gcf);
        
        reshape_array = reshape(coord_array,length(rowindex)*length(colindex),2,1);
        shuffle_array = reshape_array(Shuffle(1:length(reshape_array)),:);
        
        for repind = 1:length(shuffle_array)
            B2(reshape_array(repind,1):reshape_array(repind,1)+obj.exp.scrambleSize-1,reshape_array(repind,2):reshape_array(repind,2)+obj.exp.scrambleSize-1,:) = B(shuffle_array(repind,1):shuffle_array(repind,1)+obj.exp.scrambleSize-1,shuffle_array(repind,2):shuffle_array(repind,2)+obj.exp.scrambleSize-1,:);
        end
        
        %     imshow(B2);
        
        imwrite(B2,[obj.path.scramble filesep obj.exp.sid filesep d{i}],'JPG');
        
        %         close(gcf);
        
    end
catch ME
    result = ME;
end

end