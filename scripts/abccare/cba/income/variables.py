# -*- coding: utf-8 -*-
"""
Created on Fri Jun 10 19:22:00 2016

@author: jkcshea

This file just lists all the variables that are used for interpolation,
extrapolation, and the weights.
W = background
X = outcomes
"""

from treedict import TreeDict

cols = TreeDict()

# Interpolation ---------------------------------------------------------------

cols.interp.black = ['black']
cols.interp.background = ['male', 'm_ed0y']
cols.interp.outcomes = ['si21y_inc_labor', 'si30y_inc_labor', 'years_30y', 'piatmath', 'si34y_bmi']
cols.interp.weight = ['wtabc_allids']
cols.interp.predictors = cols.interp.background + cols.interp.outcomes
cols.interp.keep = cols.interp.predictors + cols.interp.black

# Extrapolation --------------------------------------------------------------

cols.extrap.black = ['black']
cols.extrap.background = ['male']
cols.extrap.outcomes = ['years_30y', 'si30y_inc_labor']
cols.extrap.weight = ['wtabc_allids']
cols.extrap.predictors = cols.extrap.background + cols.extrap.outcomes
cols.extrap.keep = cols.extrap.predictors + cols.extrap.black
# Forecasting Variables ------------------------------------------------------
baseline = ['cohort', 'hh_sibs0y', 'm_iq0y', 'hrabc_index']
outcomes = ['si21y_inc_labor', 'si30y_inc_labor', 'si21y_inc_trans_pub', 'si30y_inc_trans_pub']
