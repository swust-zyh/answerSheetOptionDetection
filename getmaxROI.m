function [bbox, ROIbw]=getmaxROI(bw)
	[L, num] = bwlabel(bw);
	max_area = 0; bboxn = size(num, 4);
	center = zeros(num, 2); % 质心: x,y方向上，每个点的贡献/总数
	for i = 1:num
		[y, x] = find(L==i); % x,y为列向量
		bboxn(i, 1:4) = [min(x) min(y) max(x) max(y)]; % 外接矩形框
		area = size(x, 1); % 有多少个点
		center(i, 1:2) = [mean(x) mean(y)];
		if area > max_area
			max_area = area;
			pos = i;
		end
	end
	bbox = bboxn(pos, :);
	ROIbw = L==pos; % 只将标记为pos的连通域呈现出来
end