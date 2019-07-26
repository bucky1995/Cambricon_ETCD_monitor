#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon

ReservedNum=5                  
rm_file_dir='/code/backup-file' 

cd $rm_file_dir    
RootDir=$(cd $(dirname $0); pwd)      
FileNum=$(ls -l *| grep ^- | wc -l)  

OldFile=$(ls -rt *|head -1)         
if [ $RootDir == $rm_file_dir ];then   
    while (($FileNum>$ReservedNum))  
    do
        rm -f $RootDir'/'$OldFile
        let "FileNum--"                                     
        OldFile=$(ls -rt *|head -1)         
    done
else
    exit 1                        
fi
