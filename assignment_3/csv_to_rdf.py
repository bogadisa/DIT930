import rdflib.namespace
from rdfpandas.graph import to_graph
import rdfpandas as rdfpd
import pandas as pd
import rdflib

df = pd.read_csv("data/students.csv", index_col="Student id")

namespace_manager = rdflib.namespace.NamespaceManager(rdfpd.graph.Graph())
namespace_manager.bind("skos",rdflib.SKOS)
namespace_manager.bind("rdfpandas", rdflib.namespace.Namespace("http://github.com/cadmiumkitty/rdfpandas/"))
g = to_graph(df, namespace_manager)
s = g.serialize(format="turtle")
print(s)