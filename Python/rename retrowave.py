import os, re
current = {}
for line in open('Retrowave.m3u8'):
	if 'EXTINF' in line:
		current = re.search(r'-1,(?P<artist>.*)\s{2}(?P<song>.*)', line)
	if 'https' in line:
		filename = re.search(r'([\d\w]+\.mp3)$', line).group(0)
		if os.path.isfile(filename):
			newfilename = current.group('artist')+' - '+current.group('song')+'.mp3'
			newfilename = ''.join(c for c in newfilename if c not in '<>:"/\\|?*')
			os.rename(filename, newfilename)
