% Load the input prediction NIfTI file
nii{1} = load_untouch_nii(input1); % Load the NIfTI file using a custom function
icb_pred = nii{1}.img(:,:,:,end-1); % Extract the second-to-last 3D volume (ICB prediction)
drain_pred = nii{1}.img(:,:,:,end); % Extract the last 3D volume (Drain prediction)

% Calculate probability masks by applying linear scaling factors
icb_prob_mask = single(icb_pred) * nii{1}.hdr.dime.scl_slope + nii{1}.hdr.dime.scl_inter; % Scale ICB predictions
drain_prob_mask = single(drain_pred) * nii{1}.hdr.dime.scl_slope + nii{1}.hdr.dime.scl_inter; % Scale Drain predictions

% Apply thresholding to create binary masks
icb_thresh_mask = icb_prob_mask >= 0.5; % Binary mask for ICB regions
drain_thresh_mask = drain_prob_mask >= 0.5; % Binary mask for Drain regions

% Calculate the volume of the ICB regions
icb_vol = sum(icb_thresh_mask(:)); % Sum of all voxels in the binary mask

% Load and reslice the CT volume to match the dimensions of the NIfTI data
nii{2} = load_untouch_nii(input2); % Load the CT volume
nii{2} = reslice_volume(nii{2}, nii{1}, 1); % Reslice CT volume to match prediction dimensions

% Convert data types to single precision for subsequent operations
icb = single(icb_thresh_mask); % Convert ICB binary mask
dr = single(drain_thresh_mask); % Convert Drain binary mask
ct = single(nii{2}.img); % Convert resliced CT image

% Set thresholds for Drain detection and coverage profile
thresh_drain_detection = 0.9; % High-confidence threshold for drain detection
thresh_cov_profile = 0.44; % Threshold for coverage profile

% Create a high-confidence binary mask for drains
drain_thresh_detection = drain_prob_mask >= thresh_drain_detection;

% Initialize grid and edge data for processing
edges = nii{1}.edges; % Load edges from the NIfTI file
[X, Y, Z] = nifti_grid(nii{1}); % Create a grid based on the NIfTI image

% Define grid parameters for later calculations
R = [X(:)' ; Y(:)' ; Z(:)' ; X(:)'*0+1];
[t, A, B] = ndgrid(-100:0.5:100, -10:0.5:10, -10:0.5:10);

% Analyze all islands in binary masks
rprops = []; % Initialize list for region properties

% Connected component analysis for 50% and 90% thresholds
cc_50_mask = bwconncomp(dr); % Find connected components in the 50% mask
cc_90 = bwconncomp(drain_thresh_detection); % Find connected components in the 90% mask
positive_islands = []; % Initialize list for positive islands

% Compare islands in the 50% mask with the 90% mask
for i = 1:length(cc_50_mask.PixelIdxList)
  this_island = drain_thresh_detection .* 0; % Create empty mask
  this_island(cc_50_mask.PixelIdxList{i}) = 1; % Mark current island in the mask
  
  % Calculate region properties of the current island
  rp = regionprops3(this_island, 'PrincipalAxisLength', 'Volume'); 
  rprops(i,:) = [i, rp.PrincipalAxisLength, rp.Volume]; % Store properties
  
  % Check for overlap with 90% mask islands
  inter_result = [];
  for n = 1:length(cc_90.PixelIdxList)
    test = ismember(cc_50_mask.PixelIdxList{i}, cc_90.PixelIdxList{n}); % Check overlap
    inter_result(n,:) = sum(test(:)) > 0; % Record overlap results
  end
  positive_islands(i,:) = [i, sum(inter_result) > 0]; % Mark positive islands
end

% Identify true islands from the 50% mask that overlap with the 90% mask
true_islands = positive_islands(positive_islands(:,2) > 0);

% Analyze coverage profiles using connected components
dr_for_cov = drain_prob_mask >= thresh_cov_profile; % Create coverage mask
cc_cov_mask = bwconncomp(dr_for_cov); % Connected components for coverage
positive_islands = []; % Reset list for positive islands

% Compare coverage mask islands with true islands
for i = 1:length(cc_cov_mask.PixelIdxList)
  inter_result = [];
  for n = 1:length(true_islands)
    test = ismember(cc_cov_mask.PixelIdxList{i}, cc_50_mask.PixelIdxList{true_islands(n)}); % Check overlap
    inter_result(n,:) = sum(test(:)) > 0; % Record overlap results
  end
  positive_islands(i,:) = [i, sum(inter_result) > 0]; % Mark positive islands
end

% Identify true coverage islands
true_cov_islands = positive_islands(positive_islands(:,2) > 0);

% Process each true coverage island
counter = 1; % Initialize counter for output files
for i = 1:length(true_cov_islands)
  % Create binary mask for the current island
  this_island = dr_for_cov .* 0; % Initialize empty mask
  this_island(cc_cov_mask.PixelIdxList{true_cov_islands(i)}) = dr_for_cov(cc_cov_mask.PixelIdxList{true_cov_islands(i)}); % Fill island mask
  
  % Calculate drainage and bleeding distances
  image2 = single(this_island);  
  bleeding = and(icb, not(image2)); % Define bleeding region
  drainage = image2; % Define drainage region
  dbleed = bwdist(bleeding); % Distance from bleeding
  dback = bwdist(not(drainage | bleeding)); % Distance from background
  x = (dbleed < dback) .* drainage; % Identify valid regions for processing    
  
  % Analyze island geometry and profiles
  onseg = (R(:,x(:) > 0))'; % Extract coordinates of the island
  m = mean(onseg,1); % Calculate the mean position
  demean = onseg - repmat(m, [size(onseg,1) 1]); % Center data
  [U, D] = eigs(demean' * demean, 3); % Calculate Eigenvalues
  po = inv(edges) * (U(:,1)*t(:)' + U(:,2)*A(:)' + U(:,3)*B(:)' + m'); % Map to edges
  
  % Compute profile and smooth it
  ifun = @(x) mean(mean(reshape(interp3(x,po(2,:),po(1,:),po(3,:),'linear',0),[1 size(t)]),3),4);
  drain = ifun(drainage);
  profi = ifun(x) ./ (eps + drain);
  idx = find(drain);
  
  % Compute coordinates for visualizing the profile
  coords = [ifun(X .* drainage) ./ (drain + eps);
            ifun(Y .* drainage) ./ (drain + eps);
            ifun(Z .* drainage) ./ (drain + eps)];
  gau = @(x) imfilter(abs(x), fspecial('gaussian', [1 10], 1)); % Gaussian smoothing
  profi_sm = gau(profi) ./ (0.001 + gau(profi > 0));
  
  % Determine profile range for visualization
  c1 = coords(:,idx(1));
  c2 = coords(:,idx(end));
  step = 2; % Step size
  sz = 60; % Length of the profile
  delta_coords = abs(c1 - c2);
  index_max_delta = find(delta_coords == max(delta_coords));
  abs_distance_c1 = abs(centres(index_max_delta) - c1(index_max_delta));
  abs_distance_c2 = abs(centres(index_max_delta) - c2(index_max_delta));
  
  if abs_distance_c1 < abs_distance_c2 % Check which end is closer to the center
    ran = idx(1):step:idx(1) + step * sz;
  else
    ran = idx(end):-step:idx(end) - step * sz;
  end
  
  % prepare output file names
  % Extract the directory and base name (without extension)
  [input_dir, base_name, ~] = fileparts(input1);
  
  % Save results as JSON and JPEG
  out_json = fullfile(input_dir, strcat(base_name, '_profile_', num2str(counter), '.json'));
  out_jpeg = fullfile(input_dir, strcat(base_name, '_plot_', num2str(counter), '.jpeg'));
  counter = counter + 1;
  
  %create and write profile
  output_profile = profi_sm(ran); % Store smoothed profile
  ind = find(isnan(output_profile)); % Handle NaNs
  output_profile(ind) = 0;
  mat2json(output_profile, out_json); % Save profile to JSON
  
  plot(output_profile, 'linewidth', 2); % Plot profile
  axis([0 70 0 1]);
  grid on;
  drawnow;
  result_fig = gcf;
  saveas(result_fig, out_jpeg, 'jpeg'); % Save plot as JPEG
end

% set output paths for volume and all island properties
output_vol = fullfile(input_dir, strcat(base_name, '_icb_volume.json'));
output_props = fullfile(input_dir, strcat(base_name, '_properties.json'));


% Export ICB volume
mat2json(icb_vol, output_vol);

% Export island properties
mat2json(rprops, output_props);