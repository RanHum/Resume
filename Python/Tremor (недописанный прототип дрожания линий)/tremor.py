import numpy as np
from numpy.lib.type_check import imag
from scipy import ndimage as ndi
from scipy.ndimage.filters import median_filter
from skimage import filters, morphology, io
import matplotlib.pyplot as plt
from math import ceil
import perlin_numpy
from lazyarray import larray
from skimage.color.colorconv import gray2rgb, rgb2gray

from functools import wraps
from time import process_time

def timing(f):
	@wraps(f)
	def wrap(*args, **kw):
		process_time()
		result = f(*args, **kw)
		print('func:%r args:[%r, %r] took: %2.4f sec' % (f.__name__, args, kw, process_time()))
		return result
	return wrap

def interpolant(t):
	return t*t*t*(t*(t*6 - 15) + 10)

@timing
def generate_perlin_noise_2d(
		shape, res, tileable=(False, False), interpolant=interpolant
):
	"""Generate a 2D numpy array of perlin noise.
	Args:
		shape: The shape of the generated array (tuple of two ints).
			This must be a multple of res.
		res: The number of periods of noise to generate along each
			axis (tuple of two ints). Note shape must be a multiple of
			res.
		tileable: If the noise should be tileable along each axis
			(tuple of two bools). Defaults to (False, False).
		interpolant: The interpolation function, defaults to
			t*t*t*(t*(t*6 - 15) + 10).
	Returns:
		A numpy array of shape shape with the generated noise.
	Raises:
		ValueError: If shape is not a multiple of res.
	"""

	# set pixel metrics and map
	delta = (res[0] / shape[0], res[1] / shape[1])
	d = (shape[0] // res[0], shape[1] // res[1])
	grid = np.mgrid[0:res[0]:delta[0], 0:res[1]:delta[1]]\
			 .transpose(1, 2, 0) % 1
	# Gradients
	angles = 2*np.pi*np.random.rand(res[0]+1, res[1]+1)
	gradients = np.dstack((np.cos(angles), np.sin(angles)))
	if tileable[0]:
		gradients[-1,:] = gradients[0,:]
	if tileable[1]:
		gradients[:,-1] = gradients[:,0]
	gradients = gradients.repeat(d[0], 0).repeat(d[1], 1)
	g00 = gradients[    :-d[0],    :-d[1]]
	g10 = gradients[d[0]:     ,    :-d[1]]
	g01 = gradients[    :-d[0],d[1]:     ]
	g11 = gradients[d[0]:     ,d[1]:     ]
	# Ramps
	n00 = np.sum(np.dstack((grid[:,:,0]  , grid[:,:,1]  )) * g00, 2)
	n10 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1]  )) * g10, 2)
	n01 = np.sum(np.dstack((grid[:,:,0]  , grid[:,:,1]-1)) * g01, 2)
	n11 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1]-1)) * g11, 2)
	# Interpolation
	t = interpolant(grid) # w in (a1 - a0) * w + a0
	n0 = n00*(1-t[:,:,0]) + t[:,:,0]*n10
	n1 = n01*(1-t[:,:,0]) + t[:,:,0]*n11
	return np.sqrt(2)*((1-t[:,:,1])*n0 + t[:,:,1]*n1)

@timing
def generate_perlin_disturb(shape, cells_n):
	def value(x, y):
		inter = lambda t: t*t*t*(t*(t*6 - 15) + 10)
		# inter = lambda t: t
		x0 = x//delta[0]
		y0 = y//delta[1]
		# dist = lambda c, d: (c % d) / d
		# print(type(x))
		dist = lambda c, d: (c - float(c//d)*d)/d
		wx = inter(dist(x, delta[0]))
		wy = inter(dist(y, delta[1]))
		# wx = inter(x - x0*delta[0])
		# wy = inter(y - y0*delta[1])
		# print(x)
		# g = gradients[x//delta[0], y//delta[1]: x//delta[0] + 1, y//delta[1] + 1]
		# vx = (g[0, 0, 0] + g[0, 1, 0])*wx + (g[1, 0, 0] + g[1, 1, 0])*(1 - wx)
		# vy = (g[0, 0, 1] + g[1, 0, 1])*wy + (g[0, 1, 1] + g[1, 1, 1])*(1 - wy)
		vx = (g[x0, y0, 0] + g[x0, y0 + 1, 0])*wx + (g[x0 + 1, y0, 0] + g[x0 + 1, y0 + 1, 0])*(1 - wx)
		vy = (g[x0, y0, 1] + g[x0 + 1, y0, 1])*wy + (g[x0, y0 + 1, 1] + g[x0 + 1, y0 + 1, 1])*(1 - wy)
		# print(z)
		# return vx
		return (vx, vy)
	delta = (shape[0] // cells_n[0], shape[1] // cells_n[1])
	angles = 2*np.pi*np.random.rand(cells_n[0] + 1, cells_n[1] + 1)
	# gradients = np.dstack((np.cos(angles), np.sin(angles)))
	g = np.dstack((np.cos(angles), np.sin(angles)))
	# return np.fromfunction(value, shape)
	# return larray(value, shape=shape, dtype=float)
	# array = [[None]*shape[1]]*shape[0]
	array = []
	for i in range(shape[0]*shape[1]):
		# print(i//shape[0], i%shape[1])
		array.append(value(i//shape[1], i%shape[1]))
	return np.array(array).reshape((*shape, 2))

def roundup_shape(shape, period):
	def _roundup(num):
		return ceil(num / period) * period
	return tuple(map(_roundup, shape[:-1]))

@timing
def tremor(image, edges, noise):
	def _tremor(i):
		if edges[i]:
			return noise[i]
		else:
			return image[i]
	image = image.reshape(-1, 3)
	edges = edges.reshape(-1)
	noise = ((noise/2 + 0.5) * 255).reshape(-1, 3).astype(int)
	result = list(image)
	for i in range(len(result)):
		# print(edges[i], image[i], noise[i])
		if edges[i]:
			result[i] = noise[i]
		else:
			result[i] = image[i]
		# result[i] = _tremor(i)
	result = np.array(result).reshape(sh)
	# print(result.shape)
	return result
	# print(dir(p))
	# return gray2rgb(noise_mask)


fig, ax = plt.subplots(nrows=1, ncols=5, figsize=(12, 7))

image_orig = io.imread('neko-victor.jpg')
edges = filters.prewitt(rgb2gray(image_orig))
threshold = filters.threshold_mean(edges)
# print(threshold)
edges = edges > threshold/1.2
edges = morphology.dilation(edges, morphology.square(5))
sh = image_orig.shape
tiles = 10
noise_mask = generate_perlin_noise_2d(roundup_shape(image_orig.shape, tiles), (tiles, tiles))
noise_mask = gray2rgb(noise_mask[:image_orig.shape[0], :image_orig.shape[1]])
merged_orig = ((255 - gray2rgb(edges)).astype(float)/255 * image_orig).astype(int)
merged_mask = (gray2rgb(edges) * noise_mask * 255).astype(int)
merged1 = merged_orig + merged_mask
merged2 = image_orig + merged_mask
# noise_mask2 = generate_perlin_disturb(roundup_shape(image_orig.shape, tiles), (tiles, tiles))
# print(noise_mask2.evaluate().astype(float))
# print(noise_mask2.shape)
# print((255 - gray2rgb(edges)).astype(float)/255)
# print((gray2rgb(edges) * noise_mask * 255).astype(int))
# print(np.fromiter(((x,x,x) for x in edges), edges.dtype).shape)
# merged = np.choose(np.fromiter(((x,x,x) for x in edges), edges.dtype), [image_orig, gray2rgb(noise_mask)])

def set_pic(i, pic):
	ax[i].imshow(pic)
	ax[i].axis("off")

set_pic(0, image_orig)
set_pic(1, edges)
set_pic(2, noise_mask)
# set_pic(3, gray2rgb(noise_mask2.evaluate()[:-1,:,:].transpose(1, 2, 0).reshape((1270, 850)) / 2 + 0.5))
# set_pic(3, gray2rgb(noise_mask2[:,:,:-1].reshape((1270, 850)) / 2 + 0.5))
set_pic(3, tremor(image_orig, edges, noise_mask))
set_pic(4, image_orig * edges.reshape((*edges.shape, 1)).repeat(3, 2))

fig.tight_layout()
fig.canvas.toolbar.pack_forget()
plt.get_current_fig_manager().window.state('zoomed')
plt.show()