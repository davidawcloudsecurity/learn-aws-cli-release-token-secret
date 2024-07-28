# learn-aws-cli-release-token-secret

```bash
project_name=$(aws codebuild list-projects); \
aws codebuild batch-get-projects --names $project_name
```
```bash
aws codebuild update-project \
  --name $project_name \
  --environment-variables-override name=CLIENT_SECRET_KEY,value=new-client-secret-key
```
