#dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_RDM `pwd`/DSB_RDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
#dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_FDM `pwd`/DSB_FDM_%date:~0,4%-%date:~5,2%-%date:~8,2%
#dsexport /H=ETL /U=isadmin /P=123 ETL/DSB `pwd`/DSB_%date:~0,4%-%date:~5,2%-%date:~8,2%
#dsexport /H=ETL /U=isadmin /P=123 ETL/amlrs `pwd`/amlrs_%date:~0,4%-%date:~5,2%-%date:~8,2%
#dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_MDM `pwd`/DSB_MDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
#dsexport /H=ETL /U=isadmin /P=123 ETL/TARGET `pwd`/Target_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx

# windows export
dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_RDM %cd%\DSB_RDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_FDM %cd%\DSB_FDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
dsexport /H=ETL /U=isadmin /P=123 ETL/DSB %cd%\DSB_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
dsexport /H=ETL /U=isadmin /P=123 ETL/amlrs %cd%\amlrs_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
dsexport /H=ETL /U=isadmin /P=123 ETL/DSB_MDM %cd%\DSB_MDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
dsexport /H=ETL /U=isadmin /P=123 ETL/TARGET %cd%\Target_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx


#`pwd`\DSB_MDM_%date:~0,4%-%date:~5,2%-%date:~8,2%.dsx
#`pwd`\DSB_FDM_%date:~0,4%-%date:~5,2%-%date:~8,2%
#`pwd`\DSB_%date:~0,4%-%date:~5,2%-%date:~8,2%
#`pwd`\amlrs_%date:~0,4%-%date:~5,2%-%date:~8,2%
#ETL/TARGET


#echo > "%date:~0,4%-%date:~5,2%-%date:~8,2% %time:~0,2%-%time:~3,2%-%time:~6,2%.txt"
#echo > "%date:~0,4%-%date:~5,2%-%date:~8,2%.txt"