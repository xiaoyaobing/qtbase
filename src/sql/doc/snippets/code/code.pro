TEMPLATE = lib
TARGET = code_snippets
QT = core

#! [qmake_use]
QT += sql
#! [qmake_use]

SOURCES = \
    doc_src_sql-driver.cpp \
    src_sql_kernel_qsqldatabase.cpp \
    src_sql_kernel_qsqlerror.cpp \
    src_sql_kernel_qsqlresult.cpp \
    src_sql_kernel_qsqldriver.cpp \
    src_sql_models_qsqlquerymodel.cpp
