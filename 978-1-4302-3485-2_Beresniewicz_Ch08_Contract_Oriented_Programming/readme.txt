Purpose: Code samples for Chapter 2 “Dynamic SQL and PL/SQL”
Author: Michael Rosenblum
Supported version: 10gR2 except example 5, 11g (R1 and R2)


1.Native Dynamic SQL – Example #1:  dynamic value list builder
    a.01_NativeDynamicSQL_Example1.sql – create object types, create function, run function
    b.01_NativeDynamicSQL_Example1_log.txt – SQL*Plus log

2.Native Dynamic SQL – Example #2: how to drop function-based index without invalidation of dependencies
    a.02_NativeDynamicSQL_Example2.sql – required grant, create procedure
    b.02_NativeDynamicSQL_Example2_demo.txt – log with remarks that illustrates the described effect

3.Dynamic Cursors – Example #1: building REF Cursors on the fly
    a.03_DynamicCursors_Example1.sql – create procedure, run the procedure
    b.03_DynamicCursors_Example1_log.txt – SQL*Plus log

4.Dynamic Cursors – Example #2: conditional value list builder
    a.04_DynamicCursors_Example2.sql – create function, run function
    b.04_DynamicCursors_Example2_log.txt – SQL*Plus log

5.DBMS_SQL Example (11g Only):
    a.05_DBMS_SQL_Example1_11gOnly.sql – create procedure, run procedure
    b.05_DBMS_SQL_Example1_11gOnly_log.txt – SQL*Plus log

6.Sample of Dynamic Thinking: generic cloning procedure
    a.06_SampleOfDynamicThinking.sql – create supporting type and sequence, create main package
    b.06_SampleOfDynamicThinking_demo.txt – log with remarks that shows how to clone one of the departments (with employees) in SCOTT/TIGER schema

7.Security Issues: basic illustration of code injections when bind variables are not used
    a.07_SecurityIssues_BindVariables_demoOnly.txt - illustration of code injection

8.Security Issues: repository-based solution
    a.08_SecurityIssues_Repository.sql – create repository table, create wrapper function, create sample function, register function
    b.08_SecurityIssues_Repository_demo.txt – log that illustrates how to run the function from the repository

9.AntiPatterns: case when Dynamic SQL may not be the best option
    a.09_AntiPatterns.sql – create and run function with/without Dynamic SQL
    b.09_AntiPatterns_log.txt – SQL*Plus log

10. ImplementationComparison: reusing of parsed DBMS_SQL cursors
    a. 10_ImplementationComparison.sql - create and populate repository, create main package
    b. 10_ImplementationComparison_demo.log - SQL*Plus log with comments: loading and processing incoming feed