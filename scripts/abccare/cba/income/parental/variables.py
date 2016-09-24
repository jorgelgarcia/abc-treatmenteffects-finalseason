# -*- coding: utf-8 -*-
"""
Created on Fri Jun 10 19:22:00 2016

@author: jkcshea

This file just lists all the variables that are used for interpolation,
extrapolation, and the weights.
"""

from treedict import TreeDict

cols = TreeDict()

# Interpolation ---------------------------------------------------------------
# Note: interpolation is done differently than subject income
# Interpolation does not use auxiliar sample. It is a straight linear interpolation.

cols.interpABC.background = ['male', 'm_ed0y', 'black', 'p_inc0y','m_id', 'male_subject', 'p_income_mean', 'p_income_last', 'last_age']
cols.interpABC.outcomes = ['inc_labor13', 'inc_labor14', 'inc_labor15', 'inc_labor16', 'inc_labor17', 'inc_labor18', 'inc_labor19', 'inc_labor20', 'inc_labor21', 'inc_labor22', 'inc_labor23', 'inc_labor24', 'inc_labor25', 'inc_labor26', 'inc_labor27', 'inc_labor29', 'inc_labor30', 'inc_labor31', 'inc_labor34', 'inc_labor36', 'inc_labor37', 'inc_labor44', 'inc_labor28', 'inc_labor32', 'inc_labor35', 'inc_labor38', 'inc_labor45', 'inc_labor33', 'inc_labor39', 'inc_labor46', 'inc_labor40', 'inc_labor47', 'inc_labor41', 'inc_labor48', 'inc_labor42', 'inc_labor49', 'inc_labor52', 'inc_labor43', 'inc_labor56', 'inc_labor51', 'inc_labor59', 'inc_labor50', 'inc_labor55', 'inc_labor57', 'inc_labor58', 'inc_labor65']
cols.interpABC.predictors = cols.interpABC.background + cols.interpABC.outcomes
cols.interpABC.keep = cols.interpABC.predictors

# Extrapolation --------------------------------------------------------------

#cols.extrapABC.background = ['male', 'black', 'm_ed0y', 'p_inc0y']
#cols.extrapABC.outcomes = ['p_inc21y']
#cols.extrapABC.weight = ['wtabc_allids']
#cols.extrapABC.predictors = cols.extrapABC.background + cols.extrapABC.outcomes
#cols.extrapABC.keep = cols.extrapABC.predictors

# Forecasting Variables ------------------------------------------------------
#baseline = ['cohort', 'hh_sibs0y', 'm_iq0y', 'hrabc_index']
#outcomes = ['si21y_inc_labor', 'si30y_inc_labor', 'si21y_inc_trans_pub', 'si30y_inc_trans_pub']


# Interpolation ---------------------------------------------------------------

#cols.interp.background = ['male', 'black', 'm_ed0y']
#cols.interp.outcomes = ['inc_labor20', 'inc_labor21', 'inc_labor22', 'inc_labor23', 'inc_labor24', 'inc_labor25', 'inc_labor26', 'inc_labor27', 'inc_labor29', 'inc_labor30']
#cols.interp.weight = ['wtabc_allids']
#cols.interp.predictors = cols.interp.background + cols.interp.outcomes
#cols.interp.keep = cols.interp.predictors

# Extrapolation --------------------------------------------------------------

cols.extrap.background = ['male', 'black']
cols.extrap.outcomes = ['inc_labor20', 'inc_labor21', 'inc_labor22', 'inc_labor23', 'inc_labor24', 'inc_labor25', 'inc_labor26', 'inc_labor27', 'inc_labor28', 'inc_labor29', 'inc_labor30', 'inc_labor31', 'inc_labor32', 'inc_labor33', 'inc_labor34', 'inc_labor35', 'inc_labor36', 'inc_labor37', 'inc_labor38', 'inc_labor39', 'inc_labor40', 'inc_labor41', 'inc_labor42', 'inc_labor43', 'inc_labor44', 'inc_labor45', 'inc_labor46', 'inc_labor47', 'inc_labor48', 'inc_labor49', 'inc_labor50', 'inc_labor51', 'inc_labor52', 'inc_labor53', 'inc_labor54', 'inc_labor55', 'inc_labor56', 'inc_labor57', 'inc_labor58', 'inc_labor59', 'inc_labor60', 'inc_labor61', 'inc_labor62', 'inc_labor63', 'inc_labor64', 'inc_labor65', 'inc_labor66', 'inc_labor67']
cols.extrap.predictors = cols.extrap.background + cols.extrap.outcomes
cols.extrap.keep = cols.extrap.predictors + ['male_subject']

