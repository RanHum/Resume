from array import array
with open("input.txt") as filenames:
	market_f, billing_f = filenames.readline().split()
	# markets = {}
	markets = array('b')
	# offsets = array('H')
	# lengths = array('H')
	count = 0
	d = {}
	# markets.__setitem__(30,'a')
	# print(markets.__getitem__(30))
	def set(a, i, s):
		for ci, char in enumerate(s.encode('ascii')):
			# a.__setitem__(i + ci, char)
			a.append(char)
		# print(str(a))
	def get(a, i, c):
		# print(i, c)
		return ''.join([chr(a.__getitem__(ind)) for ind in range(i, i+c)]).strip()
	def seti(a, i, int):
		global count
		while i >= count:
			offsets.append(0)
			lengths.append(0)
			count += 1
		return a.__setitem__(i, int)
	def geti(a, i):
		return a.__getitem__(i)
	# markets.extend()
	# markets = ['']*10**6
	with open(market_f) as input:
		input.readline()
		offset_last = 0
		for line in input.readlines():
			shop_id, shop_name = line.split(',')
			shop_id = int(shop_id)
			shop_name = shop_name.strip()
			# markets[int(shop_id*30)] = shop_name.strip()
			set(markets, offset_last, shop_name)
			d[shop_id] = (offset_last, len(shop_name))
			# seti(offsets, shop_id, offset_last)
			# seti(lengths, shop_id, len(shop_name))
			offset_last += len(shop_name)
			
	with open("output.txt", "w") as output:
		output.write('order_id,shop_name,shop_id,cost\n')
		with open(billing_f) as input:
			input.readline()
			for line in input.readlines():
				order_id, shop_id, cost = line.split(',')
				# shop_name = markets[int(shop_id)]
				# shop_name = get(int(shop_id))
				shop_id = int(shop_id)
				# if shop_id > count:
				if not d.get(shop_id, 0):
					continue
				# shop_name = get(markets, geti(offsets, shop_id), geti(lengths, shop_id))
				shop_name = get(markets, *d[shop_id])
				# print(shop_name)
				if shop_name:
					output.write(','.join([order_id,shop_name,str(shop_id),cost]))
