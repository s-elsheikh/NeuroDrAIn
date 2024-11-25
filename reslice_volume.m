function resliced = reslice_volume(nii,ref,method)

%% reslice_volume(nii,ref,method)
%  reslices a nifti
%  nii - nifti to reslice
%  ref - reference nifti header, or
%        if single scalar - a scale factor the orginal nifti is scaled with
%                           new voxsizes are oldvsz/factor
%        if array of size [3 1] - voxelsizes of resliced nifti
%

    if nargin == 2,
        method = 'linear';
    end


    if isnumeric(method),
        if method==0,
            method = 'nearest';
        else
            method = 'linear';
        end;
    end;
            
    if isnumeric(ref) % ref is resampling factor, so create a dummy nifti header of appr. size
        if length(ref) == 3
            edges = [nii.hdr.hist.srow_x ; nii.hdr.hist.srow_y ; nii.hdr.hist.srow_z ; 0 0 0 1];            
            factor = sqrt(sum(edges(1:3,1:3).^2)) ./ ref(:)';            
        else
            factor = ref*ones(3,1);
        end
        factor = factor(:);
        
        ref = nii;
        ref.hdr.dime.dim(2:4) = floor(ref.hdr.dime.dim(2:4).*factor');
        for j = 1:3,
            ref.hdr.hist.srow_x(j) = ref.hdr.hist.srow_x(j)/factor(j);
            ref.hdr.hist.srow_y(j) = ref.hdr.hist.srow_y(j)/factor(j);
            ref.hdr.hist.srow_z(j) = ref.hdr.hist.srow_z(j)/factor(j); 
        end
        A = [ref.hdr.hist.srow_x(1:3) ; ref.hdr.hist.srow_y(1:3) ; ref.hdr.hist.srow_z(1:3) ];
        tr = 0*A*([1 1 1]'./factor);        
        ref.hdr.hist.srow_x(4) = ref.hdr.hist.srow_x(4) - tr(1);
        ref.hdr.hist.srow_y(4) = ref.hdr.hist.srow_y(4) - tr(2);
        ref.hdr.hist.srow_z(4) = ref.hdr.hist.srow_z(4) - tr(3);        
        ref.hdr.dime.pixdim(2:4) = ref.hdr.dime.pixdim(2:4)./factor';
    end
            


    dim = ref.hdr.dime.dim(2:end);
    dim(dim==0) = 1;
    A = inv(inv([ref.hdr.hist.srow_x; ref.hdr.hist.srow_y; ref.hdr.hist.srow_z; 0 0 0 1])*[nii.hdr.hist.srow_x; nii.hdr.hist.srow_y; nii.hdr.hist.srow_z; 0 0 0 1]);
    [X Y Z] = ndgrid(0:dim(1)-1,0:dim(2)-1,0:dim(3)-1);
    
    C = single([X(:)' ; Y(:)' ; Z(:)']);
    AC = A(1:3,1:3)*C + repmat(A(1:3,4),[1 size(C,2)]);
    
    atlas = false;
    if strcmp(method,'atlas')
        method = 'linear';
        atlas = true;
    end;
    
    
    ifun = @(x) interp3(single(x),AC(2,:)+1,AC(1,:)+1,AC(3,:)+1,method,nan);
    if size(nii.img,3) == 1,
        if size(ref.img,3) == 1,
            nii.img = repmat(nii.img,[1 1 3]);
            ifun = @(x) interp3(single(x),AC(2,:)+1,AC(1,:)+1,AC(3,:)*0+2,method,nan);                        
        else
            nii.img = repmat(nii.img,[1 1 3]);
            nii.img(:,:,1,:) = 0;
            nii.img(:,:,3,:) = 0;
            ifun = @(x) interp3(single(x),AC(2,:)+1,AC(1,:)+1,AC(3,:)+2,method,nan);
        end
    end
%    if nii.hdr.dime.dim(4) == 1,
 %       ifun = @(x) interp2(single(x),AC(2,:)+1,AC(1,:)+1,method,nan);       
  %  end
    
    if atlas,        
       a = nii.img;
       idx = unique(a(a(:)>0));
       warped = zeros([size(ref.img) length(idx)]);
       for k = 1:length(idx)
          fprintf('.');
          warped(:,:,:,k)  = reshape(ifun(single((a==idx(k)))),dim(1:3)); 
       end;        
       mask = sum(warped,4)>0.5;
       [~,warped] = max(warped,[],4);
       warped(mask(:)) = idx(warped(mask(:)));
       warped = warped.*mask;
       
    else
        
        for j = 1:size(nii.img,5),
            for k = 1:size(nii.img,4),
                warped(:,:,:,k,j)  = reshape(ifun(nii.img(:,:,:,k,j)),dim(1:3)); 
            end;
        end
    
    end
    
    
    resliced = ref;

    warped(isnan(warped)) = 0;
    
    warped = cast(warped,class(nii.img));
    resliced.hdr.dime.datatype = nii.hdr.dime.datatype;
    resliced.hdr.dime.bitpix = nii.hdr.dime.bitpix;
    resliced.hdr.hist.descrip = nii.hdr.hist.descrip;
    
    
    resliced.img = warped;
    resliced.hdr.dime.dim(5) = size(warped,4);
    resliced.hdr.dime.dim(6) = size(warped,5);
    if size(warped,4) > 1
        resliced.hdr.dime.dim(5) = 4;
    end
    if size(warped,5) > 1
        resliced.hdr.dime.dim(5) = 5;
    end
        
    resliced.hdr.dime.datatype = nii.hdr.dime.datatype;
    resliced.hdr.dime.bitpix = nii.hdr.dime.bitpix;
    resliced.hdr.dime.scl_inter = nii.hdr.dime.scl_inter;
    resliced.hdr.dime.scl_slope = nii.hdr.dime.scl_slope;

    resliced.edges = [ref.hdr.hist.srow_x ; ref.hdr.hist.srow_y ; ref.hdr.hist.srow_z ; 0 0 0 1];
    resliced.voxsz = sqrt(sum(resliced.edges(1:3,1:3).^2,1));
end