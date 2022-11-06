from youtube_dl import YoutubeDL as ydl
import sys, os, shelve, requests

# a little bit of sorcery to make youtube-dl to scrape only initial page
json_proc = sys.modules['youtube_dl'].extractor.common.InfoExtractor._download_json
def ydl_max_pages(max_pages=0):
	def hook(*args, **kwargs):
		if f'Downloading page {max_pages}' in args:
			return False
		return json_proc(*args, **kwargs)
	sys.modules['youtube_dl'].extractor.common.InfoExtractor._download_json = hook

def iterate_channel(channel):
	feed = ydl({'ignoreerrors': True}).extract_info(f'https://www.youtube.com/channel/{channel}/videos?sort=dd', process=False)
	return feed and feed['entries'] or []

def get_video_data(id):
	data = ydl({'ignoreerrors': True}).extract_info('https://www.youtube.com/watch?v='+id, process=False)
	# delete big fields
	return {k:v for (k,v) in data.items() if k not in ['automatic_captions', 'formats', 'description']}

def init_channel(channel_id, known_item=0):
	db['channels'][channel_id] = get_video_data(list(iterate_channel(channel_id))[known_item]['id'])
	db.sync()

def get_updates(channel, last_video):
	for video in iterate_channel(channel):
		# print(video['id'], last_video['id'])
		if video['id'] != last_video['id']:
			video_data = get_video_data(video['id'])
			# print(video_data['upload_date'], last_video['upload_date'])
			if video_data['upload_date'] >= last_video['upload_date']:
				yield video_data
				continue
		break

def process_updates(channel, last_video):
	db_updated = False
	for video in get_updates(channel, last_video):
		broadcast_update(video)
		if not db_updated:
			db['channels'][channel] = video
			db.sync()
			db_updated = True

info_template = ['title', 'uploader', 'webpage_url']

def broadcast_update(video):
	# print(video)
	info = {key:video[key] for key in info_template}
	thumb_filename = os.path.dirname(__file__) + '/thumb.webp'
	# fetch thumbnail
	try:
		thumb = open(thumb_filename, 'wb+').write(requests.get(video['thumbnails'][-2]['url']).content)
	except Exception as e:
		print(e)
	# actual broadcast
	for user in get_subscribers(video['channel_id']):
		post_update(user, info, thumb)
	# cleanup thumbnail
	try:
		os.remove(thumb_filename)
	except Exception as e:
		print(e)

# just a couple of dummies to make things look whole

def post_update(user, info, thumb):
	print(f'Hi there, have an update for ya, {user}:\n{info["uploader"]} has published a new video <{info["title"]}>, you can watch it here: {info["webpage_url"]}')

def get_subscribers(channel_id):
	return ['abUser']

with shelve.open('db', writeback=True) as db:
	# database init
	if not db.get('channels'):
		db['channels'] = {}

	ydl_max_pages(1)

	init_channel('UC6uFoHcr_EEK6DgCS-LeTNA', 3) # treat last 3 videos as new initially, just for the test

	# scheduling will be done later with bot integration
	for channel, last_video in db['channels'].items():
		# print(channel, '->', last_video)
		# print({key:len(str(value)) for key, value in last_video.items()})
		process_updates(channel, last_video)