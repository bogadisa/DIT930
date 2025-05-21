// Group 38
// Haoqi Yu, Bjørn Magnus Hoddevik

// 1. Find the name, director and department of all programmes.
MATCH (programme:Programme)-[r:OWNED_BY]->(department:Department)
RETURN programme.programmeName, programme.director, department.departmentName;

// 2. Find the names of all students who worked as teaching assistants in courses given by the D3-2 division in study period 2 in academic year 2023/2024.
MATCH (teachingAssistant:TeachingAssistant)-[is_a:IS_A]->(student:Student)
MATCH (teachingAssistant)-[teaches:TEACHES]->(courseOffering:CourseOffering {studyPeriod: 2.0, academicYear: "2023-2024"})
MATCH (courseOffering)-[instance_of:INSTANCE_OF]->(course:Course)
MATCH (course)-[given_by:GIVEN_BY]->(division:Division {divisionName: "D3-2"})
RETURN student.studentName;

// 3. Find all teachers who are assigned more than 120 hours in course 1015 in study period 1 in academic year 2018/2019.
MATCH (teacher)-[r:TEACHES]->(courseOffering:CourseOffering {studyPeriod: "1.0", academicYear: "2018-2019"})-[:INSTANCE_OF]->(:Course {courseCode: "1015"})
WHERE toInteger(r.assignedHours) > 120
RETURN teacher.teacherName LIMIT 25;

// 4. Find all students registered for course instance I-910 that were not registered for course instance I-911.
MATCH (student:Student)-[:REGISTERED]->(courseOffering:CourseOffering {instanceId: "I-910"})
MATCH (student2:Student)-[:REGISTERED]->(courseOffering2:CourseOffering {instanceId: "I-911"})
WHERE student <> student2
RETURN student;

// 5. Find all programmes along with the total number of owned courses. List the results in descending order of number of owned courses.
MATCH (programme:Programme)<-[OWNED_BY]-(course:Course)
RETURN programme.programmeName, COUNT(course) AS totalOwnedCourses ORDER BY totalOwnedCourses DESC;

// 6. Find the number of:
//     a. senior teachers
//     b. all people

// a)
MATCH (seniorTeacher:SeniorTeacher)
RETURN COUNT(seniorTeacher) AS totalSeniorTeachers;
// b)
CALL () {
    MATCH (seniorTeacher:SeniorTeacher)
    RETURN seniorTeacher.teacherId AS id
UNION
    // technically not needed
    MATCH (teachingAssistant:TeachingAssistant)
    RETURN teachingAssistant.teacherId AS id
UNION
    MATCH (student:Student)
    RETURN student.studentId as id
}
RETURN COUNT(id);
