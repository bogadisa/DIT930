// Group 38
// Haoqi Yu, Bjørn Magnus Hoddevik

// Create students
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Students.csv' AS rowStudents
MERGE (student:Student {studentId: rowStudents.`Student id`})
  ON CREATE SET student.studentId = rowStudents.`Student id`, student.studentName = rowStudents.`Student name`, student.graduated = toBoolean(rowStudents.Graduated), student.year = toInteger(rowStudents.Year);

// Create programmes
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Programmes.csv' AS rowProgrammes
MERGE (programme:Programme {programmeCode: rowProgrammes.`Programme code`})
  ON CREATE SET programme.programmeCode = toInteger(rowProgrammes.`Programme code`), programme.programmeName = rowProgrammes.`Programme Name`, programme.director = rowProgrammes.Director;

// Create relationships between students and programmes
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Students.csv' AS rowStudents
MATCH (student:Student {studentId: rowStudents.`Student id`})
MATCH (programme:Programme {programmeCode:rowStudents.Programme})
MERGE (student)-[op:BELONGS_TO]->(programme);

// Create departments
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Programmes.csv' AS rowProgrammes
MERGE (department:Department {departmentName: rowProgrammes.`Department name`})
  ON CREATE SET department.departmentName = rowProgrammes.`Department name`;

// Create relationships between programmes and departments
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Programmes.csv' AS rowProgrammes
MATCH (programme:Programme {programmeCode: toInteger(rowProgrammes.`Programme code`)})
MATCH (department:Department {departmentName:rowProgrammes.`Department name`})
MERGE (programme)-[op:OWNED_BY]->(department);

// Create courses
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Courses.csv' AS rowCourses
MERGE (course:Course {courseCode: rowCourses.`Course code`})
  ON CREATE SET course.courseCode = toInteger(rowCourses.`Course code`), course.courseName = rowCourses.`Course name`, course.level = rowCourses.Level, course.credits = toInteger(rowCourses.Credits);

// Create relationships between courses and programmes
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Courses.csv' AS rowCourses
MATCH (course:Course {courseCode: toInteger(rowCourses.`Course code`)})
MATCH (programme:Programme {programmeName: rowCourses.`Owned By`})
MERGE (course)-[op:OWNED_BY]->(programme);

// Create divisions and create relationships between division and department, and division and courses
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Courses.csv' AS rowDivisions
MATCH (department:Department {departmentName: rowDivisions.Department})
MERGE (division:Division {divisionName: rowDivisions.Division})
  ON CREATE SET division.divisionName = rowDivisions.Division
MERGE (division)-[op:DIVISION_OF]->(department);

// Create relationships between division and courses
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Courses.csv' AS rowDivisions
MATCH (division:Division {divisionName: rowDivisions.Division})
MATCH (course:Course {courseCode: toInteger(rowDivisions.`Course code`)})
MERGE (course)-[op:GIVEN_BY]->(division);

// Create senior teacher and relationship to division
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Senior_Teachers.csv' AS rowSeniorTeachers
MATCH (division:Division {divisionName: rowSeniorTeachers.`Division name`})-[r:DIVISION_OF]-(department:Department {departmentName: rowSeniorTeachers.`Department name`})
MERGE (seniorTeacher:SeniorTeacher {teacherId: rowSeniorTeachers.`Teacher id`})
  ON CREATE SET seniorTeacher.teacherId = rowSeniorTeachers.`Teacher id`, seniorTeacher.teacherName = rowSeniorTeachers.`Teacher name`
MERGE (seniorTeacher)-[op:BELONGS_TO]->(division);

// Create teaching assistant and relationship to student
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Teaching_Assistants.csv' AS rowTeachingAssistants
MATCH (student:Student {studentId: rowTeachingAssistants.`Teacher id`})
MERGE (teachingAssistant:TeachingAssistant {teacherId: rowTeachingAssistants.`Teacher id`})
    ON CREATE SET teachingAssistant.teacherId = rowTeachingAssistants.`Teacher id`, teachingAssistant.teacherName = rowTeachingAssistants.`Teacher name`
MERGE (teachingAssistant)-[op:IS_A]->(student);

// Create relationships between teaching assistant and division
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Teaching_Assistants.csv' AS rowTeachingAssistants
MATCH (division:Division {divisionName: rowTeachingAssistants.`Division name`})-[r:DIVISION_OF]-(department:Department {departmentName: rowTeachingAssistants.`Department name`})
MATCH (teachingAssistant:TeachingAssistant {teacherId: rowTeachingAssistants.`Teacher id`})
MERGE (teachingAssistant)-[op:BELONGS_TO]->(division);

// Create course offering and relationship to course
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Course_Instances.csv' AS rowCourseInstances
MATCH (course:Course {courseCode: toInteger(rowCourseInstances.`Course code`)})
MERGE (courseOffering:CourseOffering {instanceId: rowCourseInstances.Instance_id})
    ON CREATE SET courseOffering.instanceId = rowCourseInstances.Instance_id, courseOffering.academicYear = rowCourseInstances.`Academic year`, courseOffering.studyPeriod = toFloat(rowCourseInstances.`Study period`)
MERGE (courseOffering)-[op:INSTANCE_OF]->(course);

// Extend course offering
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Course_plannings.csv' AS rowCoursePlannings
MATCH (courseOffering:CourseOffering {instanceId: rowCoursePlannings.Course})
    SET courseOffering.planningNumStudents = toInteger(rowCoursePlannings.`Planned number of Students`), courseOffering.seniorHours = toInteger(rowCoursePlannings.`Senior Hours`),
        courseOffering.assistantHours = toInteger(rowCoursePlannings.`Assistant Hours`);

// Create examiner relationship between course offering and senior teacher
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Course_Instances.csv' AS rowCourseInstances
MATCH (courseOffering:CourseOffering {instanceId: rowCourseInstances.Instance_id})
MATCH (seniorTeacher:SeniorTeacher {teacherId: rowCourseInstances.Examiner})
MERGE (seniorTeacher)-[op:EXAMINER_OF]->(courseOffering);

// Create programme instance and relationship to programme
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Programme_Courses.csv' AS rowProgrammeCourses
MATCH (programme:Programme {programmeCode: toInteger(rowProgrammeCourses.`Programme code`)})
MERGE (programmeInstance:ProgrammeInstance {programmeCode: toInteger(rowProgrammeCourses.`Programme code`), studyYear: rowProgrammeCourses.`Study Year`, academicYear: rowProgrammeCourses.`Academic Year`})
    ON CREATE SET programmeInstance.programmeCode = toInteger(rowProgrammeCourses.`Programme code`), programmeInstance.studyYear = toFloat(rowProgrammeCourses.`Study Year`), programmeInstance.academicYear = rowProgrammeCourses.`Academic Year`
MERGE (programmeInstance)-[op:INSTANCE_OF]->(programme);

// Create relationship between programme instance and course
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Programme_Courses.csv' AS rowProgrammeCourses
MATCH (course:Course {courseCode: toInteger(rowProgrammeCourses.Course)})
MATCH (programmeInstance:ProgrammeInstance {programmeCode: toInteger(rowProgrammeCourses.`Programme code`), studyYear: toFloat(rowProgrammeCourses.`Study Year`), academicYear: rowProgrammeCourses.`Academic Year`})
MERGE (programmeInstance)-[op:INCLUDES {courseType:rowProgrammeCourses.`Course Type`}]->(course);

// Create relationship teaches between senior teacher and course offering
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Assigned_Hours.csv' AS rowAssignedHours
MATCH (courseOffering:CourseOffering {instanceId: rowAssignedHours.`Course Instance`})
MATCH (seniorTeacher:SeniorTeacher {teacherId: rowAssignedHours.`Teacher Id`})
MERGE (seniorTeacher)-[op:TEACHES {assignedHours: toFloat(rowAssignedHours.Hours)}]->(courseOffering);

// Create relationship teaches between assistant teacher and course offering
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Assigned_Hours.csv' AS rowAssignedHours
MATCH (courseOffering:CourseOffering {instanceId: rowAssignedHours.`Course Instance`})
MATCH (teachingAssistant:TeachingAssistant {teacherId: rowAssignedHours.`Teacher Id`})
MERGE (teachingAssistant)-[op:TEACHES {assignedHours: toFloat(rowAssignedHours.Hours)}]->(courseOffering);

// Create relationship teaches between senior teacher and course offering
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Reported_Hours.csv' AS rowReportedHours
MATCH (courseOffering:CourseOffering {instanceId: toInteger(rowReportedHours.`Course code`)})
MATCH (seniorTeacher:SeniorTeacher {teacherId: rowReportedHours.`Teacher Id`})
MERGE (seniorTeacher)-[op:TEACHES {assignedHours:  toFloat(rowReportedHours.Hours)}]->(courseOffering);

// Create relationship teaches between assistant teacher and course offering
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Reported_Hours.csv' AS rowReportedHours
MATCH (courseOffering:CourseOffering {instanceId: toInteger(rowReportedHours.`Course code`)})
MATCH (teachingAssistant:TeachingAssistant {teacherId: rowReportedHours.`Teacher Id`})
MERGE (teachingAssistant)-[op:TEACHES {assignedHours:  toFloat(rowReportedHours.Hours)}]->(courseOffering);

// Create registered relationship between student and course offering (without grade)
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Registrations.csv' AS rowRegistrations
MATCH (courseOffering:CourseOffering {instanceId: toInteger(rowRegistrations.`Course Instance`)})
MATCH (student:Student {studentId: rowRegistrations.`Student id`})
MERGE (student)-[op:REGISTERED {status: rowRegistrations.Status}]->(courseOffering);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/bogadisa/DIT930/refs/heads/main/data/Registrations.csv' AS rowRegistrations
MATCH (courseOffering:CourseOffering {instanceId: toInteger(rowRegistrations.`Course Instance`)})
MATCH (student:Student {studentId: rowRegistrations.`Student id`})
MATCH (student)-[op:REGISTERED]->(courseOffering)
WHERE rowRegistrations.Grade IS NOT NULL
SET op.grade = rowRegistrations.Grade