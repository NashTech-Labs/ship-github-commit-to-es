#!/bin/bash

# get github commits
getCommitResponse=$(
   curl -s \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/OWNER/REPO/commits?sha=$GITHUB_REF_NAME&per_page=100&page=1"
)

# get commit SHA
commitSHA=$(echo "$getCommitResponse" |
   jq '.[].sha' |
   tr -d '"')

# get the loop count based on number of commits
loopCount=$(echo "$commitSHA" |
   wc -w)
echo "loopcount= $loopCount"

# get data from ES
getEsCommitSHA=$(curl -H "Content-Type: application/json" -X GET "$ES_URL/github/_search?pretty" -d '{
                  "size": 10000,                                                                  
                  "query": {
                     "wildcard": {
                           "commit_sha": {
                              "value": "*"
                           }}}}' |
                  jq '.hits.hits[]._source.commit_sha' |
                  tr -d '"')

# store ES commit sha in a temp file
echo $getEsCommitSHA | tr " " "\n" > sha_es.txt

# looping through each commit detail
for ((count = 0; count < $loopCount; count++)); do
   
   # get commitSHA
   commitSHA=$(echo "$getCommitResponse" |
      jq --argjson count "$count" '.[$count].sha' |
      tr -d '"')

   # match result for previous existing commit on ES
   matchRes=$(grep -o $commitSHA sha_es.txt)
   echo $matchRes | tr " " "\n" >> match.txt

   # filtering and pushing unmatched commit sha details to ES
   if [ -z $matchRes ]; then
      echo "Unmatched SHA: $commitSHA"
      echo $commitSHA | tr " " "\n" >> unmatch.txt
      
      # get author name
      authorName=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.author.name' |
         tr -d '"')

      # get commit message
      commitMessage=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.message' |
         tr -d '"')

      # get commit html url
      commitHtmlUrl=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].html_url' |
         tr -d '"')

      # get commit time
      commitTime=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.author.date' |
         tr -d '"')

      # send data to es with index github
      curl -X POST "$ES_URL/<index>/<type>" \
         -H "Content-Type: application/json" \
         -d "{ \"commit_sha\" : \"$commitSHA\",
            \"branch_name\" : \"$GITHUB_REF_NAME\",
            \"author_name\" : \"$authorName\",
            \"commit_message\" : \"$commitMessage\",
            \"commit_html_url\" : \"$commitHtmlUrl\",
            \"commit_time\" : \"$commitTime\" }"
   fi
done

# removing temporary file
rm -rf sha_es.txt
rm -rf match.txt
rm -rf unmatch.txt