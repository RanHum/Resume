from os import walk, getcwd

(_, _, filenames) = next(walk(getcwd() + '/img/gallery'))
print(filenames)