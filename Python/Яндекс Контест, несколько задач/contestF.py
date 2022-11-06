from queue import PriorityQueue
with open("input.txt") as input:
	reqs, size = list(map(int, input.readline().split()))
	cache = {}
	times = PriorityQueue()
	for i, line in enumerate(input.readlines()):
		item, t = line.split(' ')
		t = int(t)
		t_last = cache.get(item, 0)
		if t_last:
			if t > t_last:
				cache[item] = t
				times.put((t, item))
				print(i+1, 'UPDATE '+ item)
		else:
			while len(cache) == size and not times.empty():
				t_last, item_last = times.get()
				# print('times: ',t_last, item_last)
				if cache.get(item_last, 0) == t_last and t_last < t:
					del(cache[item_last])
					print(i+1, 'DELETE '+ item_last)
				elif t_last > t:
					times.put((t_last, item_last))
					break
			if len(cache) < size:
				cache[item] = t
				times.put((t, item))
				print(i+1, 'PUT '+ item)


			# if len(cache) == size and times.empty():
			# 	item_last = min(cache, key=cache.get)
			# 	if cache.get(item_last, 0) < t:
			# 		del(cache[item_last])
			# 		print(i+1, 'DELETE '+ item_last)
	# print(cache)
	# while not times.empty():
	# 	item = times.get()
	# 	print(item)
	# with open("output.txt", "w") as output:
	# 	output.write(str(result))
