import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from pprint import pprint
from sklearn.model_selection import RandomizedSearchCV
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import accuracy_score
from sklearn import metrics
import matplotlib.pyplot as plt


dataset = pd.read_sas("ess_02.sas7bdat")
dataset.info()

dataset['gndr'] = dataset.gndr.astype('object')
dataset['mnactic'] = dataset.mnactic.astype('object')

#First: we create two data sets for numeric and non-numeric data
numerical = dataset.select_dtypes(exclude=['object'])
categorical = dataset.select_dtypes(include=['object'])

#Second: One-hot encode the non-numeric columns
onehot = pd.get_dummies(categorical)

#Third: Union the one-hot encoded columns to the numeric ones
df = pd.concat([numerical, onehot], axis=1)

# We create the X and y data sets
X = df.loc[ : , df.columns != 'y']
y = df[['y']]

# Create training, evaluation and test sets
X_train, test_X, y_train, test_y = train_test_split(X, y, test_size=.3, random_state=123)

# percentage of the classes in the training set
round(y_train['y'].value_counts()*100/len(y_train['y']), 2)

# Number of trees in random forest
n_estimators = [int(x) for x in np.linspace(start = 200, stop = 2000, num = 10)]
# Number of features to consider at every split
max_features = ['auto', 'sqrt']
# Maximum number of levels in tree
max_depth = [int(x) for x in np.linspace(10, 110, num = 11)]
max_depth.append(None)
# Minimum number of samples required to split a node
min_samples_split = [2, 5, 10]
# Minimum number of samples required at each leaf node
min_samples_leaf = [1, 2, 4]
# Method of selecting samples for training each tree
bootstrap = [True, False]
# Create the random grid
random_grid = {'n_estimators': n_estimators,
               'max_features': max_features,
               'max_depth': max_depth,
               'min_samples_split': min_samples_split,
               'min_samples_leaf': min_samples_leaf,
               'bootstrap': bootstrap}
pprint(random_grid)

# Use the random grid to search for best hyperparameters
# First create the base model to tune
rf = RandomForestRegressor()
# Random search of parameters, using 3 fold cross validation, 
# search across 100 different combinations, and use all available cores
rf_random = RandomizedSearchCV(estimator = rf, param_distributions = random_grid, n_iter = 100, cv = 3, verbose=2, random_state=42, n_jobs = -1)
# Fit the random search model
rf_random.fit(X_train, y_train)
#We can view the best parameters from fitting the random search:
rf_random.best_params_
# we make predictions
best_random = rf_random.best_estimator_
predictions = pd.DataFrame(best_random.predict(test_X))
#We calculate the AUC
fpr, tpr, thresholds = metrics.roc_curve(test_y, predictions, pos_label=3)
metrics.auc(fpr, tpr)
# get importance
importance = best_random.feature_importances_
# summarize feature importance
var_importance = pd.DataFrame({'col_name': best_random.feature_importances_}, index=X_train.columns).sort_values(by='col_name', ascending=False)
# plot feature importance
importance = pd.DataFrame({'col_name': best_random.feature_importances_})
index = np.array(X_train.columns)
pyplot.bar(index, importance)
pyplot.show()

