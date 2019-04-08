#This file is managed by Puppet. Any manual changes will be overwritten.
#!/bin/bash

output=$(sudo ps aux | awk -v p='COMMAND' 'NR==1 {n=index($0, p); next} {print substr($0, n)}' | cut -d' ' -f1-2 )

echo -e "{\n\t\"data\":["
while IFS= read SERVICE ; do
          [ ${PRINTED} ] && echo ","
            PRINTED=true
              echo -en "\t\t{ \"{#SERVICE}\":\"${SERVICE}\" }"
      done <<< "$output"
echo -e "\n\t]\n}"
