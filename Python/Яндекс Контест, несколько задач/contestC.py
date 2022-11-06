from datetime import datetime
from collections import deque
with open("input.txt") as input:
	t_crit, e_crit = list(map(int, input.readline().split()))
	q = deque(maxlen = e_crit)
	solved = False
	for line in input.readlines():
		if line[22] == 'E':
			time = line.split(' ')
			time = list(map(int, time[0][1:].split('-') + time[1][:-1].split(':')))
			secs = datetime(*time).timestamp()
			while len(q):
				t_prev = q.popleft()
				if t_prev + t_crit > secs:
					q.appendleft(t_prev)
					break
			if len(q) == e_crit - 1:
				print(' '.join((line.split(' '))[:2])[1:-1])
				solved = True
				break
			q.append(secs)
	if not solved:
		print(-1)

	# with open("output.txt", "w") as output:
	# 	output.write(str(result))
