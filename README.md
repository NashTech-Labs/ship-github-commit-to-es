This repository contains a shell script to ship GitHub commit details to Elastic Search.


-------------

**Files:** 

```
      1. getGitHubCommit.sh
```

## How to run the above scripts

1.  Modify the following variables in the script.
   - OWNER to GitHub owner name on line 7.
   - REPO to GitHub repsitory name on line 7.
   - GITHUB_REF_NAME to GitHub repsitory branch name on line 7.
   - ES_URL to Elastic Search URL on line 22 and 73.
   - index to Elastic Search Index name on line 73.
   - type to Elastci Search Index type name on line 73.

2. Now, to run the script:
    ```
    ./getGitHubCommit.sh
    ```