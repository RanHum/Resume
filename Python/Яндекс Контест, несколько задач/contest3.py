from collections import deque
with open("input.txt") as input:
	decl = input.readline().split()
	n = int(decl[0])
	k = int(decl[1])
	result = ''
	a = [None] * n
	a_addr = [None] * n
	a_result = [None] * n
	i = 0
	for ai in map(int, input.readline().split()):
		a[i] = (i, ai)
		i += 1
	a.sort(key=lambda x: x[1])
	base = deque([abs(a[j][1] - a[0][1]) for j in range(1, k+1)])
	base_dist = sum(base)
	base_count = k
	base_center = 0
	a_result[0] = base_dist
	for i in range(1, n):
		if i > k:
			base.popleft()
		diff = a[i][1] - a[i-1][1]
		for j in range(base_count - 1):
			base[j] += diff
		
		



		for i_base in range(max(i_sort-k, 0), min(i_sort + k + 1, n)):
			base_count += 1
			base_a.append(abs(a[i_sort][1] - a[i_base][1]))
			base_dist += base_a[-1]
		min_dist = base_dist - sum(base_a[:base_count-k])
		cur_dist = min_dist
		
		for lshift in range(1, -k+1):
			cur_dist += base_a[base_count-k-lshift] - base_a[-lshift]
			if cur_dist < min_dist:
				min_dist = cur_dist
		
		a_result[a[i_sort][0]] = str(min_dist)
	
	with open("output.txt", "w") as output:
		output.write(' '.join(a_result))
		
	# for current in range(n):
	# 	min_dist = -1
	# 	i_sort = current
	# 	i_sort = -1
	# 	for j in range(n):
	# 		if a[j][0] == current:
	# 			i_sort = j
	# 			break
	# 	base_dist = 0
	# 	base_count = -1
	# 	base_a = []
	# 	for i_base in range(max(i_sort-k, 0), min(i_sort + k + 1, n)):
	# 		base_count += 1
	# 		base_a.append(abs(a[i_sort][1] - a[i_base][1]))
	# 		base_dist += base_a[-1]
	# 	min_dist = base_dist - sum(base_a[:base_count-k])
	# 	cur_dist = min_dist
	# 	for lshift in range(1, base_count-k+1):
	# 		cur_dist += base_a[base_count-k-lshift] - base_a[-lshift]
	# 		if cur_dist < min_dist:
	# 			min_dist = cur_dist
	# 	result += ' '+ str(min_dist)
	# with open("output.txt", "w") as output:
	# 	output.write(result[1:])
