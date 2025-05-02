from rdfpandas.graph import to_graph, to_dataframe
import rdfpandas as rdfpd
import pandas as pd
from rdflib import Graph, URIRef, RDF, Literal
from rdflib.namespace import Namespace, XSD, OWL
import urllib.parse

g = Graph()
g.parse(r"assignment_2\assignment_2.txt", format="ttl")
df = to_dataframe(g)

class_mask = df[r"rdf:type{URIRef}"] == "owl:Class"
classes_df = df.loc[class_mask].copy()
df = df.loc[~class_mask]

# print(classes_df)
# quit()

object_mask = df[r"rdf:type{URIRef}"] == "owl:ObjectProperty"
objects_df = df.loc[object_mask].copy()
df = df.loc[~object_mask]


data_properties_mask = df[r"rdf:type{URIRef}"] == "owl:DatatypeProperty"
data_properties_df = df.loc[data_properties_mask].copy()
df = df.loc[~data_properties_mask]

restrictions_mask = df[r"rdf:type{URIRef}"] == "owl:Restriction"
restrictions_df = df.loc[restrictions_mask].copy()
df = df.loc[~restrictions_mask]


def subset_column_match(df: pd.DataFrame, col1: str, col2: str, val: str):
    return df.loc[(df[col1] == val) | (df[col2] == val)]


student_df = pd.concat(
    (
        subset_column_match(
            data_properties_df.copy(),
            r"rdfs:domain{URIRef}[0]",
            r"rdfs:domain{URIRef}[1]",
            ":Student",
        ),
        subset_column_match(
            objects_df, r"rdfs:domain{URIRef}[0]", r"rdfs:domain{URIRef}[1]", ":Student"
        ),
    )
)
# print(student_df)

student_data_df = pd.read_csv("data/Students.csv", dtype=str)
column_rename = {
    "Student name": ":studentName",
    "Student id": ":studentID",
    "Programme": ":BelongsToProgramme",
    "Year": ":studentYear",
    "Graduated": ":graduated",
}
student_data_df = student_data_df.rename(columns=column_rename)
student_data_df[":graduated"] = student_data_df[":graduated"].str.lower()
# print(student_data_df[":graduated"])

g_students = Graph()
ppl = Namespace("http://example.org/people/")
loc = Namespace("http://mylocations.org/addresses/")
schema = Namespace("http://schema.org/")
# g_students.bind("owl", OWL)

for _, row in student_data_df.iterrows():
    # for key, val in row.to_dict().items():
    # g_students.add(URIRef(ppl + row[":" + key]), )
    g_students.add(
        (
            URIRef(urllib.parse.quote(ppl + row[":studentName"])),
            RDF.type,
            Literal(":Student", datatype="owl:Class"),
        )
    )
    for index, rdf_row in student_df.iterrows():
        if rdf_row[r"rdf:type{URIRef}"] == "owl:DatatypeProperty":
            if index in student_data_df.columns:
                g_students.add(
                    (
                        URIRef(urllib.parse.quote(ppl + row[":studentName"])),
                        XSD[rdf_row[r"rdfs:range{URIRef}"]],
                        Literal(
                            row[index],
                            datatype=rdf_row[r"rdfs:range{URIRef}"],
                        ),
                    )
                )

g_students.serialize("out.txt")
# for s, p, o in g_students.triples((None, None, None)):
#     print(f"{s} - {p}, {o}")
