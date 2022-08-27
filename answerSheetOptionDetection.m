img = imread("image/测试图3.jpg");
I = rgb2gray(img);
bw = edge(I, 'canny', 0.3); % bw is logical 二值图

figure(1); imshow(bw);

[H, T, R] = hough(bw); % H为二值图经过霍夫变换后得到的矩阵，即参数空间矩阵
P = houghpeaks(H, 8); % P为参数矩阵的极大值点的坐标，对应图像空间直线参数方程的ρ和θ
% 线段合并，舍弃，提取
lines = houghlines(bw, T, R, P, 'FillGap', 500, 'Minlength', 7);

figure(2); imshow(I);
hold on;
	for	k = 1:length(lines)
		xy = [lines(k).point1; lines(k).point2];
		plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
		plot(xy(1,1), xy(1,2), 'x', 'LineWidth', 2, 'Color', 'yellow');
		plot(xy(2,1), xy(2,2), 'x', 'LineWidth', 2, 'Color', 'red');
	end
hold off;

% 找直线交点
% 将各个点坐标拼接为1个数组  结构体->数组
p1 = cat(1, lines.point1); % https://baike.baidu.com/item/cat/4623515?fr=aladdin
p2 = cat(1, lines.point2);
pcnt = size(p1, 1); pselect = []; cnt = 0;
for i = 1:pcnt-1
	for j = i:pcnt
		a.x = p1(i, 1); a.y = p1(i, 2); b.x = p2(i, 1); b.y = p2(i, 2);
		c.x = p1(j, 1); c.y = p1(j, 2); d.x = p2(j, 1); d.y = p2(j, 2);
		dnm = (b.y - a.y)*(d.x - c.x) - (b.x - a.x)*(d.y - c.y);
		if abs(dnm) < 200
			continue;
		end
		% 已知四个点求交点
		x = ((b.x - a.x) * (d.x - c.x) * (c.y - a.y) + (b.y - a.y) * (d.x - c.x) * a.x ...
					- (d.y - c.y) * (b.x - a.x) *	c.x) / dnm;
		y = -((b.y - a.y) * (d.y - c.y) * (c.x - a.x) + (b.x - a.x) * (d.y - c.y) * a.y ...
					- (d.x - c.x) * (b.y - a.y) * c.y) / dnm;
		cnt = cnt + 1;
		pselect(cnt, 1:2) = [x y];
	end
end
figure(3); imshow(bw);
hold on; plot(pselect(:, 1), pselect(:, 2), 'r+'); hold off;
% 交点过滤
pselect = round(pselect); pcorner = []; ccnt = 0;
[bbox, ROIbw] = getmaxROI(bw);
for i = 1:cnt
	if pselect(i, 1) > 0 && pselect(i, 1) <= bbox(3)+10 && pselect(i, 2) > 0 && pselect(i, 2) <= bbox(4)+10
		 ccnt = ccnt + 1;
		 pcorner(ccnt, 1:2) = pselect(i, 1:2);
	end
end
figure(4); imshow(bw); % bw(bbox(2):bbox(4), bbox(1):bbox(3))
hold on; plot(pcorner(:, 1), pcorner(:, 2), 'r+'); hold off;

% 确定4个顶点
loccir = mean(pcorner(:, :));
% 质心做原点
disxy(:, 1) = pcorner(:, 1) - loccir(1);
disxy(:, 2) = pcorner(:, 2) - loccir(2);
disflag = disxy>0;
% 0+3 1+3 0+1 1+1
ind = xor(disflag(:, 1), disflag(:, 2)) + disflag(:, 2) * 2 + 1; 
for i=1:4
	flag = ind==i;
	tempoints = pcorner(flag,:);
	dis = (tempoints(:, 1) - loccir(1)).^2 + (tempoints(:, 2) - loccir(2)).^2;
	% 返回第一个距离为最大距离的下标（该点）
	pidx = find(dis == max(dis), 1, 'first');
	ROIpoints(i, :) = tempoints(pidx, :);
end
figure(5); imshow(bw);
hold on; plot(ROIpoints(:, 1), ROIpoints(:, 2), 'r+'); hold off;
% 变换 变换矩阵 x是列数，y是行数
x = ROIpoints(:, 2); y = ROIpoints(:, 1);
width = round(max(x) - min(x)); height = round(max(y) - min(y));
Y(1) = min(y); Y(4) = Y(1); Y(2:3) = Y(1) + height;
X(1:2) = min(x); X(3:4) = X(1) + width;
% 变换矩阵
tform = fitgeotrans(ROIpoints, [Y' X'], 'Projective'); % https://blog.csdn.net/xiamentingtao/article/details/50810121
% 输出视图
output = imref2d(size(I)); % 将图片放到世界坐标系下，即标上刻度
% 将变化矩阵应用到输入图像，并呈现在输出视图上
Is = imwarp(I, tform, 'OutputView', output);
figure(6); imshow(Is);

bw = edge(Is, 'canny', 0.2);

% 答题框 轮廓线可以框出答题部分
[bbox, ROI] = getmaxROI(bw);
ROIbw = bw(bbox(2):bbox(4), bbox(1):bbox(3));
ROIimg = Is(bbox(2):bbox(4), bbox(1):bbox(3));
%figure(1); imshow(ROI);
%figure(2); imshow(ROIbw);
%figure(3); imshow(ROIimg);

% 选择题 选择题部分用百色的更多的面积得到
[bbox1, ROI1] = getmaxROI(~ROIbw);
ROIbwselect = ROIbw(bbox1(2):bbox1(4), bbox1(1):bbox1(3));
ROIimgselect = ROIimg(bbox1(2):bbox1(4), bbox1(1):bbox1(3));
figure(7); imshow(ROIbwselect);
figure(8); imshow(ROIimgselect);

% 将涂抹痕迹转化为选择结果
[L, num] = bwlabel(ROIbwselect);
cnt = 0; cir = zeros(num, 2);
[row, col] = size(ROIbwselect); radiomx = 1/30; radiomn = 1/35;
for i = 1:num
	[y, x] = find(L==i);
	area = size(x, 1); w = max(x) - min(x); h = max(y) - min(y);
	if w > col*radiomx || h > row*radiomx || w < col*radiomn
		ROIbwselect(L==i) = 0;
	else
		w
		cnt = cnt + 1;
		cir(cnt, 1:2) = [mean(x) mean(y)];
	end
end
figure(9); imshow(ROIbwselect);
% https://wenku.baidu.com/view/2a4e67538d9951e79b89680203d8ce2f00666533.html
hold on; plot(cir(1:cnt, 1), cir(1:cnt, 2), 'r+'); hold off;

for i = 1:cnt
	fprintf("%d:\n", i);
	t = ceil(mod(col/4, cir(i, 1)) / (col/16)); % https://blog.csdn.net/xiamentingtao/article/details/52593648
	if t == 1
		disp('A');
	elseif t == 2
		disp('B');
	elseif t == 3
		disp('C');
	else 
		disp('D');
	end
end
