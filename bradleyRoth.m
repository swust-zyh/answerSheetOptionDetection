% https://stackoverflow.com/questions/30487127/extract-a-page-from-a-uniform-background-in-an-image/30496377#30496377
function [out] = bradleyRoth(im, s, t)

%// Error checking of the input
%// Default value for s is 1/8th the width of the image
%// Must make sure that this is a whole number
if nargin <= 1, s = round(size(im,2) / 8); end

%// Default value for t is 15
%// t is used to determine whether the current pixel is t% lower than the
%// average in the particular neighbourhood
if nargin <= 2, t = 15; end

%// Too few or too many arguments?
if nargin == 0, error('Too few arguments'); end
if nargin >= 4, error('Too many arguments'); end

%// Convert to grayscale if necessary then cast to double to ensure no
%// saturation
if size(im, 3) == 3
    im = double(rgb2gray(im));
elseif size(im, 3) == 1
    im = double(im);
else
    error('Incompatible image: Must be a colour or grayscale image');
end

%// Compute integral image
intImage = cumsum(cumsum(im, 2), 1);

%// Define grid of points
[rows, cols] = size(im);
[X,Y] = meshgrid(1:cols, 1:rows); %index

%// Ensure s is even so that we are able to index the image properly
s = s + mod(s,2);

%// Access the four corners of each neighbourhood
% make the kernel size is even
x1 = X - s/2; x2 = X + s/2;
y1 = Y - s/2; y2 = Y + s/2;

%// Ensure no co-ordinates are out of bounds
x1(x1 < 1) = 1;
x2(x2 > cols) = cols;
y1(y1 < 1) = 1;
y2(y2 > rows) = rows;

%// Count how many pixels there are in each neighbourhood
% x is center, the kernel have how many pixels
count = (x2 - x1) .* (y2 - y1);

%// Compute row and column co-ordinates to access each corner of the
%// neighbourhood for the integral image
f1_x = x2; f1_y = y2;
f2_x = x2; f2_y = y1 - 1; f2_y(f2_y < 1) = 1;
f3_x = x1 - 1; f3_x(f3_x < 1) = 1; f3_y = y2;
f4_x = f3_x; f4_y = f2_y;

%// Compute 1D linear indices for each of the corners
% sub2ind: https://blog.csdn.net/u011624019/article/details/80345717
ind_f1 = sub2ind([rows cols], f1_y, f1_x);
ind_f2 = sub2ind([rows cols], f2_y, f2_x);
ind_f3 = sub2ind([rows cols], f3_y, f3_x);
ind_f4 = sub2ind([rows cols], f4_y, f4_x);

%// Calculate the areas for each of the neighbourhoods
sums = intImage(ind_f1) - intImage(ind_f2) - intImage(ind_f3) + ...
    intImage(ind_f4);

%// Determine whether the summed area surpasses a threshold
%// Set this output to 0 if it doesn't
locs = (im .* count) <= (sums * (100 - t) / 100); % two value change
% locs is index
out = true(size(im));
out(locs) = false;

end