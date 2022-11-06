from os import walk, getcwd

(_, albums, _) = next(walk(getcwd() + '/snd/albums'))
for album in albums:
	(_, _, songs) = next(walk(getcwd() + '/snd/albums/' + album))
	print(album)
	for song in songs:
		print(f'<option value="{"""/snd/albums/""" + album + """/""" + song}">{song[:-4]}</option>')