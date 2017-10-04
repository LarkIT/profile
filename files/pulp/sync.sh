#!/bin/bash -e

for repo in $(pulp-admin repo list | awk '/Id:/ {print $NF}')
do
  echo $repo
  pulp-admin rpm repo sync run --repo-id $repo
  pulp-admin rpm repo publish run --repo-id $repo
done
