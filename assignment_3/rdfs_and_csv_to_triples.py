# Group 38
# Haoqi Yu, Bjørn Magnus Hoddevik
from rdfpandas.graph import to_dataframe
import pandas as pd
from rdflib import Graph, URIRef, RDF, Literal, BNode
from rdflib.namespace import Namespace

g = Graph()
g.parse(r"assignment_3\assignment_2_rdfs_revised.txt", format="ttl")
df = to_dataframe(g)

class_mask = df[r"rdf:type{URIRef}"] == "owl:Class"
classes_df = df.loc[class_mask].copy()
df = df.loc[~class_mask]

# print(classes_df)
# quit()

object_mask = df[r"rdf:type{URIRef}"] == "owl:ObjectProperty"
objects_df = df.loc[object_mask].copy()
df = df.loc[~object_mask]
# print(objects_df.to_string())
# quit()


data_properties_mask = df[r"rdf:type{URIRef}"] == "owl:DatatypeProperty"
data_properties_df = df.loc[data_properties_mask].copy()
df = df.loc[~data_properties_mask]

restrictions_mask = df[r"rdf:type{URIRef}"] == "owl:Restriction"
restrictions_df = df.loc[restrictions_mask].copy()
df = df.loc[~restrictions_mask]


def subset_column_match(df: pd.DataFrame, col1: str, col2: str, val: str):
    return df.loc[(df[col1] == val) | (df[col2] == val)]


def get_subset_df(entity_name: str):
    return pd.concat(
        (
            subset_column_match(
                data_properties_df.copy(),
                r"rdfs:domain{URIRef}[0]",
                r"rdfs:domain{URIRef}[1]",
                f":{entity_name}",
            ),
            subset_column_match(
                objects_df,
                r"rdfs:domain{URIRef}[0]",
                r"rdfs:domain{URIRef}[1]",
                f":{entity_name}",
            ),
        )
    )


# print(student_df.columns)
# print(student_df)
# quit()


g_students = Graph()
default = Namespace("http://example.org/")


def convert_to_correct_type(value: str, value_type: str):
    if "boolean" in value_type:
        return bool(value.capitalize())
    elif "string" in value_type:
        return value
    else:
        try:
            return eval(value)
        except TypeError:
            # This only happens when value is nan
            # E.g. Not all registrations have a grade
            # return None
            return value


full_graph = Graph()


def df_to_rdf(
    csv_data: pd.DataFrame,
    rdf_schema: pd.DataFrame,
    key_column: str,
    entity_name: str,
    is_bnode: bool,
):
    for _, row in csv_data.iterrows():
        id = URIRef(row[key_column], default)
        if is_bnode:
            bnode = BNode()
            full_graph.add((id, URIRef(entity_name, default), bnode))
            id = bnode
        else:
            full_graph.add((id, RDF.type, URIRef(entity_name, default)))
        for index, rdf_row in rdf_schema.iterrows():
            if rdf_row[r"rdf:type{URIRef}"] in (
                "owl:DatatypeProperty",
                "owl:ObjectProperty",
            ):
                # if rdf_row[r"rdf:type{URIRef}"] == "owl:DatatypeProperty":
                index = index.replace(":", "")
                if index == key_column or (
                    is_bnode and rdf_row[r"rdf:type{URIRef}"] == "owl:ObjectProperty"
                ):
                    continue
                if index in csv_data.columns:
                    full_graph.add(
                        (
                            id,
                            URIRef(index, default),
                            Literal(
                                convert_to_correct_type(
                                    row[index], rdf_row[r"rdfs:range{URIRef}"]
                                )
                                if rdf_row[r"rdf:type{URIRef}"]
                                == "owl:DatatypeProperty"
                                else row[index]
                            ),
                            # Literal(convert_to_correct_type(row[index], rdf_row[r"rdfs:range{URIRef}"]))
                        )
                    )

        # full_graph.serialize(f"{entity_name}.ttl")
        # for s, p, o in g.triples((None, None, None)):
        #     print(f"{s} - {p}, {o}")


def add_csv_to_graph(
    filepath: str,
    column_rename: dict[str, str],
    key: str,
    name: str,
    entity_name: str = None,
    is_bnode: bool = False,
):
    if entity_name is None:
        entity_name = name
    data_df = pd.read_csv(filepath, dtype=str)
    data_df = data_df.rename(columns=column_rename)
    if key not in data_df.columns:
        if key == "programmeInstanceID":
            data_df["programmeInstanceID"] = (
                data_df["programmeInstanceProgrammeCode"]
                + "-"
                + data_df["programmeInstanceStudyYear"]
            )

    rdf_df = get_subset_df(name)
    df_to_rdf(data_df, rdf_df, key, entity_name, is_bnode)


student_rename = {
    "Student name": "studentName",
    "Student id": "studentID",
    "Programme": "BelongsToProgram",
    "Year": "studentYear",
    "Graduated": "studentGraduated",
}
add_csv_to_graph("data/Students.csv", student_rename, "studentID", "Student")
program_rename = {
    "Programme name": "programmeName",
    "Programme code": "programmeCode",
    "Department name": "OwnedByDepartment",
    "Director": "programmeDirector",
}
add_csv_to_graph("data/Programmes.csv", program_rename, "programmeCode", "Programme")

assigned_hours_rename = {
    "Course code": "teachesCourseCode",
    "Study Period": "teachesCourseOfferingStudyPeriod",
    "Academic Year": "teachesCourseOfferingAcademicYear",
    "Teacher Id": "teachesTeacherID",
    "Hours": "teachesAssignedHours",
    "Course Instance": "teachesCourseOfferingInstanceID",
}
add_csv_to_graph(
    "data/Assigned_Hours.csv",
    assigned_hours_rename,
    "teachesTeacherID",
    "Teaches",
    is_bnode=True,
)

course_instance_rename = {
    "Course code": "courseOfferingCourseCode",
    "Study period": "courseOfferingStudyPeriod",
    "Academic year": "courseOfferingAcademicYear",
    "Instance_id": "courseOfferingInstanceID",
    "Examiner": "Examiner",
}
add_csv_to_graph(
    "data/Course_Instances.csv",
    course_instance_rename,
    "courseOfferingInstanceID",
    "CourseOffering",
)

course_plannings_rename = {
    "Course": "courseOfferingInstanceID",
    "Planned number of Students": "courseOfferingPlanningNumStudents",
    "Senior Hours": "courseOfferingSeniorHours",
    "Assistant Hours": "courseOfferingAssistantHours",
}
add_csv_to_graph(
    "data/Course_plannings.csv",
    course_plannings_rename,
    "courseOfferingInstanceID",
    "CourseOffering",
)

courses_rename = {
    "Course name": "courseName",
    "Course code": "courseCode",
    "Credits": "courseCredits",
    "Level": "courseLevel",
    # "Department": "divisionDepartmentID", #left over
    # "Division": "GivenBy",
    "Owned By": "OwnedByProgramme",
}
add_csv_to_graph("data/Courses.csv", courses_rename, "courseCode", "Course")
courses_given_by_rename = {
    "Course code": "courseCode",
    "Department": "divisionDepartmentID",
    "Division": "divisionID",
}
add_csv_to_graph(
    "data/Courses.csv",
    courses_given_by_rename,
    "courseCode",
    "Division",
    "GivenBy",
    is_bnode=True,
)

programme_courses_rename = {
    "Programme code": "programmeInstanceProgrammeCode",
    "Study Year": "programmeInstanceStudyYear",
    "Academic Year": "programmeInstanceAcademicYear",
    # "Course": "programmeInstanceCourseCode",
    # "Course Type": "programmeInstanceCourseType",
}
add_csv_to_graph(
    "data/Programme_Courses.csv",
    programme_courses_rename,
    "programmeInstanceProgrammeCode",
    "ProgrammeInstance",
)
programme_courses_rename = {
    "Programme code": "programmeInstanceProgrammeCode",
    # "Study Year": "programmeInstanceStudyYear",
    # "Academic Year": "programmeInstanceAcademicYear",
    "Course": "programmeCoursesCourseCode",
    "Course Type": "programmeCoursesCourseType",
}
add_csv_to_graph(
    "data/Programme_Courses.csv",
    programme_courses_rename,
    "programmeInstanceProgrammeCode",
    "ProgrammeCourses",
    is_bnode=True,
)

registrations_rename = {
    "Course Instance": "registrationsCourseOfferingInstanceID",
    "Student id": "registrationsStudentID",
    "Status": "registrationsStatus",
    "Grade": "registrationsGrade",
}
add_csv_to_graph(
    "data/Registrations.csv",
    registrations_rename,
    "registrationsStudentID",
    "Registrations",
    is_bnode=True,
)

reported_hours_rename = {
    "Course code": "teachesCourseCode",
    "Teacher Id": "teachesTeacherID",
    "Hours": "teachesReportedHours",
}
add_csv_to_graph(
    "data/Reported_Hours.csv",
    reported_hours_rename,
    "teachesTeacherID",
    "Teaches",
    is_bnode=True,
)

senior_teachers_rename = {
    "Teacher name": "teacherName",
    "Teacher id": "teacherID",
    "Department name": "teacherDepartmentName",
    "Division name": "teacherDivisionName",
}
add_csv_to_graph(
    "data/Senior_Teachers.csv",
    senior_teachers_rename,
    "teacherID",
    "Teacher",
    "SeniorTeacher",
)

teaching_assistants_rename = senior_teachers_rename
add_csv_to_graph(
    "data/Teaching_Assistants.csv",
    teaching_assistants_rename,
    "teacherID",
    "Teacher",
    "TeachingAssistant",
)


full_graph.serialize("assignment_3/graph.txt", format="turtle")
