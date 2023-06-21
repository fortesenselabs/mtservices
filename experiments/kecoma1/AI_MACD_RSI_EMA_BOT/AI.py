import pickle
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import cross_val_score

FILENAME = 'data.csv'

def fix_line(line, is_header=False):
    """Function to fix a line.
       Función para corregir una línea.
    Args:
        line (string): Line to correct.
                       Línea a corregir.
        is_header (bool, optional): 
            To know if we are fixing the header. Defaults to False.
            Para saber si estamos corrigiendo la cabecera. Por defecto False.
    Returns:
        string: 
            Corrected line.
            Línea corregida.
    """
    line = line.replace('\n', '')
    line = line.replace('ÿþ', '')
    line = line.split(',')
    line = [ elem.replace('\x00', '') for elem in line ]
    if not is_header: line = [ float(elem) for elem in line ]
    return line

# Openning the file in the correct encoding
# Abriendo el archivo con la codificación correcta
with open(FILENAME, encoding="cp1252") as f:
    lines = f.readlines()
    
    # Loading the header
    # Cargando el header
    header = fix_line(lines[0], is_header=True)
    
    # Loading the data
    # Cargando los datos
    data = []
    for i, line in enumerate(lines[2:-1]):
        if i%2 == 0 and line != '':
            data.append(fix_line(line))

# Creating a pandas dataframe
# Creando un dataframe de pandas            
df = pd.DataFrame(data, columns=header)

# Correcting the class type
# Corrigiendo el tipo de la clase
df[header[-1]] = df[header[-1]].astype('int32')

# Creating the neural network
# Creando la red neuronal
dt = DecisionTreeClassifier()

# Setting the data for trainning
# Preparando los datos para el entrenamiento
X = df.drop('class', axis=1)
y = df[header[-1]]

# Training the neural network
# Entrenando la Red neuronal
dt = dt.fit(X, y)

# Saving the model
# Guardando el modelo
with open("dt_model.pkl", "wb") as f:
    pickle.dump(dt, f)
    
# To load
# Para cargar
# with open("nn_model.pkl", "rb") as f:
#     nn = pickle.load(f)