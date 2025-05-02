import rdflib.namespace
from rdfpandas.graph import to_graph, to_dataframe
import rdfpandas as rdfpd
import pandas as pd
import rdflib

g = rdflib.Graph()
g.parse(r"assignment_2\assignment_2.txt", format="ttl")
df = to_dataframe(g)
print(df.loc[":studentName"])
