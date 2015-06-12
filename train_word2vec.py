__author__ = 'rwechsler'

import gensim
import sys
import glob
from corpus_reader import CorpusReader



class Dataset():

    def __init__(self, files):
        self.files = files

    def __iter__(self):
        for f in self.files:
            print "Reading file ", f
            cr = CorpusReader(f, max_limit=10)
            for sentence in cr:
                yield sentence


files = glob.glob(sys.argv[1])
outfile_name = sys.argv[2]


dataset = Dataset(files)

model = gensim.models.Word2Vec(dataset, size=500, window=5, min_count=3, negative=5, workers=2)

model.save(outfile_name)











