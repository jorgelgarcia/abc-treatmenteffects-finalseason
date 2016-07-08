import pandas as pd
import numpy as np

''' 
Sampling Parameters
-------------------
seed : int
	seed for pseudo-random number generator
draws : int
	number of bootstrap draws
by : list or None
	if list, list of column names to stratify sampling
'''


def draw_index(data, size, by=None, seed=1234):
    '''sample indices from data

    Parameteters
    ------------
    data : array or dataframe
        data to be resampled
    size : int
        number of samples
    by : list
        list of columns in data to sample within, i.e.
        stratified random sampling within blocks defined
        by selected columns
    seed : int
        seed for pseudo-random number generator
    '''
    size -= 1

    np.random.seed(1234)

    data = pd.DataFrame(data)
    ix = np.array(data.index.tolist())

    N = len(data)

    if by is not None:

        assert isinstance(by, list)

        if not set(by).issubset(data.columns):
            raise ValueError('{} not in data columns'.format(by))

        cells = data[by].drop_duplicates().as_matrix()
        
        indices = [ix]
        for i in range(size):
            reindex = np.array([])
            for c in cells:
                cell_index = (data[by]==c).all(axis=1)
                N_ = cell_index.sum()
                reindex = np.hstack((reindex, np.random.choice(\
                                     data[cell_index].index,size=N_)))
            indices.append(reindex)

        return indices

    else:
        return [ix] + [np.random.choice(data.index, \
                    size=N) for i in range(size)]


